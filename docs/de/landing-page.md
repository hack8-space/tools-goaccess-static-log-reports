# Landing Page

Das Script erzeugt automatisch eine statische Startseite:

```text
/opt/goaccess/static-log-reports/html/index.html
```

Sie zeigt Karten für alle Einträge aus `DOMAINS=(...)`.

Wenn ein Report existiert, wird die Karte verlinkt. Wenn noch kein Report erzeugt wurde, erscheint die Karte als `Report missing`.

Die Texte können oben im Script angepasst werden:

```bash
LANDING_PAGE_TITLE="Static GoAccess Reports"
LANDING_PAGE_KICKER="STATIC REPORTS / GOACCESS"
LANDING_PAGE_SUBTITLE="Daily SFTP web access logs turned into static HTML reports."
LANDING_PAGE_DESCRIPTION="..."
LANDING_PAGE_FOOTER="Generated locally from server access logs."
```

## Weitere Beispiele

Ein Screenshot eines generierten GoAccess-Reports ist in [`screenshots.md`](screenshots.md) dokumentiert.
