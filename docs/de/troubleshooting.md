# Troubleshooting

## `Syntax error: "(" unexpected`

Das Script wurde mit `sh` statt Bash ausgeführt.

Richtig:

```bash
sudo /usr/local/bin/update-static-goaccess-reports.sh
```

oder:

```bash
sudo bash /usr/local/bin/update-static-goaccess-reports.sh
```

Falsch:

```bash
sudo sh /usr/local/bin/update-static-goaccess-reports.sh
```

Die erste Zeile muss lauten:

```bash
#!/bin/bash
```

## Einzelnes Quote am Dateiende

Wenn du beim Kopieren versehentlich Python-Wrapper eingefügt hast, können am Anfang oder Ende solche Zeilen stehen:

```text
script = r'''#!/bin/bash
'''
```

Diese Zeilen dürfen nicht im Shell-Script stehen.

Prüfen:

```bash
sudo head -n 3 /usr/local/bin/update-static-goaccess-reports.sh
sudo tail -n 5 /usr/local/bin/update-static-goaccess-reports.sh
sudo bash -n /usr/local/bin/update-static-goaccess-reports.sh
```

## Provider-/SFTP-Limits

Wenn SFTP-Verbindungen hängen oder abbrechen, reduziere:

```bash
SFTP_MAX_FILES_PER_RUN=5
SFTP_FILE_DELAY_SECONDS=5
SFTP_DOMAIN_DELAY_SECONDS=10
```

Wenn alles stabil läuft, sind diese Defaults sinnvoll:

```bash
SFTP_MAX_FILES_PER_RUN=25
SFTP_FILE_DELAY_SECONDS=2
SFTP_DOMAIN_DELAY_SECONDS=5
```

## Keine Access-Logs gefunden

Prüfe lokal:

```bash
sudo find /opt/goaccess/static-log-reports/logs/<domain> -name 'access.log.*.gz' -type f | sort
```

Prüfe remote:

```bash
sudo bash -c 'source /root/.goaccess-sftp.env && lftp -u "$SFTP_USER,$SFTP_PASS" "sftp://$SFTP_HOST:$SFTP_PORT" <<EOF
cd www_logs/<domain>
cls -1 access.log.*.gz
bye
EOF'
```

## GoAccess-Parsing schlägt fehl

Prüfe `config/goaccess.conf`:

```conf
log-format COMBINED
date-format %d/%b/%Y
time-format %H:%M:%S
ignore-crawlers false
output /html/index.html
```

Wenn dein Provider kein Combined-Logformat nutzt, muss `log-format` angepasst werden.
