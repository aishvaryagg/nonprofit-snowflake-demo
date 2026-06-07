# United Way Affiliate Financial Health — Snowflake Demo

A data pipeline and analytics project built in Snowflake to analyze the financial health of United Way affiliate organizations across four U.S. states (CA, NY, TX, VA), using IRS Exempt Organization and Form 990 data.

## Project Overview

This project demonstrates an end-to-end data workflow in Snowflake:

1. **Schema setup** — creates a layered database architecture (RAW → STAGING → CLEAN)
2. **Staging & validation** — consolidates multi-state affiliate data, joins with IRS 990 filings, and runs data quality checks
3. **Dashboard views** — surfaces financial KPIs and risk categories ready for BI tools

## Data Sources

| Source | Description |
|--------|-------------|
| `EO_CA`, `EO_NY`, `EO_TX`, `EO_VA` | IRS Exempt Organization lists by state |
| `IRS_990` | Form 990 financial filings (revenue, expenses, assets, liabilities) |

## File Structure

```
Create_DB_Schema.sql      — Database and schema setup (RAW, STAGING, CLEAN layers)
Staging_Validation.sql    — Data ingestion, join logic, validation checks, and analytics views
Dashboard_View.sql        — Final risk-categorized dashboard view
```

## Key Metrics Computed

| Metric | Formula |
|--------|---------|
| `OPERATING_MARGIN` | Total Revenue − Total Functional Expenses |
| `EXPENSE_RATIO_PCT` | (Expenses / Revenue) × 100 |
| `LIABILITY_TO_ASSET_RATIO_PCT` | (Total Liabilities / Total Assets) × 100 |
| `RISK_CATEGORY` | Flags orgs as `NEGATIVE_MARGIN`, `HIGH_EXPENSE_RATIO`, `HIGH_LIABILITY`, or `NORMAL` |

## Dashboard View

`VW_FINANCIAL_HEALTH_DASHBOARD` combines all computed metrics and assigns a risk category to each affiliate, making it ready to connect to Snowsight charts or any external BI tool.

## Tech Stack

- **Snowflake** — data warehouse, SQL worksheets, views
- **IRS public data** — EO database + Form 990 extracts
