DROP TABLE IF EXISTS analytics.powerbi_loan_fact;

CREATE TABLE analytics.powerbi_loan_fact AS

SELECT

    -- =====================================================
    -- KEY
    -- =====================================================

    loan_row_id,

    -- =====================================================
    -- LOAN CHARACTERISTICS
    -- =====================================================

    loan_amnt,
    funded_amnt,
    term_months,
    int_rate,
    installment,

    grade,
    sub_grade,

    purpose,

    -- =====================================================
    -- BORROWER PROFILE
    -- =====================================================

    employment_years,
    home_ownership,
    annual_inc,
    verification_status,
    application_type,

    -- =====================================================
    -- DATE / VINTAGE
    -- =====================================================

    issue_date,
    issue_year,
    issue_month_number,
    issue_year_month,

    -- =====================================================
    -- GEOGRAPHY
    -- =====================================================

    addr_state,

    -- =====================================================
    -- CREDIT RISK VARIABLES
    -- =====================================================

    dti,
    delinq_2yrs,
    inq_last_6mths,

    revol_bal,
    revol_util,

    total_acc,
    acc_now_delinq,

    mort_acc,

    num_accts_ever_120_pd,
    num_tl_90g_dpd_24m,

    pub_rec_bankruptcies,
    tax_liens,

    credit_history_months,

    -- =====================================================
    -- PERFORMANCE
    -- =====================================================

    loan_status,
    performance_group,

    resolved_flag,
    completed_good_flag,
    bad_loan_flag,
    active_flag,
    watchlist_flag,

    -- =====================================================
    -- ANALYTICAL BANDS
    -- =====================================================

    income_band,
    dti_band,
    interest_rate_band,
    loan_amount_band,
    credit_history_band,
    revol_util_band,

    -- =====================================================
    -- EXPOSURE / PERFORMANCE VALUE
    -- =====================================================

    funded_exposure,
    outstanding_exposure,

    total_pymnt,
    total_rec_prncp,
    total_rec_int,
    total_rec_late_fee,

    recovery_amount,

    -- =====================================================
    -- DISTRESS INDICATORS
    -- =====================================================

    hardship_flag,
    debt_settlement_flag,
    disbursement_method

FROM analytics.loan_performance;

SELECT

    (SELECT COUNT(*)
     FROM analytics.loan_performance)
        AS performance_rows,

    (SELECT COUNT(*)
     FROM analytics.powerbi_loan_fact)
        AS powerbi_rows;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT loan_row_id) AS unique_loan_ids
FROM analytics.powerbi_loan_fact;

ALTER TABLE analytics.powerbi_loan_fact
ADD COLUMN performance_group_sort INTEGER;

UPDATE analytics.powerbi_loan_fact

SET performance_group_sort =
    CASE performance_group
        WHEN 'Completed Good' THEN 1
        WHEN 'Active' THEN 2
        WHEN 'Watchlist' THEN 3
        WHEN 'Bad / Default' THEN 4
        WHEN 'Other / Review' THEN 5
        ELSE 6
    END;

ALTER TABLE analytics.powerbi_loan_fact
ADD COLUMN dti_band_sort INTEGER;

UPDATE analytics.powerbi_loan_fact

SET dti_band_sort =
    CASE dti_band
        WHEN '< 10' THEN 1
        WHEN '10-19.99' THEN 2
        WHEN '20-29.99' THEN 3
        WHEN '30-39.99' THEN 4
        WHEN '40+' THEN 5
        WHEN 'Unknown' THEN 6
        ELSE 7
    END;

ALTER TABLE analytics.powerbi_loan_fact
ADD COLUMN income_band_sort INTEGER;

UPDATE analytics.powerbi_loan_fact

SET income_band_sort =
    CASE income_band
        WHEN '< $40K' THEN 1
        WHEN '$40K-$74.9K' THEN 2
        WHEN '$75K-$99.9K' THEN 3
        WHEN '$100K-$149.9K' THEN 4
        WHEN '$150K+' THEN 5
        WHEN 'Unknown' THEN 6
        ELSE 7
    END;

ALTER TABLE analytics.powerbi_loan_fact
ADD COLUMN interest_rate_band_sort INTEGER;

UPDATE analytics.powerbi_loan_fact

SET interest_rate_band_sort =
    CASE interest_rate_band
        WHEN '< 10%' THEN 1
        WHEN '10%-14.99%' THEN 2
        WHEN '15%-19.99%' THEN 3
        WHEN '20%-24.99%' THEN 4
        WHEN '25%+' THEN 5
        WHEN 'Unknown' THEN 6
        ELSE 7
    END;

ALTER TABLE analytics.powerbi_loan_fact
ADD COLUMN revol_util_band_sort INTEGER;

UPDATE analytics.powerbi_loan_fact

SET revol_util_band_sort =
    CASE revol_util_band
        WHEN '< 30%' THEN 1
        WHEN '30%-49.99%' THEN 2
        WHEN '50%-69.99%' THEN 3
        WHEN '70%-89.99%' THEN 4
        WHEN '90%+' THEN 5
        WHEN 'Unknown' THEN 6
        ELSE 7
    END;

ALTER TABLE analytics.powerbi_loan_fact
ADD COLUMN loan_amount_band_sort INTEGER;

UPDATE analytics.powerbi_loan_fact

SET loan_amount_band_sort =
    CASE loan_amount_band
        WHEN '< $5K' THEN 1
        WHEN '$5K-$9.9K' THEN 2
        WHEN '$10K-$19.9K' THEN 3
        WHEN '$20K-$29.9K' THEN 4
        WHEN '$30K+' THEN 5
        WHEN 'Unknown' THEN 6
        ELSE 7
    END;

ALTER TABLE analytics.powerbi_loan_fact
ADD COLUMN credit_history_band_sort INTEGER;

UPDATE analytics.powerbi_loan_fact

SET credit_history_band_sort =
    CASE credit_history_band
        WHEN '< 5 Years' THEN 1
        WHEN '5-9 Years' THEN 2
        WHEN '10-19 Years' THEN 3
        WHEN '20+ Years' THEN 4
        WHEN 'Unknown' THEN 5
        ELSE 6
    END;

SELECT
    COUNT(*) AS rows,
    COUNT(*) FILTER (
        WHERE issue_date IS NULL
    ) AS missing_issue_date,

    COUNT(*) FILTER (
        WHERE performance_group IS NULL
    ) AS missing_performance_group,

    COUNT(*) FILTER (
        WHERE grade IS NULL
    ) AS missing_grade,

    COUNT(*) FILTER (
        WHERE funded_amnt IS NULL
    ) AS missing_funded_amount

FROM analytics.powerbi_loan_fact;

SELECT

    COUNT(*) AS loans,

    SUM(resolved_flag) AS resolved_loans,

    SUM(bad_loan_flag) AS bad_loans,

    SUM(active_flag) AS active_loans,

    SUM(watchlist_flag) AS watchlist_loans,

    ROUND(
        SUM(funded_amnt),
        2
    ) AS funded_amount,

    ROUND(
        SUM(outstanding_exposure),
        2
    ) AS outstanding_exposure

FROM analytics.powerbi_loan_fact;