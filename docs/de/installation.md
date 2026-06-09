# Installation

## Voraussetzungen

Auf dem Host werden benötigt:

```bash
sudo apt update
sudo apt install lftp docker.io
```

Außerdem muss Docker lauffähig sein.

## Projektdateien installieren

Script kopieren:

```bash
sudo cp scripts/update-static-goaccess-reports.sh /usr/local/bin/update-static-goaccess-reports.sh
sudo chmod +x /usr/local/bin/update-static-goaccess-reports.sh
```

Konfigurationsverzeichnisse werden vom Script automatisch erstellt:

```text
/opt/goaccess/static-log-reports/logs/
/opt/goaccess/static-log-reports/html/
/opt/goaccess/static-log-reports/config/
```

## SFTP-Zugangsdaten

Beispieldatei kopieren:

```bash
sudo cp examples/goaccess-sftp.env.example /root/.goaccess-sftp.env
sudo nano /root/.goaccess-sftp.env
```

Inhalt:

```bash
SFTP_USER='your-sftp-user'
SFTP_PASS='your-sftp-password'
SFTP_HOST='your-sftp-host.example.org'
SFTP_PORT='22'
```

Rechte setzen:

```bash
sudo chmod 600 /root/.goaccess-sftp.env
sudo chown root:root /root/.goaccess-sftp.env
```

## Test

```bash
sudo bash -n /usr/local/bin/update-static-goaccess-reports.sh
sudo /usr/local/bin/update-static-goaccess-reports.sh
```

## Webserver

Der nginx-Container liefert nur statische HTML-Dateien aus:

```bash
docker compose up -d
```

Danach ist die Landing Page erreichbar unter:

```text
http://<server>:7881/
```
