# Landing Page

The script automatically generates a static landing page:

```text
/opt/goaccess/static-log-reports/html/index.html
```

It shows cards for all entries from `DOMAINS=(...)`.

If a report exists, the card is linked. If no report has been generated yet, the card is shown as `Report missing`.

The text can be adjusted at the top of the script:

```bash
LANDING_PAGE_TITLE="Static GoAccess Reports"
LANDING_PAGE_KICKER="STATIC REPORTS / GOACCESS"
LANDING_PAGE_SUBTITLE="Daily SFTP web access logs turned into static HTML reports."
LANDING_PAGE_DESCRIPTION="..."
LANDING_PAGE_FOOTER="Generated locally from server access logs."
```

## Further examples

A screenshot of a generated GoAccess report is documented in [`screenshots.md`](screenshots.md).
