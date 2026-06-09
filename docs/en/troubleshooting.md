# Troubleshooting

## `Syntax error: "(" unexpected`

The script was executed with `sh` instead of Bash.

Correct:

```bash
sudo /usr/local/bin/update-static-goaccess-reports.sh
```

or:

```bash
sudo bash /usr/local/bin/update-static-goaccess-reports.sh
```

Wrong:

```bash
sudo sh /usr/local/bin/update-static-goaccess-reports.sh
```

The first line must be:

```bash
#!/bin/bash
```

## Single quote at the end of the file

If you accidentally copied a Python wrapper, the script may contain lines like:

```text
script = r'''#!/bin/bash
'''
```

These lines must not be part of the shell script.

Check with:

```bash
sudo head -n 3 /usr/local/bin/update-static-goaccess-reports.sh
sudo tail -n 5 /usr/local/bin/update-static-goaccess-reports.sh
sudo bash -n /usr/local/bin/update-static-goaccess-reports.sh
```

## Provider/SFTP limits

If SFTP connections hang or fail, reduce:

```bash
SFTP_MAX_FILES_PER_RUN=5
SFTP_FILE_DELAY_SECONDS=5
SFTP_DOMAIN_DELAY_SECONDS=10
```

If everything is stable, these defaults are reasonable:

```bash
SFTP_MAX_FILES_PER_RUN=25
SFTP_FILE_DELAY_SECONDS=2
SFTP_DOMAIN_DELAY_SECONDS=5
```

## No access logs found

Check locally:

```bash
sudo find /opt/goaccess/static-log-reports/logs/<domain> -name 'access.log.*.gz' -type f | sort
```

Check remotely:

```bash
sudo bash -c 'source /root/.goaccess-sftp.env && lftp -u "$SFTP_USER,$SFTP_PASS" "sftp://$SFTP_HOST:$SFTP_PORT" <<EOF
cd www_logs/<domain>
cls -1 access.log.*.gz
bye
EOF'
```

## GoAccess parsing fails

Check `config/goaccess.conf`:

```conf
log-format COMBINED
date-format %d/%b/%Y
time-format %H:%M:%S
ignore-crawlers false
output /html/index.html
```

If your provider does not use Combined log format, `log-format` must be adjusted.
