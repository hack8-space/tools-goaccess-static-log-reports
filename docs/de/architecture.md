# Architektur

Das Setup besteht aus zwei getrennten Teilen:

```text
Cron auf dem Host
  ├─ SFTP-Logs pro Domain auflisten
  ├─ fehlende Logs providerfreundlich herunterladen
  ├─ lokale Retention anwenden
  ├─ GoAccess kurz in Docker starten
  └─ statische HTML-Reports erzeugen

nginx-Container
  └─ liefert nur /opt/goaccess/static-log-reports/html aus
```

GoAccess läuft nicht dauerhaft. Nach dem Build beendet sich der Container automatisch.

## Providerfreundlicher Download

Im filename-Modus öffnet das Script:

```text
1 SFTP-Session zum Auflisten pro Domain
1 SFTP-Session zum Herunterladen pro Domain
```

Fehlende Dateien werden zuerst gesammelt und dann langsam geladen. Das ist deutlich sanfter als eine neue SFTP-Verbindung pro Datei.

## Landing Page

Nach allen Domain-Reports erzeugt das Script:

```text
/opt/goaccess/static-log-reports/html/index.html
```

Diese Seite verlinkt automatisch auf alle konfigurierten Domains.
