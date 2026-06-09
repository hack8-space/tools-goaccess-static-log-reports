# Configuration

The most important settings are at the top of the script:

```bash
DOMAINS=("example.org" "example.com")
MAX_LOG_AGE_DAYS=365
REMOTE_BASE_PATH="www_logs"
LOCAL_BASE="/opt/goaccess/static-log-reports"
ACCESS_LOG_GLOB="access.log.*.gz"
RETENTION_MODE="filename"
LOG_DATE_REGEX='access\.log\.([0-9]{8})\.gz'
```

## Domains

One domain:

```bash
DOMAINS=("example.org")
```

Multiple domains:

```bash
DOMAINS=("example.org" "example.com" "sub.example.org")
```

A separate report is generated for each domain.

## Retention

```bash
MAX_LOG_AGE_DAYS=365
```

The script only keeps local logs within the configured time window. Remote files are never deleted.

```bash
MAX_LOG_AGE_DAYS=0
```

disables local cleanup and date-based download filtering.

## Retention modes

```bash
RETENTION_MODE="filename"
```

Uses the date in the filename. This is ideal for files like:

```text
access.log.20260607.gz
```

```bash
RETENTION_MODE="mtime"
```

uses the local modification time. This is more generic, but less exact.

```bash
RETENTION_MODE="none"
```

loads/keeps everything matching `ACCESS_LOG_GLOB`.

## Provider-friendly SFTP throttling

```bash
SFTP_MAX_FILES_PER_RUN=25
SFTP_FILE_DELAY_SECONDS=2
SFTP_DOMAIN_DELAY_SECONDS=5
```

`SFTP_MAX_FILES_PER_RUN` limits how many missing files are downloaded per domain and script run.

For sensitive providers:

```bash
SFTP_MAX_FILES_PER_RUN=5
SFTP_FILE_DELAY_SECONDS=5
SFTP_DOMAIN_DELAY_SECONDS=10
```

For initial backfills, you can temporarily increase it:

```bash
SFTP_MAX_FILES_PER_RUN=100
SFTP_FILE_DELAY_SECONDS=1
SFTP_DOMAIN_DELAY_SECONDS=5
```

During normal daily operation, usually only one new file per domain is downloaded.

## No delay after the last domain

The script waits only between domains, not after the last domain. This means the landing page is generated immediately at the end.

## GeoIP

GeoIP is intentionally not enabled by default in this project.

GoAccess can generate country or city statistics only if an additional GeoIP database such as MaxMind GeoLite2 or DB-IP is provided and mounted into the container. These databases have their own licensing, download, and update requirements.

This project is intentionally kept lightweight, so it does not ship a GeoIP database and does not set up automatic GeoIP updates. Also, some hosting providers anonymize IP addresses in web logs, which can make GeoIP results inaccurate or incomplete.

If you want GeoIP, you can add it manually later by mounting a suitable `.mmdb` file and setting `geoip-database` in the GoAccess configuration.
