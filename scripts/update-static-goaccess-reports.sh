#!/bin/bash

# -----------------------------------------------------------------------------
# Static GoAccess Reports from Daily SFTP Web Access Logs
# -----------------------------------------------------------------------------
# EN:
# This script downloads compressed web access logs via SFTP, stores them locally,
# optionally removes old local log files, and generates separate static GoAccess
# HTML reports using Docker.
#
# DE:
# Dieses Script lädt komprimierte Web-Access-Logs per SFTP herunter, speichert sie
# lokal, entfernt optional alte lokale Logdateien und erzeugt separate statische
# GoAccess-HTML-Reports über Docker.
#
# EN:
# The defaults are optimized for providers that expose daily Apache/Combined logs
# via SFTP. Hetzner Webhosting / konsoleH commonly uses:
#   www_logs/<domain>/access.log.YYYYMMDD.gz
#
# DE:
# Die Defaults sind für Provider optimiert, die tägliche Apache/Combined-Logs per
# SFTP bereitstellen. Hetzner Webhosting / konsoleH verwendet typischerweise:
#   www_logs/<domain>/access.log.YYYYMMDD.gz
# -----------------------------------------------------------------------------

set -uo pipefail

# -----------------------------------------------------------------------------
# User configuration
# Benutzerkonfiguration
# -----------------------------------------------------------------------------

# EN: Domains to process. Each domain gets its own report.
#     For one domain:       DOMAINS=("example.org")
#     For multiple domains: DOMAINS=("example.org" "example.com")
# DE: Zu verarbeitende Domains. Jede Domain bekommt einen eigenen Report.
#     Für eine Domain:      DOMAINS=("example.org")
#     Für mehrere Domains:  DOMAINS=("example.org" "example.com")
DOMAINS=("example.org" "example.com")

# EN:
# Generate a static landing page at /index.html that links to all domain reports.
# The nginx web container serves it at http://<server>:7881/.
#
# DE:
# Eine statische Startseite unter /index.html erzeugen, die auf alle Domain-Reports verlinkt.
# Der nginx-Webcontainer liefert sie unter http://<server>:7881/ aus.
GENERATE_LANDING_PAGE=true

# EN: Landing page text. Adjust these values to match your project or website style.
# DE: Texte der Startseite. Diese Werte können an Projekt oder Website-Stil angepasst werden.
LANDING_PAGE_TITLE="Static GoAccess Reports"
LANDING_PAGE_KICKER="STATIC REPORTS / GOACCESS"
LANDING_PAGE_SUBTITLE="Daily SFTP web access logs turned into static HTML reports."
LANDING_PAGE_DESCRIPTION="No live tracking, no JavaScript tracker, no permanent GoAccess daemon. Logs are fetched periodically, reports are generated, and nginx serves the static output."
LANDING_PAGE_FOOTER="Generated locally from server access logs."

# EN:
# Maximum age of local log files in days.
# Set to 0 to disable automatic local log cleanup and date-based download filtering.
# This only deletes local copies, never remote files on the SFTP server.
#
# DE:
# Maximales Alter lokaler Logdateien in Tagen.
# Auf 0 setzen, um das automatische lokale Aufräumen und die datumsgesteuerte
# Download-Einschränkung zu deaktivieren.
# Es werden nur lokale Kopien gelöscht, niemals Dateien auf dem SFTP-Server.
MAX_LOG_AGE_DAYS=365

# EN: Credentials are loaded from this root-only environment file.
# DE: Zugangsdaten werden aus dieser nur für root lesbaren Env-Datei geladen.
ENV_FILE="/root/.goaccess-sftp.env"

# EN: Remote base directory on the SFTP account. Hetzner default: www_logs
# DE: Basisverzeichnis auf dem SFTP-Account. Hetzner-Default: www_logs
REMOTE_BASE_PATH="www_logs"

# EN: Local base directory for logs, config and generated HTML reports.
# DE: Lokales Basisverzeichnis für Logs, Konfiguration und HTML-Reports.
LOCAL_BASE="/opt/goaccess/static-log-reports"

