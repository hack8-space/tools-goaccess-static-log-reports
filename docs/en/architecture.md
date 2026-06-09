# Architecture

The setup consists of two separate parts:

```text
Cron on the host
  ├─ list SFTP logs per domain
  ├─ download missing logs provider-friendly
  ├─ apply local retention
  ├─ briefly start GoAccess in Docker
  └─ generate static HTML reports

nginx container
  └─ only serves /opt/goaccess/static-log-reports/html
```

GoAccess does not run permanently. After the build, the container exits automatically.

## Provider-friendly download

In filename mode, the script opens:

```text
1 SFTP session for listing per domain
1 SFTP session for downloads per domain
```

Missing files are queued first and then downloaded slowly. This is much gentler than opening a new SFTP connection for every file.

## Landing page

After all domain reports, the script generates:

```text
/opt/goaccess/static-log-reports/html/index.html
```

This page automatically links to all configured domains.
