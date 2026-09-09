-- ============================================================
-- PROJECT 2: CREDIT RISK & LOAN PORTFOLIO PERFORMANCE ANALYSIS
-- STEP 4: BUILD analytics.loan_performance
-- SOURCE: analytics.loans_clean
-- ============================================================

SELECT
    loan_status,
    COUNT(*) AS loan_count,
    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS portfolio_pct
FROM analytics.loans_clean
GROUP BY loan_status
ORDER BY loan_count DESC;

SELECT
    loan_status,
    COUNT(*) AS loan_count,
    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS portfolio_pct
FROM analytics.loans_clean
GROUP BY loan_status
ORDER BY loan_count DESC;

DROP TABLE IF EXISTS analytics.loan_performance;

CREATE TABLE analytics.loan_performance AS

WITH base AS (

    SELECT
        l.*,

        BTRIM(l.loan_status) AS status_normalized

    FROM analytics.loans_clean AS l

),

classified AS (

    SELECT
        *,

        -- ====================================================
        -- LOAN PERFORMANCE GROUP
        -- ====================================================

        CASE

            WHEN status_normalized IN (
                'Fully Paid',
                'Does not meet the credit policy. Status:Fully Paid'
            )
                THEN 'Completed Good'

            WHEN status_normalized IN (
                'Charged Off',
                'Default',
                'Does not meet the credit policy. Status:Charged Off'
            )
                THEN 'Bad / Default'

            WHEN status_normalized IN (
                'Late (16-30 days)',
                'Late (31-120 days)',
                'In Grace Period'
            )
                THEN 'Watchlist'

            WHEN status_normalized = 'Current'
                THEN 'Active'

            ELSE 'Other / Review'

        END AS performance_group,

        -- ====================================================
        -- FLAGS
        -- ====================================================

        CASE
            WHEN status_normalized IN (
                'Fully Paid',
                'Does not meet the credit policy. Status:Fully Paid',
                'Charged Off',
                'Default',
                'Does not meet the credit policy. Status:Charged Off'
            )
                THEN 1
            ELSE 0
        END AS resolved_flag,

        CASE
            WHEN status_normalized IN (
                'Fully Paid',
                'Does not meet the credit policy. Status:Fully Paid'
            )
                THEN 1
            ELSE 0
        END AS completed_good_flag,

        CASE
            WHEN status_normalized IN (
                'Charged Off',
                'Default',
                'Does not meet the credit policy. Status:Charged Off'
            )
                THEN 1
            ELSE 0
        END AS bad_loan_flag,

        CASE
            WHEN status_normalized = 'Current'
                THEN 1
            ELSE 0
        END AS active_flag,

        CASE
            WHEN status_normalized IN (
                'Late (16-30 days)',
                'Late (31-120 days)',
                'In Grace Period'
            )
                THEN 1
            ELSE 0
        END AS watchlist_flag,

        -- ====================================================
        -- VINTAGE VARIABLES
        -- ====================================================

        EXTRACT(YEAR FROM issue_date)::INTEGER
            AS issue_year,

        EXTRACT(MONTH FROM issue_date)::INTEGER
            AS issue_month_number,

        TO_CHAR(issue_date, 'YYYY-MM')
            AS issue_year_month,

        -- ====================================================
        -- INCOME BAND
        -- Analyst-defined portfolio segmentation, not an
        -- official Lending Club or regulatory risk category.
        -- ====================================================

        CASE

            WHEN annual_inc IS NULL
                THEN 'Unknown'

            WHEN annual_inc < 40000
                THEN '< $40K'

            WHEN annual_inc < 75000
                THEN '$40K-$74.9K'

            WHEN annual_inc < 100000
                THEN '$75K-$99.9K'

            WHEN annual_inc < 150000
                THEN '$100K-$149.9K'

            ELSE '$150K+'

        END AS income_band,

        -- ====================================================
        -- DTI BAND
        -- ====================================================

        CASE

            WHEN dti IS NULL
                THEN 'Unknown'

            WHEN dti < 10
                THEN '< 10'

            WHEN dti < 20
                THEN '10-19.99'

            WHEN dti < 30
                THEN '20-29.99'

            WHEN dti < 40
                THEN '30-39.99'

            ELSE '40+'

        END AS dti_band,

        -- ====================================================
        -- INTEREST RATE BAND
        -- ====================================================

        CASE

            WHEN int_rate IS NULL
                THEN 'Unknown'

            WHEN int_rate < 10
                THEN '< 10%'

            WHEN int_rate < 15
                THEN '10%-14.99%'

            WHEN int_rate < 20
                THEN '15%-19.99%'

            WHEN int_rate < 25
                THEN '20%-24.99%'

            ELSE '25%+'

        END AS interest_rate_band,

        -- ====================================================
        -- LOAN AMOUNT BAND
        -- ====================================================

        CASE

            WHEN loan_amnt IS NULL
                THEN 'Unknown'

            WHEN loan_amnt < 5000
                THEN '< $5K'

            WHEN loan_amnt < 10000
                THEN '$5K-$9.9K'

            WHEN loan_amnt < 20000
                THEN '$10K-$19.9K'

            WHEN loan_amnt < 30000
                THEN '$20K-$29.9K'

            ELSE '$30K+'

        END AS loan_amount_band,

        -- ====================================================
        -- CREDIT HISTORY BAND
        -- ====================================================

        CASE

            WHEN credit_history_months IS NULL
                THEN 'Unknown'

            WHEN credit_history_months < 60
                THEN '< 5 Years'

            WHEN credit_history_months < 120
                THEN '5-9 Years'

            WHEN credit_history_months < 240
                THEN '10-19 Years'

            ELSE '20+ Years'

        END AS credit_history_band,

        -- ====================================================
        -- PORTFOLIO / EXPOSURE FIELDS
        -- ====================================================

        COALESCE(funded_amnt, 0)
            AS funded_exposure,

        COALESCE(out_prncp, 0)
            AS outstanding_exposure,

        COALESCE(recoveries, 0)
            AS recovery_amount

    FROM base
)

