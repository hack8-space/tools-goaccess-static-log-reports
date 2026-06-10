# Screenshots und Beispielausgabe

Das Projekt erzeugt eine eigene statische Landing Page und zusätzlich pro Domain einen normalen GoAccess-Report. Die Screenshots zeigen den groben Ablauf und die wichtigsten Ausgaben, ohne sensible Infrastrukturdetails offenzulegen.

## Landing Page

Die Landing Page liegt unter:

```text
/opt/goaccess/static-log-reports/html/index.html
```

Sie verlinkt automatisch auf alle Domains aus `DOMAINS=(...)` und dient als Einstiegspunkt für mehrere statische Reports.

![Landing Page mit mehreren statischen Webserver-Reports](../assets/landing-page-webserver.png)

**Was zu sehen ist:**

- eine kompakte Übersicht über mehrere konfigurierte Domains
- Statuskarten mit Zeitstempel der letzten Report-Erzeugung
- direkte Links zu den einzelnen Domain-Reports
- ein rein statischer Einstieg ohne laufende Analytics-Webanwendung

## GoAccess-Report: Übersicht

Jeder Domain-Report wird von GoAccess selbst erzeugt und liegt unter:

```text
/opt/goaccess/static-log-reports/html/<domain>/index.html
```

![Beispiel eines generierten GoAccess-Reports](../assets/goaccess-report-example.png)

**Was zu sehen ist:**

- aggregierte Kennzahlen zu Requests, Besuchern und Bandbreite
- zeitliche Verteilung der Zugriffe
- angefragte Dateien und Pfade
- Statuscodes und typische technische Metriken
- Browser-, Betriebssystem- und Referrer-Blöcke, soweit die Logs diese Informationen enthalten

Der Screenshot zeigt Beispiel-/Demoausgaben. Für öffentliche Repositories sollten keine Screenshots verwendet werden, die echte IP-Adressen, Zugangsdaten, interne Hostnamen, private Query-Parameter oder vertrauliche Referrer enthalten.

## GoAccess-Report: lange Seitenansicht

GoAccess fasst viele Auswertungsbereiche in einer einzigen HTML-Datei zusammen. Die lange Seitenansicht zeigt den Report im Verlauf.

![Lange Seitenansicht eines GoAccess-Reports](../assets/goaccess-report-example.page.png)

**Was zu sehen ist:**

- mehrere Report-Blöcke untereinander
- technische Detailbereiche wie Requests, Dateien, Statuscodes, Betriebssysteme und Browser
- eine statische HTML-Ausgabe, die auch ohne Datenbank oder Live-Dienst geöffnet werden kann

Diese Ansicht ist hilfreich, um zu verstehen, dass der Report nicht nur aus einer Kennzahlenkarte besteht, sondern viele Logbereiche in einer Datei zusammenführt.

## Script-Testlauf

Das Update-Script kann so ausgeführt werden, dass der Ablauf nachvollziehbar im Terminal sichtbar wird.

![Terminalausgabe eines Testlaufs für das Update-Script](../assets/script_test_run_output.png)

**Was zu sehen ist:**

- Laden und Prüfen der Konfiguration
- SFTP-/Log-Verarbeitungsschritte
- Erzeugung der statischen GoAccess-Ausgabe
- Prüfung, ob die erwarteten Ergebnisdateien vorhanden sind
- klare Konsolenausgabe für Fehlersuche und Betrieb

Der Testlauf dient vor allem der Kontrolle: Man sieht, welche Schritte ausgeführt wurden und an welcher Stelle ein Problem auftreten würde.

## Hinweis zur Veröffentlichung von Screenshots

Vor dem Veröffentlichen eigener Screenshots sollten sensible Details entfernt oder durch Beispieldaten ersetzt werden. Dazu gehören insbesondere:

- IP-Adressen
- Zugangsdaten oder Tokens
- interne Hostnamen
- private Pfade und Query-Parameter
- vertrauliche Referrer
- Kundennamen oder andere personenbezogene Informationen