# EN: Remote/local access log filename pattern. Hetzner default: access.log.*.gz
# DE: Muster für Remote-/lokale Access-Logdateien. Hetzner-Default: access.log.*.gz
ACCESS_LOG_GLOB="access.log.*.gz"

# EN:
# Retention mode:
#   filename = use date from filename; best for access.log.YYYYMMDD.gz
#   mtime    = use local file modification time; more generic but less exact
#   none     = do not filter by age; keep all downloaded logs
#
# DE:
# Aufbewahrungsmodus:
#   filename = Datum aus Dateiname verwenden; ideal für access.log.YYYYMMDD.gz
#   mtime    = lokales Datei-Änderungsdatum verwenden; generischer, aber ungenauer
#   none     = nicht nach Alter filtern; alle heruntergeladenen Logs behalten
RETENTION_MODE="filename"

# EN:
# Date extraction regex for RETENTION_MODE="filename".
# The first capture group must be YYYYMMDD.
# Hetzner-style example: access.log.20250607.gz
#
# DE:
# Regex zur Datumserkennung bei RETENTION_MODE="filename".
# Die erste Capture-Gruppe muss YYYYMMDD sein.
# Hetzner-artiges Beispiel: access.log.20250607.gz
LOG_DATE_REGEX='access\.log\.([0-9]{8})\.gz'

# EN:
# Provider-friendly SFTP throttling.
# - One remote listing session per domain.
# - One download session per domain.
# - Missing files are queued first and downloaded slowly.
# - Set SFTP_MAX_FILES_PER_RUN=0 for unlimited backfill per run.
#
# DE:
# Providerfreundliche SFTP-Drosselung.
# - Eine Remote-Listing-Session pro Domain.
# - Eine Download-Session pro Domain.
# - Fehlende Dateien werden zuerst gesammelt und dann langsam geladen.
# - SFTP_MAX_FILES_PER_RUN=0 bedeutet unbegrenzter Backfill pro Lauf.
SFTP_MAX_FILES_PER_RUN=25
SFTP_FILE_DELAY_SECONDS=2
SFTP_DOMAIN_DELAY_SECONDS=5

# EN: SFTP timeout/retry behavior for non-interactive cron runs.
# DE: SFTP-Timeout-/Retry-Verhalten für nicht-interaktive Cron-Läufe.
SFTP_TIMEOUT_SECONDS=20
SFTP_MAX_RETRIES=1
SFTP_RECONNECT_INTERVAL_BASE=5
SFTP_RECONNECT_INTERVAL_MAX=10

# EN: Pin GoAccess version to avoid unexpected breaking changes from latest.
# DE: GoAccess-Version pinnen, damit latest keine unerwarteten Änderungen bringt.
GOACCESS_IMAGE="allinurl/goaccess:1.10.2"

# -----------------------------------------------------------------------------
# Internal paths
# Interne Pfade
# -----------------------------------------------------------------------------

LOCAL_LOG_PATH="${LOCAL_BASE}/logs"
LOCAL_HTML_PATH="${LOCAL_BASE}/html"
LOCAL_CONFIG_PATH="${LOCAL_BASE}/config"

# -----------------------------------------------------------------------------
# Functions
# Funktionen
# -----------------------------------------------------------------------------

