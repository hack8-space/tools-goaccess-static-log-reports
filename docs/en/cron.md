# Cron

Many providers expose daily log files only after midnight, so one run per day is usually enough.

Recommended:

```cron
37 3 * * * /usr/local/bin/update-static-goaccess-reports.sh >> /var/log/update-static-goaccess-reports.log 2>&1
```

Install with:

```bash
sudo crontab -e
```

Check with:

```bash
sudo crontab -l
sudo tail -n 100 /var/log/update-static-goaccess-reports.log
```

During a large backfill, the script may download missing files over multiple runs. This is controlled by `SFTP_MAX_FILES_PER_RUN`.
