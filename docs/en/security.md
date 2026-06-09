# Security

Real SFTP credentials must not be committed to the repository.

They are stored locally on the server at:

```text
/root/.goaccess-sftp.env
```

Permissions:

```bash
sudo chmod 600 /root/.goaccess-sftp.env
sudo chown root:root /root/.goaccess-sftp.env
```

The nginx container only gets access to:

```text
/opt/goaccess/static-log-reports/html
```

This contains only static HTML reports, no SFTP credentials and no raw logs.

## GeoIP

GeoIP is intentionally not enabled by default in this project.

GoAccess can generate country or city statistics only if an additional GeoIP database such as MaxMind GeoLite2 or DB-IP is provided and mounted into the container. These databases have their own licensing, download, and update requirements.

This project is intentionally kept lightweight, so it does not ship a GeoIP database and does not set up automatic GeoIP updates. Also, some hosting providers anonymize IP addresses in web logs, which can make GeoIP results inaccurate or incomplete.

If you want GeoIP, you can add it manually later by mounting a suitable `.mmdb` file and setting `geoip-database` in the GoAccess configuration.