SELECT
    *
FROM classified;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT loan_row_id) AS distinct_loan_row_ids
FROM analytics.loan_performance;

ALTER TABLE analytics.loan_performance
ADD CONSTRAINT pk_loan_performance
PRIMARY KEY (loan_row_id);

SELECT

    (SELECT COUNT(*)
     FROM analytics.loans_clean)
        AS clean_rows,

    (SELECT COUNT(*)
     FROM analytics.loan_performance)
        AS performance_rows,

    (SELECT COUNT(*)
     FROM analytics.loans_clean)

    -

    (SELECT COUNT(*)
     FROM analytics.loan_performance)
        AS difference;

SELECT
    loan_status,
    performance_group,
    resolved_flag,
    bad_loan_flag,
    active_flag,
    watchlist_flag,
    COUNT(*) AS loan_count
FROM analytics.loan_performance
GROUP BY
    loan_status,
    performance_group,
    resolved_flag,
    bad_loan_flag,
    active_flag,
    watchlist_flag
ORDER BY loan_count DESC;

SELECT
    loan_status,
    COUNT(*) AS loan_count
FROM analytics.loan_performance
WHERE performance_group = 'Other / Review'
GROUP BY loan_status
ORDER BY loan_count DESC;

SELECT
    performance_group,
    COUNT(*) AS loan_count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS portfolio_pct,

    ROUND(
        SUM(funded_amnt),
        2
    ) AS funded_amount,

    ROUND(
        SUM(outstanding_exposure),
        2
    ) AS outstanding_amount

FROM analytics.loan_performance

GROUP BY performance_group

ORDER BY loan_count DESC;

SELECT
    performance_group,
    COUNT(*) AS loan_count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS portfolio_pct,

    ROUND(
        SUM(funded_amnt),
        2
    ) AS funded_amount,

    ROUND(
        SUM(outstanding_exposure),
        2
    ) AS outstanding_amount

FROM analytics.loan_performance

GROUP BY performance_group

ORDER BY loan_count DESC;

DROP VIEW IF EXISTS analytics.resolved_loans;

CREATE VIEW analytics.resolved_loans AS

SELECT *
FROM analytics.loan_performance
WHERE resolved_flag = 1;

SELECT
    performance_group,
    COUNT(*) AS loans
FROM analytics.resolved_loans
GROUP BY performance_group
ORDER BY loans DESC;

SELECT

    COUNT(*) AS resolved_loans,

    SUM(completed_good_flag)
        AS completed_good_loans,

    SUM(bad_loan_flag)
        AS bad_loans,

    ROUND(
        100.0 * SUM(bad_loan_flag)
        / NULLIF(COUNT(*), 0),
        2
    ) AS resolved_bad_loan_rate_pct

FROM analytics.resolved_loans;

SELECT

    COUNT(*) AS total_loans,

    SUM(bad_loan_flag) AS bad_loans,

    SUM(active_flag) AS active_loans,

    SUM(watchlist_flag) AS watchlist_loans,

    ROUND(
        100.0 * SUM(bad_loan_flag)
        / COUNT(*),
        2
    ) AS bad_loans_pct_of_all,

    ROUND(
        100.0 * SUM(active_flag)
        / COUNT(*),
        2
    ) AS active_loans_pct,

    ROUND(
        100.0 * SUM(watchlist_flag)
        / COUNT(*),
        2
    ) AS watchlist_pct

FROM analytics.loan_performance;