extract_yyyymmdd_from_filename() {
  local filename="$1"
  if [[ "$filename" =~ $LOG_DATE_REGEX ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

is_yyyymmdd_in_window() {
  local yyyymmdd="$1"
  local cutoff_yyyymmdd="$2"

  if [ "$MAX_LOG_AGE_DAYS" -eq 0 ]; then
    return 0
  fi

  [[ "$yyyymmdd" =~ ^[0-9]{8}$ ]] || return 1
  [ "$yyyymmdd" -ge "$cutoff_yyyymmdd" ]
}

html_escape() {
  local value="$1"
  value=${value//&/&amp;}
  value=${value//</&lt;}
  value=${value//>/&gt;}
  value=${value//\"/&quot;}
  value=${value//\'/&#39;}
  echo "$value"
}

write_lftp_common_settings() {
  cat <<EOF
set sftp:auto-confirm yes
set cmd:fail-exit yes
set net:timeout ${SFTP_TIMEOUT_SECONDS}
set net:max-retries ${SFTP_MAX_RETRIES}
set net:reconnect-interval-base ${SFTP_RECONNECT_INTERVAL_BASE}
set net:reconnect-interval-max ${SFTP_RECONNECT_INTERVAL_MAX}
set net:connection-limit 1
set xfer:clobber off
EOF
}

generate_landing_page() {
  if [ "$GENERATE_LANDING_PAGE" != "true" ]; then
    echo "==> Landing page generation disabled"
    echo "==> Startseiten-Erzeugung deaktiviert"
    return 0
  fi

  echo "==> Generating landing page"
  echo "==> Erzeuge Startseite"

  local output_file="${LOCAL_HTML_PATH}/index.html"
  local generated_at
  generated_at=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

  local title kicker subtitle description footer
  title=$(html_escape "$LANDING_PAGE_TITLE")
  kicker=$(html_escape "$LANDING_PAGE_KICKER")
  subtitle=$(html_escape "$LANDING_PAGE_SUBTITLE")
  description=$(html_escape "$LANDING_PAGE_DESCRIPTION")
  footer=$(html_escape "$LANDING_PAGE_FOOTER")

  cat > "$output_file" <<EOF
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title}</title>
  <style>
    :root {
      color-scheme: dark;
      --bg: #07090f;
      --panel: rgba(15, 20, 31, 0.78);
      --panel-strong: rgba(18, 25, 38, 0.96);
      --text: #ecfdf5;
      --muted: #9ca3af;
      --line: rgba(148, 163, 184, 0.18);
      --accent: #9cff3a;
      --accent-2: #22d3ee;
      --warn: #facc15;
      --shadow: rgba(0, 0, 0, 0.45);
    }

    * { box-sizing: border-box; }

    body {
      margin: 0;
      min-height: 100vh;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      color: var(--text);
      background:
        radial-gradient(circle at 20% 10%, rgba(156, 255, 58, 0.14), transparent 28rem),
        radial-gradient(circle at 85% 20%, rgba(34, 211, 238, 0.11), transparent 30rem),
        linear-gradient(180deg, #07090f 0%, #0b1020 55%, #07090f 100%);
    }

    body::before {
      content: "";
      position: fixed;
      inset: 0;
      pointer-events: none;
      background-image:
        linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
        linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
      background-size: 44px 44px;
      mask-image: linear-gradient(to bottom, rgba(0,0,0,0.65), transparent 75%);
    }

    .wrap {
      width: min(1120px, calc(100% - 32px));
      margin: 0 auto;
      padding: 56px 0 40px;
      position: relative;
    }

    header {
      display: grid;
      gap: 18px;
      margin-bottom: 32px;
    }

    .kicker {
      display: inline-flex;
      width: fit-content;
      align-items: center;
      gap: 10px;
      padding: 8px 12px;
      border: 1px solid var(--line);
      border-radius: 999px;
      color: var(--accent);
      background: rgba(156, 255, 58, 0.06);
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
      font-size: 12px;
      letter-spacing: 0.12em;
      text-transform: uppercase;
    }

    .kicker::before {
      content: "";
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--accent);
      box-shadow: 0 0 18px var(--accent);
    }

    h1 {
      max-width: 860px;
      margin: 0;
      font-size: clamp(42px, 8vw, 92px);
      line-height: 0.92;
      letter-spacing: -0.07em;
    }

    .subtitle {
      max-width: 760px;
      margin: 0;
      color: #cbd5e1;
      font-size: clamp(18px, 2vw, 24px);
      line-height: 1.45;
    }

    .description {
      max-width: 760px;
      margin: 0;
      color: var(--muted);
      font-size: 15px;
      line-height: 1.7;
    }

    .meta {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 6px;
    }

    .pill {
      padding: 8px 10px;
      border: 1px solid var(--line);
      border-radius: 999px;
      color: #d1d5db;
      background: rgba(15, 23, 42, 0.6);
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
      font-size: 12px;
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 16px;
      margin-top: 34px;
    }

    .card {
      display: flex;
      flex-direction: column;
      min-height: 174px;
      padding: 20px;
      border: 1px solid var(--line);
      border-radius: 24px;
      background: linear-gradient(180deg, var(--panel-strong), var(--panel));
      box-shadow: 0 18px 40px var(--shadow);
      text-decoration: none;
      color: inherit;
      transition: transform 180ms ease, border-color 180ms ease, background 180ms ease;
    }

    .card:hover {
      transform: translateY(-3px);
      border-color: rgba(156, 255, 58, 0.48);
      background: linear-gradient(180deg, rgba(25, 35, 52, 0.98), rgba(15, 20, 31, 0.82));
    }

    .card.disabled {
      opacity: 0.62;
      pointer-events: none;
    }

    .domain {
      font-size: 22px;
      font-weight: 750;
      letter-spacing: -0.03em;
    }

    .status {
      margin-top: 10px;
      color: var(--accent);
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.1em;
    }

    .disabled .status { color: var(--warn); }

    .updated {
      margin-top: auto;
      padding-top: 24px;
      color: var(--muted);
      font-size: 13px;
      line-height: 1.45;
    }

    footer {
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      gap: 12px;
      margin-top: 36px;
      padding-top: 22px;
      border-top: 1px solid var(--line);
      color: var(--muted);
      font-size: 13px;
    }

    code {
      color: #d9f99d;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
    }
  </style>
</head>
<body>
  <main class="wrap">
    <header>
      <div class="kicker">${kicker}</div>
      <h1>${title}</h1>
      <p class="subtitle">${subtitle}</p>
      <p class="description">${description}</p>
      <div class="meta">
        <span class="pill">GoAccess</span>
        <span class="pill">SFTP Logs</span>
        <span class="pill">Static HTML</span>
        <span class="pill">Generated ${generated_at}</span>
      </div>
    </header>

    <section class="grid" aria-label="Available reports">
EOF

  local domain escaped_domain report_path updated_at card_class href status_text
  for domain in "${DOMAINS[@]}"; do
    escaped_domain=$(html_escape "$domain")
    report_path="${LOCAL_HTML_PATH}/${domain}/index.html"

    if [ -f "$report_path" ]; then
      updated_at=$(date -r "$report_path" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || echo "unknown")
      updated_at=$(html_escape "$updated_at")
      card_class="card"
      href="./${escaped_domain}/"
      status_text="Report ready"
      cat >> "$output_file" <<EOF
      <a class="${card_class}" href="${href}">
        <div class="domain">${escaped_domain}</div>
        <div class="status">${status_text}</div>
        <div class="updated">Last generated:<br><code>${updated_at}</code></div>
      </a>
EOF
    else
      card_class="card disabled"
      status_text="Report missing"
      cat >> "$output_file" <<EOF
      <div class="${card_class}">
        <div class="domain">${escaped_domain}</div>
        <div class="status">${status_text}</div>
        <div class="updated">No <code>index.html</code> found for this domain yet.</div>
      </div>
EOF
    fi
  done

  cat >> "$output_file" <<EOF
    </section>

    <footer>
      <span>${footer}</span>
      <span><code>${#DOMAINS[@]}</code> configured report target(s)</span>
    </footer>
  </main>
</body>
</html>
EOF
}

# -----------------------------------------------------------------------------
# Pre-flight checks
# Vorabprüfungen
# -----------------------------------------------------------------------------

for REQUIRED_COMMAND in lftp docker date find sort mktemp basename wc grep; do
  if ! command -v "$REQUIRED_COMMAND" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: ${REQUIRED_COMMAND}"
    echo "FEHLER: Benötigter Befehl nicht gefunden: ${REQUIRED_COMMAND}"
    exit 1
  fi
done

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: Missing env file: ${ENV_FILE}"
  echo "FEHLER: Env-Datei fehlt: ${ENV_FILE}"
  echo
  echo "Create it with:"
  echo "Erstelle sie mit:"
  echo "  sudo nano ${ENV_FILE}"
  echo
  echo "Example content:"
  echo "Beispielinhalt:"
  echo "  SFTP_USER='your-sftp-user'"
  echo "  SFTP_PASS='your-sftp-password'"
  echo "  SFTP_HOST='your-sftp-host'"
  echo "  SFTP_PORT='22'"
  exit 1
fi

if [ "${#DOMAINS[@]}" -eq 0 ]; then
  echo "ERROR: No domains configured in DOMAINS array."
  echo "FEHLER: Keine Domains im DOMAINS-Array konfiguriert."
  exit 1
fi

for INTEGER_SETTING in MAX_LOG_AGE_DAYS SFTP_MAX_FILES_PER_RUN SFTP_FILE_DELAY_SECONDS SFTP_DOMAIN_DELAY_SECONDS SFTP_TIMEOUT_SECONDS SFTP_MAX_RETRIES SFTP_RECONNECT_INTERVAL_BASE SFTP_RECONNECT_INTERVAL_MAX; do
  if ! [[ "${!INTEGER_SETTING}" =~ ^[0-9]+$ ]]; then
    echo "ERROR: ${INTEGER_SETTING} must be a non-negative integer."
    echo "FEHLER: ${INTEGER_SETTING} muss eine nicht-negative ganze Zahl sein."
    exit 1
  fi
done

case "$RETENTION_MODE" in
  filename|mtime|none) ;;
  *)
    echo "ERROR: RETENTION_MODE must be one of: filename, mtime, none"
    echo "FEHLER: RETENTION_MODE muss einer dieser Werte sein: filename, mtime, none"
    exit 1
    ;;
esac

case "$GENERATE_LANDING_PAGE" in
  true|false) ;;
  *)
    echo "ERROR: GENERATE_LANDING_PAGE must be true or false"
    echo "FEHLER: GENERATE_LANDING_PAGE muss true oder false sein"
    exit 1
    ;;
esac

# EN: Load SFTP credentials from root-only environment file.
# DE: SFTP-Zugangsdaten aus einer nur für root lesbaren Datei laden.
source "$ENV_FILE"

: "${SFTP_USER:?Missing SFTP_USER in ${ENV_FILE}}"
: "${SFTP_PASS:?Missing SFTP_PASS in ${ENV_FILE}}"
: "${SFTP_HOST:?Missing SFTP_HOST in ${ENV_FILE}}"
: "${SFTP_PORT:=22}"

mkdir -p "$LOCAL_LOG_PATH" "$LOCAL_HTML_PATH" "$LOCAL_CONFIG_PATH"

# EN: Create GoAccess config if it does not exist.
# DE: GoAccess-Konfiguration erstellen, falls sie noch nicht existiert.
if [ ! -f "${LOCAL_CONFIG_PATH}/goaccess.conf" ]; then
  cat > "${LOCAL_CONFIG_PATH}/goaccess.conf" <<'GOACCESS_CONF'
log-format COMBINED
date-format %d/%b/%Y
time-format %H:%M:%S
ignore-crawlers false
output /html/index.html
GOACCESS_CONF
fi

CUTOFF_YYYYMMDD="00000000"
if [ "$MAX_LOG_AGE_DAYS" -gt 0 ]; then
  CUTOFF_YYYYMMDD=$(date -u -d "${MAX_LOG_AGE_DAYS} days ago" +%Y%m%d)
fi

# -----------------------------------------------------------------------------
# Main processing
# Hauptverarbeitung
# -----------------------------------------------------------------------------

DOMAIN_COUNT="${#DOMAINS[@]}"

for DOMAIN_INDEX in "${!DOMAINS[@]}"; do
  DOMAIN="${DOMAINS[$DOMAIN_INDEX]}"

  echo "============================================================"
  echo "==> Processing domain: ${DOMAIN}"
  echo "==> Verarbeite Domain: ${DOMAIN}"
  echo "============================================================"

  mkdir -p "${LOCAL_LOG_PATH}/${DOMAIN}" "${LOCAL_HTML_PATH}/${DOMAIN}"

  echo "==> Synchronizing logs via SFTP for ${DOMAIN}"
  echo "==> Synchronisiere Logs per SFTP für ${DOMAIN}"

  if [ "$RETENTION_MODE" = "filename" ]; then
    # EN:
    # Provider-friendly filename mode:
    # 1. list remote files once
    # 2. queue missing files locally
    # 3. download queued files in one SFTP session per domain
    #
    # DE:
    # Providerfreundlicher filename-Modus:
    # 1. Remote-Dateien einmal auflisten
    # 2. fehlende Dateien lokal vormerken
    # 3. vorgemerkte Dateien in einer SFTP-Session pro Domain laden
    REMOTE_FILES=$(lftp -u "${SFTP_USER},${SFTP_PASS}" "sftp://${SFTP_HOST}:${SFTP_PORT}" <<LFTP_LIST
$(write_lftp_common_settings)
cd ${REMOTE_BASE_PATH}/${DOMAIN}
cls -1 ${ACCESS_LOG_GLOB}
bye
LFTP_LIST
)

    LFTP_STATUS=$?
    if [ "$LFTP_STATUS" -ne 0 ]; then
      echo "ERROR: Could not list remote logs for ${DOMAIN}. Continuing with next domain."
      echo "FEHLER: Remote-Logs für ${DOMAIN} konnten nicht aufgelistet werden. Fahre mit nächster Domain fort."
      continue
    fi

    FILES_TO_DOWNLOAD=()
    TOTAL_MISSING_IN_WINDOW=0

    while IFS= read -r REMOTE_FILE; do
      [ -z "$REMOTE_FILE" ] && continue
      FILE_NAME=$(basename "$REMOTE_FILE")

      if ! LOG_YYYYMMDD=$(extract_yyyymmdd_from_filename "$FILE_NAME"); then
        echo "WARNING: Could not extract date from remote filename, skipping download: ${FILE_NAME}"
        echo "WARNUNG: Konnte kein Datum aus Remote-Dateiname lesen, überspringe Download: ${FILE_NAME}"
        continue
      fi

      if ! is_yyyymmdd_in_window "$LOG_YYYYMMDD" "$CUTOFF_YYYYMMDD"; then
        continue
      fi

      if [ -f "${LOCAL_LOG_PATH}/${DOMAIN}/${FILE_NAME}" ]; then
        continue
      fi

      TOTAL_MISSING_IN_WINDOW=$((TOTAL_MISSING_IN_WINDOW + 1))

      if [ "$SFTP_MAX_FILES_PER_RUN" -gt 0 ] && [ "${#FILES_TO_DOWNLOAD[@]}" -ge "$SFTP_MAX_FILES_PER_RUN" ]; then
        continue
      fi

      FILES_TO_DOWNLOAD+=("$FILE_NAME")
      echo "==> Queued missing log for download: ${FILE_NAME}"
      echo "==> Fehlendes Log für Download vorgemerkt: ${FILE_NAME}"
    done <<< "$REMOTE_FILES"

    if [ "$TOTAL_MISSING_IN_WINDOW" -eq 0 ]; then
      echo "==> No missing remote logs to download for ${DOMAIN}"
      echo "==> Keine fehlenden Remote-Logs für ${DOMAIN} herunterzuladen"
    elif [ "${#FILES_TO_DOWNLOAD[@]}" -eq 0 ]; then
      echo "==> ${TOTAL_MISSING_IN_WINDOW} missing file(s) remain, but SFTP_MAX_FILES_PER_RUN prevented this run from downloading more."
      echo "==> ${TOTAL_MISSING_IN_WINDOW} fehlende Datei(en) verbleiben, aber SFTP_MAX_FILES_PER_RUN verhindert weitere Downloads in diesem Lauf."
    else
      echo "==> Starting one SFTP download session for ${DOMAIN} with ${#FILES_TO_DOWNLOAD[@]} file(s)"
      echo "==> Starte eine SFTP-Download-Sitzung für ${DOMAIN} mit ${#FILES_TO_DOWNLOAD[@]} Datei(en)"

      LFTP_BATCH_FILE=$(mktemp)
      {
        write_lftp_common_settings
        echo "cd ${REMOTE_BASE_PATH}/${DOMAIN}"
        echo "lcd ${LOCAL_LOG_PATH}/${DOMAIN}"

        for FILE_NAME in "${FILES_TO_DOWNLOAD[@]}"; do
          echo "get ${FILE_NAME}"
          if [ "$SFTP_FILE_DELAY_SECONDS" -gt 0 ]; then
            echo "sleep ${SFTP_FILE_DELAY_SECONDS}"
          fi
        done

        echo "bye"
      } > "$LFTP_BATCH_FILE"

      if ! lftp -u "${SFTP_USER},${SFTP_PASS}" "sftp://${SFTP_HOST}:${SFTP_PORT}" < "$LFTP_BATCH_FILE"; then
        echo "WARNING: SFTP download session failed for ${DOMAIN}. Continuing with local files that are already available."
        echo "WARNUNG: SFTP-Download-Sitzung für ${DOMAIN} fehlgeschlagen. Fahre mit bereits lokal vorhandenen Dateien fort."
      fi

      rm -f "$LFTP_BATCH_FILE"
    fi
  else
    if ! lftp -u "${SFTP_USER},${SFTP_PASS}" "sftp://${SFTP_HOST}:${SFTP_PORT}" <<LFTP_MIRROR
$(write_lftp_common_settings)
mirror --verbose --only-newer --include-glob ${ACCESS_LOG_GLOB} --exclude-glob * ${REMOTE_BASE_PATH}/${DOMAIN} ${LOCAL_LOG_PATH}/${DOMAIN}
bye
LFTP_MIRROR
    then
      echo "ERROR: SFTP synchronization failed for ${DOMAIN}. Continuing with next domain."
      echo "FEHLER: SFTP-Synchronisierung für ${DOMAIN} fehlgeschlagen. Fahre mit nächster Domain fort."
      continue
    fi
  fi

  # EN: Local retention cleanup. This never deletes remote files.
  # DE: Lokales Aufräumen. Remote-Dateien werden niemals gelöscht.
  if [ "$RETENTION_MODE" = "filename" ] && [ "$MAX_LOG_AGE_DAYS" -gt 0 ]; then
    echo "==> Checking filename-based local retention for ${DOMAIN}"
    echo "==> Prüfe dateinamenbasierte lokale Aufbewahrung für ${DOMAIN}"

    OLD_LOG_COUNT=0
    while IFS= read -r LOCAL_FILE; do
      [ -z "$LOCAL_FILE" ] && continue
      FILE_NAME=$(basename "$LOCAL_FILE")

      if ! LOG_YYYYMMDD=$(extract_yyyymmdd_from_filename "$FILE_NAME"); then
        echo "WARNING: Could not extract date from local filename, keeping file: ${LOCAL_FILE}"
        echo "WARNUNG: Konnte kein Datum aus lokalem Dateinamen lesen, behalte Datei: ${LOCAL_FILE}"
        continue
      fi

      if ! is_yyyymmdd_in_window "$LOG_YYYYMMDD" "$CUTOFF_YYYYMMDD"; then
        OLD_LOG_COUNT=$((OLD_LOG_COUNT + 1))
        echo "==> Removing old local log: ${LOCAL_FILE}"
        echo "==> Entferne altes lokales Log: ${LOCAL_FILE}"
        rm -f -- "$LOCAL_FILE"
      fi
    done < <(find "${LOCAL_LOG_PATH}/${DOMAIN}" -name "${ACCESS_LOG_GLOB}" -type f | sort)

    if [ "$OLD_LOG_COUNT" -eq 0 ]; then
      echo "==> No old local logs to remove for ${DOMAIN}"
      echo "==> Keine alten lokalen Logs für ${DOMAIN} zu entfernen"
    else
      echo "==> Removed ${OLD_LOG_COUNT} old local log file(s) for ${DOMAIN}"
      echo "==> ${OLD_LOG_COUNT} alte lokale Logdatei(en) für ${DOMAIN} entfernt"
    fi
  elif [ "$RETENTION_MODE" = "mtime" ] && [ "$MAX_LOG_AGE_DAYS" -gt 0 ]; then
    echo "==> Checking mtime-based local retention for ${DOMAIN}"
    echo "==> Prüfe mtime-basierte lokale Aufbewahrung für ${DOMAIN}"

    OLD_LOG_COUNT=$(find "${LOCAL_LOG_PATH}/${DOMAIN}" -name "${ACCESS_LOG_GLOB}" -type f -mtime +"${MAX_LOG_AGE_DAYS}" | wc -l)

    if [ "$OLD_LOG_COUNT" -gt 0 ]; then
      echo "==> Found ${OLD_LOG_COUNT} old local log file(s) for ${DOMAIN}"
      echo "==> ${OLD_LOG_COUNT} alte lokale Logdatei(en) für ${DOMAIN} gefunden"
      find "${LOCAL_LOG_PATH}/${DOMAIN}" -name "${ACCESS_LOG_GLOB}" -type f -mtime +"${MAX_LOG_AGE_DAYS}" -print -delete
    else
      echo "==> No old local logs to remove for ${DOMAIN}"
      echo "==> Keine alten lokalen Logs für ${DOMAIN} zu entfernen"
    fi
  else
    echo "==> Local log cleanup disabled or not applicable for mode: ${RETENTION_MODE}"
    echo "==> Lokales Log-Aufräumen deaktiviert oder nicht anwendbar für Modus: ${RETENTION_MODE}"
  fi

  MATCHING_LOG_FILE=$(find "${LOCAL_LOG_PATH}/${DOMAIN}" \
    -name "${ACCESS_LOG_GLOB}" \
    -type f \
    -print \
    -quit)

  if [ -z "$MATCHING_LOG_FILE" ]; then
    echo "ERROR: No matching access log files found for ${DOMAIN} after synchronization and retention cleanup. Continuing with next domain."
    echo "FEHLER: Keine passenden Access-Logdateien für ${DOMAIN} nach Synchronisierung und Aufräumen gefunden. Fahre mit nächster Domain fort."
    echo "HINT: Increase MAX_LOG_AGE_DAYS, set RETENTION_MODE=none, or check whether remote logs exist for this domain."
    echo "HINWEIS: MAX_LOG_AGE_DAYS erhöhen, RETENTION_MODE=none setzen oder prüfen, ob Remote-Logs für diese Domain existieren."
    continue
  fi

  echo "==> Generating GoAccess report for ${DOMAIN}"
  echo "==> Erzeuge GoAccess-Report für ${DOMAIN}"

  if ! docker run --rm \
    -v "${LOCAL_LOG_PATH}/${DOMAIN}:/logs:ro" \
    -v "${LOCAL_HTML_PATH}/${DOMAIN}:/html" \
    -v "${LOCAL_CONFIG_PATH}/goaccess.conf:/etc/goaccess/goaccess.conf:ro" \
    --entrypoint /bin/sh \
    "${GOACCESS_IMAGE}" \
    -c "find /logs -name '${ACCESS_LOG_GLOB}' -type f | sort | xargs zcat | goaccess - -p /etc/goaccess/goaccess.conf"; then

    echo "ERROR: GoAccess report generation failed for ${DOMAIN}. Continuing with next domain."
    echo "FEHLER: GoAccess-Report für ${DOMAIN} fehlgeschlagen. Fahre mit nächster Domain fort."
    continue
  fi

  echo "==> Successfully processed ${DOMAIN}"
  echo "==> ${DOMAIN} erfolgreich verarbeitet"

  if [ "$SFTP_DOMAIN_DELAY_SECONDS" -gt 0 ] && [ "$DOMAIN_INDEX" -lt $((DOMAIN_COUNT - 1)) ]; then
    echo "==> Waiting ${SFTP_DOMAIN_DELAY_SECONDS} second(s) before next domain"
    echo "==> Warte ${SFTP_DOMAIN_DELAY_SECONDS} Sekunde(n) vor der nächsten Domain"
    sleep "$SFTP_DOMAIN_DELAY_SECONDS"
  fi
done

# EN: Generate the root landing page after all domain reports were processed.
# DE: Startseite im Wurzelverzeichnis erzeugen, nachdem alle Domain-Reports verarbeitet wurden.
generate_landing_page

# EN: Adjust ownership so files are readable by the web container/user.
# DE: Besitzrechte anpassen, damit die Dateien vom Webcontainer/User gelesen werden können.
chown -R 1000:1000 "$LOCAL_BASE"

echo "==> Done"
echo "==> Fertig"
