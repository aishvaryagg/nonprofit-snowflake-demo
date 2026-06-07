-- ============================================================
-- STEP 1: Combine affiliate data from all four states
-- ============================================================
CREATE OR REPLACE TABLE UWW_DEMO.STAGING.UNITED_WAY_AFFILIATES AS

SELECT
    'CA' AS SOURCE_STATE,
    EIN,
    NAME,
    CITY,
    STATE,
    ZIP,
    ACTIVITY,
    RULING,
    TAX_PERIOD,
    REVENUE_AMT,
    ASSET_AMT,
    INCOME_AMT,
    NTEE_CD
FROM UWW_DEMO.RAW.EO_CA

UNION ALL

SELECT
    'NY' AS SOURCE_STATE,
    EIN,
    NAME,
    CITY,
    STATE,
    ZIP,
    ACTIVITY,
    RULING,
    TAX_PERIOD,
    REVENUE_AMT,
    ASSET_AMT,
    INCOME_AMT,
    NTEE_CD
FROM UWW_DEMO.RAW.EO_NY

UNION ALL

SELECT
    'TX' AS SOURCE_STATE,
    EIN,
    NAME,
    CITY,
    STATE,
    ZIP,
    ACTIVITY,
    RULING,
    TAX_PERIOD,
    REVENUE_AMT,
    ASSET_AMT,
    INCOME_AMT,
    NTEE_CD
FROM UWW_DEMO.RAW.EO_TX

UNION ALL

SELECT
    'VA' AS SOURCE_STATE,
    EIN,
    NAME,
    CITY,
    STATE,
    ZIP,
    ACTIVITY,
    RULING,
    TAX_PERIOD,
    REVENUE_AMT,
    ASSET_AMT,
    INCOME_AMT,
    NTEE_CD
FROM UWW_DEMO.RAW.EO_VA;


-- ============================================================
-- STEP 2: Validation checks
-- ============================================================

-- Total row count
SELECT COUNT(*) AS TOTAL_ROWS
FROM UWW_DEMO.STAGING.UNITED_WAY_AFFILIATES;

-- Row count by state
SELECT SOURCE_STATE, COUNT(*) AS ROW_COUNT
FROM UWW_DEMO.STAGING.UNITED_WAY_AFFILIATES
GROUP BY SOURCE_STATE
ORDER BY SOURCE_STATE;

-- Duplicate EINs check
SELECT EIN, COUNT(*) AS DUP_COUNT
FROM UWW_DEMO.STAGING.UNITED_WAY_AFFILIATES
GROUP BY EIN
HAVING COUNT(*) > 1;


-- ============================================================
-- STEP 3: Join affiliates with IRS 990 financial data
-- ============================================================

DESC TABLE UWW_DEMO.RAW.IRS_990;

CREATE OR REPLACE TABLE UWW_DEMO.CLEAN.UNITED_WAY_FINAL AS
SELECT
    a.SOURCE_STATE,
    a.EIN,
    a.NAME,
    a.CITY,
    a.STATE,
    a.NTEE_CD,

    i.TAX_PD,
    i.TOTREVENUE,
    i.TOTFUNCEXPNS,
    i.TOTASSETSEND,
    i.TOTLIABEND,
    i.TOTNETASSETEND

FROM UWW_DEMO.STAGING.UNITED_WAY_AFFILIATES a
LEFT JOIN UWW_DEMO.RAW.IRS_990 i
    ON a.EIN = i.EIN;


-- ============================================================
-- STEP 4: Post-join validation
-- ============================================================

-- Total rows in final table
SELECT COUNT(*)
FROM UWW_DEMO.CLEAN.UNITED_WAY_FINAL;

-- Duplicates in final table (affiliates with multiple 990 filings)
SELECT
    EIN,
    COUNT(*) AS RECORDS
FROM UWW_DEMO.CLEAN.UNITED_WAY_FINAL
GROUP BY EIN
HAVING COUNT(*) > 1
ORDER BY RECORDS DESC;

-- Affiliates with no matching IRS 990 record
SELECT
    a.SOURCE_STATE,
    a.EIN,
    a.NAME,
    a.CITY,
    a.STATE
FROM UWW_DEMO.STAGING.UNITED_WAY_AFFILIATES a
LEFT JOIN UWW_DEMO.RAW.IRS_990 i
    ON a.EIN = i.EIN
WHERE i.EIN IS NULL
ORDER BY a.SOURCE_STATE, a.NAME;


-- ============================================================
-- STEP 5: Data quality summary view
-- ============================================================

CREATE OR REPLACE VIEW UWW_DEMO.CLEAN.VW_DATA_QUALITY_SUMMARY AS

SELECT
    'TOTAL_AFFILIATES' AS METRIC,
    COUNT(*)::VARCHAR AS VALUE
FROM UWW_DEMO.STAGING.UNITED_WAY_AFFILIATES

UNION ALL

SELECT
    'TOTAL_FINAL_ROWS',
    COUNT(*)::VARCHAR
FROM UWW_DEMO.CLEAN.UNITED_WAY_FINAL

UNION ALL

SELECT
    'UNMATCHED_AFFILIATES',
    COUNT(*)::VARCHAR
FROM (
    SELECT a.EIN
    FROM UWW_DEMO.STAGING.UNITED_WAY_AFFILIATES a
    LEFT JOIN UWW_DEMO.RAW.IRS_990 i
        ON a.EIN = i.EIN
    WHERE i.EIN IS NULL
)

UNION ALL

SELECT
    'DUPLICATE_FILINGS',
    COUNT(*)::VARCHAR
FROM (
    SELECT EIN
    FROM UWW_DEMO.CLEAN.UNITED_WAY_FINAL
    GROUP BY EIN
    HAVING COUNT(*) > 1
);

SELECT *
FROM UWW_DEMO.CLEAN.VW_DATA_QUALITY_SUMMARY;


-- ============================================================
-- STEP 6: Dashboard-ready analytics view
-- ============================================================

CREATE OR REPLACE VIEW UWW_DEMO.CLEAN.VW_AFFILIATE_FINANCIAL_ANALYTICS AS
SELECT
    SOURCE_STATE,
    EIN,
    NAME,
    CITY,
    STATE,
    NTEE_CD,
    TAX_PD,
    TOTREVENUE,
    TOTFUNCEXPNS,
    TOTASSETSEND,
    TOTLIABEND,
    TOTNETASSETEND,

    TOTREVENUE - TOTFUNCEXPNS AS OPERATING_MARGIN,
    CASE
        WHEN TOTREVENUE = 0 OR TOTREVENUE IS NULL THEN NULL
        ELSE ROUND((TOTFUNCEXPNS / TOTREVENUE) * 100, 2)
    END AS EXPENSE_RATIO_PCT,

    CASE
        WHEN TOTASSETSEND = 0 OR TOTASSETSEND IS NULL THEN NULL
        ELSE ROUND((TOTLIABEND / TOTASSETSEND) * 100, 2)
    END AS LIABILITY_TO_ASSET_RATIO_PCT

FROM UWW_DEMO.CLEAN.UNITED_WAY_FINAL;

SELECT *
FROM UWW_DEMO.CLEAN.VW_AFFILIATE_FINANCIAL_ANALYTICS
LIMIT 20;
