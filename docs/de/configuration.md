# Konfiguration

Die wichtigsten Einstellungen stehen oben im Script:

```bash
DOMAINS=("example.org" "example.com")
MAX_LOG_AGE_DAYS=365
REMOTE_BASE_PATH="www_logs"
LOCAL_BASE="/opt/goaccess/static-log-reports"
ACCESS_LOG_GLOB="access.log.*.gz"
RETENTION_MODE="filename"
LOG_DATE_REGEX='access\.log\.([0-9]{8})\.gz'
```

## Domains

Eine Domain:

```bash
DOMAINS=("example.org")
```

Mehrere Domains:

```bash
DOMAINS=("example.org" "example.com" "sub.example.org")
```

Pro Domain wird ein eigener Report erzeugt.

## Retention

```bash
MAX_LOG_AGE_DAYS=365
```

Das Script behält lokal nur Logs im konfigurierten Zeitraum. Remote-Dateien werden niemals gelöscht.

```bash
MAX_LOG_AGE_DAYS=0
```

deaktiviert lokale Aufräumlogik und datumsgesteuerte Download-Einschränkung.

## Retention-Modi

```bash
RETENTION_MODE="filename"
```

Nutzt das Datum im Dateinamen. Das ist ideal für Dateien wie:

```text
access.log.20260607.gz
```

```bash
RETENTION_MODE="mtime"
```

nutzt das lokale Änderungsdatum. Das ist generischer, aber weniger exakt.

```bash
RETENTION_MODE="none"
```

lädt/behält alles, was zum `ACCESS_LOG_GLOB` passt.

## Providerfreundliche SFTP-Drosselung

```bash
SFTP_MAX_FILES_PER_RUN=25
SFTP_FILE_DELAY_SECONDS=2
SFTP_DOMAIN_DELAY_SECONDS=5
```

`SFTP_MAX_FILES_PER_RUN` begrenzt, wie viele fehlende Dateien pro Domain und Scriptlauf geladen werden.

Für sehr vorsichtige Provider:

```bash
SFTP_MAX_FILES_PER_RUN=5
SFTP_FILE_DELAY_SECONDS=5
SFTP_DOMAIN_DELAY_SECONDS=10
```

Für initiale Backfills kannst du temporär erhöhen:

```bash
SFTP_MAX_FILES_PER_RUN=100
SFTP_FILE_DELAY_SECONDS=1
SFTP_DOMAIN_DELAY_SECONDS=5
```

Im normalen täglichen Betrieb wird meist nur eine neue Datei pro Domain geladen.

## Keine Wartezeit nach letzter Domain

Das Script wartet nur zwischen Domains, nicht mehr nach der letzten Domain. Dadurch wird am Ende direkt die Landing Page erzeugt.

## GeoIP

GeoIP ist in diesem Projekt absichtlich nicht standardmäßig aktiviert.

GoAccess kann Länder- oder Stadtstatistiken nur erzeugen, wenn zusätzlich eine GeoIP-Datenbank wie MaxMind GeoLite2 oder DB-IP bereitgestellt und in den Container gemountet wird. Diese Datenbanken haben eigene Lizenz-, Download- und Update-Anforderungen.

Da dieses Projekt bewusst schlank bleiben soll, wird keine GeoIP-Datenbank mitgeliefert und keine automatische GeoIP-Aktualisierung eingerichtet. Außerdem anonymisieren manche Hosting-Provider IP-Adressen in Weblogs, wodurch GeoIP-Auswertungen ungenau oder unvollständig sein können.

Wer GeoIP nutzen möchte, kann es später manuell ergänzen, indem eine passende `.mmdb`-Datei gemountet und `geoip-database` in der GoAccess-Konfiguration gesetzt wird.
