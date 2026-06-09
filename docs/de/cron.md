# Cron

Da viele Provider tägliche Logdateien erst nach Mitternacht bereitstellen, ist ein täglicher Lauf ausreichend.

Empfohlen:

```cron
37 3 * * * /usr/local/bin/update-static-goaccess-reports.sh >> /var/log/update-static-goaccess-reports.log 2>&1
```

Eintragen mit:

```bash
sudo crontab -e
```

Prüfen:

```bash
sudo crontab -l
sudo tail -n 100 /var/log/update-static-goaccess-reports.log
```

Während eines großen Backfills kann das Script über mehrere Läufe hinweg fehlende Dateien nachziehen. Dafür ist `SFTP_MAX_FILES_PER_RUN` zuständig.
