# Sicherheit

Die echten SFTP-Zugangsdaten gehören nicht ins Repository.

Sie liegen lokal auf dem Server unter:

```text
/root/.goaccess-sftp.env
```

Rechte:

```bash
sudo chmod 600 /root/.goaccess-sftp.env
sudo chown root:root /root/.goaccess-sftp.env
```

Der nginx-Container erhält nur Zugriff auf:

```text
/opt/goaccess/static-log-reports/html
```

Dort liegen nur statische HTML-Reports, keine SFTP-Zugangsdaten und keine Rohlogs.

## GeoIP

GeoIP ist in diesem Projekt absichtlich nicht standardmäßig aktiviert.

GoAccess kann Länder- oder Stadtstatistiken nur erzeugen, wenn zusätzlich eine GeoIP-Datenbank wie MaxMind GeoLite2 oder DB-IP bereitgestellt und in den Container gemountet wird. Diese Datenbanken haben eigene Lizenz-, Download- und Update-Anforderungen.

Da dieses Projekt bewusst schlank bleiben soll, wird keine GeoIP-Datenbank mitgeliefert und keine automatische GeoIP-Aktualisierung eingerichtet. Außerdem anonymisieren manche Hosting-Provider IP-Adressen in Weblogs, wodurch GeoIP-Auswertungen ungenau oder unvollständig sein können.

Wer GeoIP nutzen möchte, kann es später manuell ergänzen, indem eine passende `.mmdb`-Datei gemountet und `geoip-database` in der GoAccess-Konfiguration gesetzt wird.
