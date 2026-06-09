# Installation

## Requirements

The host needs:

```bash
sudo apt update
sudo apt install lftp docker.io
```

Docker must be working.

## Install project files

Copy the script:

```bash
sudo cp scripts/update-static-goaccess-reports.sh /usr/local/bin/update-static-goaccess-reports.sh
sudo chmod +x /usr/local/bin/update-static-goaccess-reports.sh
```

The script creates these directories automatically:

```text
/opt/goaccess/static-log-reports/logs/
/opt/goaccess/static-log-reports/html/
/opt/goaccess/static-log-reports/config/
```

## SFTP credentials

Copy the example file:

```bash
sudo cp examples/goaccess-sftp.env.example /root/.goaccess-sftp.env
sudo nano /root/.goaccess-sftp.env
```

Content:

```bash
SFTP_USER='your-sftp-user'
SFTP_PASS='your-sftp-password'
SFTP_HOST='your-sftp-host.example.org'
SFTP_PORT='22'
```

Set permissions:

```bash
sudo chmod 600 /root/.goaccess-sftp.env
sudo chown root:root /root/.goaccess-sftp.env
```

## Test

```bash
sudo bash -n /usr/local/bin/update-static-goaccess-reports.sh
sudo /usr/local/bin/update-static-goaccess-reports.sh
```

## Web server

The nginx container serves only static HTML files:

```bash
docker compose up -d
```

The landing page is then available at:

```text
http://<server>:7881/
```