SELECT

    ROUND(
        SUM(funded_amnt),
        2
    ) AS total_funded_amount,

    ROUND(
        SUM(funded_amnt)
        FILTER (
            WHERE bad_loan_flag = 1
        ),
        2
    ) AS bad_loan_funded_amount,

    ROUND(
        100.0 *
        SUM(funded_amnt)
        FILTER (
            WHERE bad_loan_flag = 1
        )
        /
        NULLIF(SUM(funded_amnt), 0),
        2
    ) AS bad_loan_funded_pct

FROM analytics.loan_performance;

SELECT

    ROUND(
        SUM(outstanding_exposure),
        2
    ) AS total_outstanding_exposure,

    ROUND(
        SUM(outstanding_exposure)
        FILTER (
            WHERE performance_group = 'Active'
        ),
        2
    ) AS active_outstanding_exposure,

    ROUND(
        SUM(outstanding_exposure)
        FILTER (
            WHERE performance_group = 'Watchlist'
        ),
        2
    ) AS watchlist_outstanding_exposure

FROM analytics.loan_performance;

SELECT

    COUNT(*) AS bad_loans,

    ROUND(
        SUM(funded_amnt),
        2
    ) AS bad_loan_funded_amount,

    ROUND(
        SUM(recoveries),
        2
    ) AS total_recoveries,

    ROUND(
        SUM(collection_recovery_fee),
        2
    ) AS collection_recovery_fees,

    ROUND(
        100.0 * SUM(recoveries)
        / NULLIF(SUM(funded_amnt), 0),
        2
    ) AS recoveries_as_pct_of_funded

FROM analytics.loan_performance

WHERE bad_loan_flag = 1;

SELECT

    grade,

    COUNT(*) AS resolved_loans,

    SUM(bad_loan_flag)
        AS bad_loans,

    ROUND(
        100.0 * SUM(bad_loan_flag)
        / NULLIF(COUNT(*), 0),
        2
    ) AS bad_loan_rate_pct,

    ROUND(
        SUM(funded_amnt),
        2
    ) AS funded_amount,

    ROUND(
        AVG(int_rate),
        2
    ) AS avg_interest_rate

FROM analytics.resolved_loans

GROUP BY grade

ORDER BY grade;

SELECT

    term_months,

    COUNT(*) AS resolved_loans,

    SUM(bad_loan_flag)
        AS bad_loans,

    ROUND(
        100.0 * SUM(bad_loan_flag)
        / NULLIF(COUNT(*), 0),
        2
    ) AS bad_loan_rate_pct,

    ROUND(
        AVG(int_rate),
        2
    ) AS avg_interest_rate,

    ROUND(
        AVG(loan_amnt),
        2
    ) AS avg_loan_amount

FROM analytics.resolved_loans

GROUP BY term_months

ORDER BY term_months;

SELECT

    dti_band,

    COUNT(*) AS resolved_loans,

    SUM(bad_loan_flag)
        AS bad_loans,

    ROUND(
        100.0 * SUM(bad_loan_flag)
        / NULLIF(COUNT(*), 0),
        2
    ) AS bad_loan_rate_pct,

    ROUND(
        AVG(dti),
        2
    ) AS avg_dti

FROM analytics.resolved_loans

GROUP BY dti_band

ORDER BY
    CASE dti_band

        WHEN '< 10' THEN 1
        WHEN '10-19.99' THEN 2
        WHEN '20-29.99' THEN 3
        WHEN '30-39.99' THEN 4
        WHEN '40+' THEN 5

        ELSE 6

    END;

SELECT

    income_band,

    COUNT(*) AS resolved_loans,

    SUM(bad_loan_flag)
        AS bad_loans,

    ROUND(
        100.0 * SUM(bad_loan_flag)
        / NULLIF(COUNT(*), 0),
        2
    ) AS bad_loan_rate_pct,

    ROUND(
        AVG(annual_inc),
        2
    ) AS avg_income

FROM analytics.resolved_loans

GROUP BY income_band

ORDER BY
    CASE income_band

        WHEN '< $40K' THEN 1
        WHEN '$40K-$74.9K' THEN 2
        WHEN '$75K-$99.9K' THEN 3
        WHEN '$100K-$149.9K' THEN 4
        WHEN '$150K+' THEN 5

        ELSE 6

    END;

SELECT

    purpose,

    COUNT(*) AS resolved_loans,

    SUM(bad_loan_flag)
        AS bad_loans,

    ROUND(
        100.0 * SUM(bad_loan_flag)
        / NULLIF(COUNT(*), 0),
        2
    ) AS bad_loan_rate_pct,

    ROUND(
        SUM(funded_amnt),
        2
    ) AS funded_amount

FROM analytics.resolved_loans

GROUP BY purpose

HAVING COUNT(*) >= 100

