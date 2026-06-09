# GeoIP

GeoIP ist in diesem Projekt absichtlich nicht standardmäßig aktiviert.

## Warum nicht standardmäßig?

GoAccess kann geografische Auswertungen nur erzeugen, wenn zusätzlich eine GeoIP-Datenbank bereitgestellt wird. Typische Datenbanken sind MaxMind GeoLite2 oder DB-IP. Diese Datenbanken müssen separat bezogen, lizenziert, gespeichert und regelmäßig aktualisiert werden.

Dieses Projekt soll bewusst einfach bleiben:

```text
SFTP-Logs → GoAccess → statische HTML-Reports
```

Deshalb wird keine GeoIP-Datenbank mitgeliefert und keine automatische GeoIP-Aktualisierung eingerichtet.

## Einschränkungen durch anonymisierte Logs

Manche Hosting-Provider anonymisieren IP-Adressen in Weblogs. In diesem Fall kann GeoIP nur eingeschränkt funktionieren. Länder können eventuell noch grob erkannt werden, Städte oder exakte Regionen sind oft unzuverlässig oder leer.

## Manuelle Erweiterung

Wer GeoIP trotzdem verwenden möchte, kann später eine passende `.mmdb`-Datei bereitstellen und in den GoAccess-Container mounten.

Beispielstruktur:

```text
/opt/goaccess/static-log-reports/geoip/GeoLite2-City.mmdb
```

Dann müsste die GoAccess-Konfiguration ergänzt werden:

```conf
geoip-database /geoip/GeoLite2-City.mmdb
```

Und der Docker-Run im Script müsste zusätzlich dieses Verzeichnis mounten:

```bash
-v "${LOCAL_BASE}/geoip:/geoip:ro"
```

Diese Erweiterung ist bewusst nicht Teil der Standardkonfiguration.
