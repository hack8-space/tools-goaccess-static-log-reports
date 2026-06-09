# Screenshots und Beispielausgabe

Das Projekt erzeugt eine eigene statische Landing Page und zusätzlich pro Domain einen normalen GoAccess-Report.

## Landing Page

Die Landing Page liegt unter:

```text
/opt/goaccess/static-log-reports/html/index.html
```

Sie verlinkt automatisch auf alle Domains aus `DOMAINS=(...)`.

## GoAccess-Report

Jeder Domain-Report wird von GoAccess selbst erzeugt und liegt unter:

```text
/opt/goaccess/static-log-reports/html/<domain>/index.html
```

Beispiel:

![Beispiel eines generierten GoAccess-Reports](../assets/goaccess-report-example.png)

Der Screenshot zeigt aggregierte Statistikdaten. Für öffentliche Repositories sollten keine Screenshots verwendet werden, die echte IP-Adressen, Zugangsdaten, interne Hostnamen, private Query-Parameter oder vertrauliche Referrer enthalten.