ORDER BY bad_loan_rate_pct DESC;

SELECT

    interest_rate_band,

    COUNT(*) AS resolved_loans,

    SUM(bad_loan_flag) AS bad_loans,

    ROUND(
        100.0 * SUM(bad_loan_flag)
        / NULLIF(COUNT(*), 0),
        2
    ) AS bad_loan_rate_pct,

    ROUND(
        AVG(int_rate),
        2
    ) AS avg_interest_rate

FROM analytics.resolved_loans

GROUP BY interest_rate_band

ORDER BY
    CASE interest_rate_band

        WHEN '< 10%' THEN 1
        WHEN '10%-14.99%' THEN 2
        WHEN '15%-19.99%' THEN 3
        WHEN '20%-24.99%' THEN 4
        WHEN '25%+' THEN 5

        ELSE 6

    END;

SELECT

    issue_year,

    COUNT(*) AS resolved_loans,

    SUM(bad_loan_flag)
        AS bad_loans,

    ROUND(
        100.0 * SUM(bad_loan_flag)
        / NULLIF(COUNT(*), 0),
        2
    ) AS bad_loan_rate_pct,

    ROUND(
        SUM(funded_amnt),
        2
    ) AS funded_amount

FROM analytics.resolved_loans

GROUP BY issue_year

ORDER BY issue_year;

CREATE INDEX idx_loan_perf_group
ON analytics.loan_performance(performance_group);

CREATE INDEX idx_loan_perf_resolved
ON analytics.loan_performance(resolved_flag);

CREATE INDEX idx_loan_perf_bad
ON analytics.loan_performance(bad_loan_flag);

CREATE INDEX idx_loan_perf_grade
ON analytics.loan_performance(grade);

CREATE INDEX idx_loan_perf_term
ON analytics.loan_performance(term_months);

CREATE INDEX idx_loan_perf_issue_year
ON analytics.loan_performance(issue_year);

CREATE INDEX idx_loan_perf_dti_band
ON analytics.loan_performance(dti_band);

CREATE INDEX idx_loan_perf_income_band
ON analytics.loan_performance(income_band);

CREATE INDEX idx_loan_perf_purpose
ON analytics.loan_performance(purpose);

SELECT

    (SELECT COUNT(*)
     FROM analytics.loans_clean)
        AS clean_records,

    (SELECT COUNT(*)
     FROM analytics.loan_performance)
        AS performance_records,

    (SELECT COUNT(*)
     FROM analytics.resolved_loans)
        AS resolved_records,

    (SELECT SUM(completed_good_flag)
     FROM analytics.loan_performance)
        AS completed_good_loans,

    (SELECT SUM(bad_loan_flag)
     FROM analytics.loan_performance)
        AS bad_loans,

    (SELECT SUM(active_flag)
     FROM analytics.loan_performance)
        AS active_loans,

    (SELECT SUM(watchlist_flag)
     FROM analytics.loan_performance)
        AS watchlist_loans,

    (SELECT COUNT(*)
     FROM analytics.loan_performance
     WHERE performance_group = 'Other / Review')
        AS unclassified_loans;

SELECT
    COUNT(*) AS invalid_rows
FROM analytics.loan_performance
WHERE
    completed_good_flag
    + bad_loan_flag
    + active_flag
    + watchlist_flag
    >
    1;

SELECT
    COUNT(*) AS inconsistent_resolved_flags
FROM analytics.loan_performance
WHERE
    resolved_flag
    <>
    CASE
        WHEN completed_good_flag = 1
          OR bad_loan_flag = 1
        THEN 1
        ELSE 0
    END;

SELECT

    COUNT(*) AS total_loans,

    ROUND(
        SUM(funded_amnt),
        2
    ) AS total_funded_amount,

    ROUND(
        SUM(outstanding_exposure),
        2
    ) AS outstanding_exposure,

    SUM(completed_good_flag)
        AS completed_good_loans,

    SUM(bad_loan_flag)
        AS bad_loans,

    SUM(active_flag)
        AS active_loans,

    SUM(watchlist_flag)
        AS watchlist_loans,

    ROUND(
        100.0 *
        SUM(bad_loan_flag)
        FILTER (WHERE resolved_flag = 1)
        /
        NULLIF(
            COUNT(*)
            FILTER (WHERE resolved_flag = 1),
            0
        ),
        2
    ) AS resolved_bad_loan_rate_pct,

    ROUND(
        SUM(funded_amnt)
        FILTER (WHERE bad_loan_flag = 1),
        2
    ) AS bad_loan_funded_amount,

    ROUND(
        SUM(outstanding_exposure)
        FILTER (WHERE watchlist_flag = 1),
        2
    ) AS watchlist_outstanding_exposure

FROM analytics.loan_performance;