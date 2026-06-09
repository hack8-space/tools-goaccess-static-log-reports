# GeoIP

GeoIP is intentionally not enabled by default in this project.

## Why not by default?

GoAccess can generate geographic reports only if an additional GeoIP database is provided. Common databases are MaxMind GeoLite2 or DB-IP. These databases must be obtained, licensed, stored, and updated separately.

This project is intentionally kept simple:

```text
SFTP logs → GoAccess → static HTML reports
```

Because of that, it does not ship a GeoIP database and does not set up automatic GeoIP updates.

## Limitations with anonymized logs

Some hosting providers anonymize IP addresses in web logs. In that case, GeoIP may only work partially. Countries may still be roughly detectable, while cities or precise regions are often unreliable or empty.

## Manual extension

If you still want GeoIP, you can provide a suitable `.mmdb` file later and mount it into the GoAccess container.

Example structure:

```text
/opt/goaccess/static-log-reports/geoip/GeoLite2-City.mmdb
```

Then add this to the GoAccess configuration:

```conf
geoip-database /geoip/GeoLite2-City.mmdb
```

And add this mount to the Docker run command in the script:

```bash
-v "${LOCAL_BASE}/geoip:/geoip:ro"
```

This extension is intentionally not part of the default configuration.
