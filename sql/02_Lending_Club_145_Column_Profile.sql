-- ============================================================
-- PROJECT 2: CREDIT RISK & LOAN PORTFOLIO PERFORMANCE ANALYSIS
-- STEP 2B: FULL 145-COLUMN DATA PROFILING
-- SOURCE: LENDING CLUB ACCEPTED LOANS
-- RAW TABLE: staging.lending_club_raw
-- ============================================================

SELECT
    (SELECT COUNT(*)
     FROM staging.lending_club_raw) AS raw_rows,

    (SELECT COUNT(*)
     FROM information_schema.columns
     WHERE table_schema = 'staging'
       AND table_name = 'lending_club_raw') AS raw_columns;

ANALYZE staging.lending_club_raw;

SELECT
    relname,
    n_live_tup
FROM pg_stat_user_tables
WHERE schemaname = 'staging'
  AND relname = 'lending_club_raw';

SELECT
    COUNT(*) AS total_rows,

    COUNT(id) AS non_null_ids,

    COUNT(*) FILTER (
        WHERE id IS NULL
           OR BTRIM(id) = ''
    ) AS missing_ids,

    COUNT(
        DISTINCT NULLIF(BTRIM(id), '')
    ) AS distinct_nonblank_ids

FROM staging.lending_club_raw;

SELECT
    id,
    COUNT(*) AS occurrences
FROM staging.lending_club_raw
WHERE NULLIF(BTRIM(id), '') IS NOT NULL
GROUP BY id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, id
LIMIT 50;

DROP TABLE IF EXISTS staging.lending_club_column_profile;

CREATE TABLE staging.lending_club_column_profile AS
SELECT
    c.ordinal_position AS column_position,
    c.column_name,
    c.data_type,

    2260668::BIGINT AS total_rows,

    ROUND(
        COALESCE(s.null_frac, 0)::NUMERIC * 100,
        2
    ) AS approx_null_pct,

    CASE
        WHEN s.n_distinct IS NULL THEN NULL

        WHEN s.n_distinct >= 0
            THEN ROUND(s.n_distinct)::BIGINT

        ELSE
            ROUND(
                ABS(s.n_distinct) * 2260668
            )::BIGINT
    END AS approx_distinct_count,

    s.avg_width,

    s.most_common_vals::TEXT AS common_values

FROM information_schema.columns AS c

LEFT JOIN pg_stats AS s
    ON s.schemaname = c.table_schema
   AND s.tablename = c.table_name
   AND s.attname = c.column_name

WHERE c.table_schema = 'staging'
  AND c.table_name = 'lending_club_raw'

ORDER BY c.ordinal_position;

SELECT COUNT(*) AS profiled_columns
FROM staging.lending_club_column_profile;

SELECT *
FROM staging.lending_club_column_profile
ORDER BY column_position;

SELECT
    column_position,
    column_name,
    approx_null_pct,
    approx_distinct_count
FROM staging.lending_club_column_profile
ORDER BY approx_null_pct DESC,
         column_position;

SELECT
    CASE
        WHEN approx_null_pct = 0
            THEN '0% Missing'

        WHEN approx_null_pct <= 10
            THEN '>0–10% Missing'

        WHEN approx_null_pct <= 25
            THEN '>10–25% Missing'

        WHEN approx_null_pct <= 50
            THEN '>25–50% Missing'

        WHEN approx_null_pct <= 75
            THEN '>50–75% Missing'

        ELSE '>75% Missing'
    END AS missingness_band,

    COUNT(*) AS number_of_columns

FROM staging.lending_club_column_profile

GROUP BY 1

ORDER BY
    MIN(approx_null_pct);

SELECT
    column_position,
    column_name,
    approx_null_pct,
    approx_distinct_count
FROM staging.lending_club_column_profile
WHERE approx_null_pct > 75
ORDER BY approx_null_pct DESC;

SELECT
    COALESCE(NULLIF(BTRIM(loan_status), ''), '[Missing]')
        AS loan_status,

    COUNT(*) AS loan_count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS portfolio_pct

FROM staging.lending_club_raw

GROUP BY
    COALESCE(NULLIF(BTRIM(loan_status), ''), '[Missing]')

ORDER BY loan_count DESC;

SELECT
    grade,
    COUNT(*) AS loan_count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS portfolio_pct

FROM staging.lending_club_raw

GROUP BY grade

ORDER BY grade;

SELECT
    grade,
    sub_grade,
    COUNT(*) AS loan_count
FROM staging.lending_club_raw
GROUP BY grade, sub_grade
ORDER BY grade, sub_grade;

SELECT
    '[' || term || ']' AS raw_term,
    LENGTH(term) AS text_length,
    COUNT(*) AS loan_count
FROM staging.lending_club_raw
GROUP BY term
ORDER BY loan_count DESC;

SELECT DISTINCT int_rate
FROM staging.lending_club_raw
WHERE NULLIF(BTRIM(int_rate), '') IS NOT NULL
LIMIT 50;

SELECT
    COUNT(*) AS populated_rates,

    COUNT(*) FILTER (
        WHERE int_rate LIKE '%\%%' ESCAPE '\'
    ) AS values_with_percent_symbol

FROM staging.lending_club_raw

WHERE NULLIF(BTRIM(int_rate), '') IS NOT NULL;

SELECT
    COUNT(*) AS populated_values,

    COUNT(*) FILTER (
        WHERE BTRIM(int_rate)
              ~ '^-?[0-9]+(\.[0-9]+)?$'
    ) AS valid_numeric_values,

    COUNT(*) FILTER (
        WHERE BTRIM(int_rate)
              !~ '^-?[0-9]+(\.[0-9]+)?$'
    ) AS invalid_numeric_values

FROM staging.lending_club_raw

WHERE NULLIF(BTRIM(int_rate), '') IS NOT NULL;

SELECT
    MIN(
        CASE
            WHEN BTRIM(int_rate)
                 ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN BTRIM(int_rate)::NUMERIC
        END
    ) AS min_interest_rate,

    MAX(
        CASE
            WHEN BTRIM(int_rate)
                 ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN BTRIM(int_rate)::NUMERIC
        END
    ) AS max_interest_rate,

    ROUND(
        AVG(
            CASE
                WHEN BTRIM(int_rate)
                     ~ '^-?[0-9]+(\.[0-9]+)?$'
                THEN BTRIM(int_rate)::NUMERIC
            END
        ),
        2
    ) AS avg_interest_rate

FROM staging.lending_club_raw;

SELECT DISTINCT issue_d
FROM staging.lending_club_raw
WHERE NULLIF(BTRIM(issue_d), '') IS NOT NULL
ORDER BY issue_d
LIMIT 50;

SELECT
    COUNT(*) AS populated_issue_dates,

    COUNT(*) FILTER (
        WHERE BTRIM(issue_d)
              ~ '^[A-Za-z]{3}-[0-9]{4}$'
    ) AS expected_format,

    COUNT(*) FILTER (
        WHERE BTRIM(issue_d)
              !~ '^[A-Za-z]{3}-[0-9]{4}$'
    ) AS unexpected_format

FROM staging.lending_club_raw

WHERE NULLIF(BTRIM(issue_d), '') IS NOT NULL;

SELECT
    MIN(
        TO_DATE(BTRIM(issue_d), 'Mon-YYYY')
    ) AS first_issue_month,

    MAX(
        TO_DATE(BTRIM(issue_d), 'Mon-YYYY')
    ) AS last_issue_month

FROM staging.lending_club_raw

WHERE BTRIM(issue_d)
      ~ '^[A-Za-z]{3}-[0-9]{4}$';

SELECT
    COALESCE(
        NULLIF(BTRIM(emp_length), ''),
        '[Missing]'
    ) AS employment_length,

    COUNT(*) AS loan_count

FROM staging.lending_club_raw

GROUP BY
    COALESCE(
        NULLIF(BTRIM(emp_length), ''),
        '[Missing]'
    )

ORDER BY loan_count DESC;

SELECT
    purpose,
    COUNT(*) AS loan_count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS portfolio_pct

FROM staging.lending_club_raw

GROUP BY purpose

ORDER BY loan_count DESC;

SELECT
    home_ownership,
    COUNT(*) AS loan_count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS portfolio_pct

FROM staging.lending_club_raw

GROUP BY home_ownership

ORDER BY loan_count DESC;

SELECT
    verification_status,
    COUNT(*) AS loan_count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS portfolio_pct

FROM staging.lending_club_raw

GROUP BY verification_status

ORDER BY loan_count DESC;

SELECT
    application_type,
    COUNT(*) AS loan_count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS portfolio_pct

FROM staging.lending_club_raw

GROUP BY application_type

ORDER BY loan_count DESC;

SELECT
    loan_amnt,
    funded_amnt,
    installment,
    annual_inc,
    dti,
    revol_bal,
    revol_util,
    out_prncp,
    total_pymnt
FROM staging.lending_club_raw
LIMIT 30;

SELECT
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(loan_amnt), '') IS NOT NULL
          AND BTRIM(loan_amnt)
              !~ '^-?[0-9]+(\.[0-9]+)?$'
    ) AS invalid_loan_amnt,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(funded_amnt), '') IS NOT NULL
          AND BTRIM(funded_amnt)
              !~ '^-?[0-9]+(\.[0-9]+)?$'
    ) AS invalid_funded_amnt,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(annual_inc), '') IS NOT NULL
          AND BTRIM(annual_inc)
              !~ '^-?[0-9]+(\.[0-9]+)?$'
    ) AS invalid_annual_inc,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(dti), '') IS NOT NULL
          AND BTRIM(dti)
              !~ '^-?[0-9]+(\.[0-9]+)?$'
    ) AS invalid_dti

FROM staging.lending_club_raw;

SELECT
    MIN(
        CASE WHEN BTRIM(loan_amnt)
             ~ '^-?[0-9]+(\.[0-9]+)?$'
             THEN loan_amnt::NUMERIC END
    ) AS min_loan_amount,

    MAX(
        CASE WHEN BTRIM(loan_amnt)
             ~ '^-?[0-9]+(\.[0-9]+)?$'
             THEN loan_amnt::NUMERIC END
    ) AS max_loan_amount,

    ROUND(
        AVG(
            CASE WHEN BTRIM(loan_amnt)
                 ~ '^-?[0-9]+(\.[0-9]+)?$'
                 THEN loan_amnt::NUMERIC END
        ),
        2
    ) AS avg_loan_amount,

    MIN(
        CASE WHEN BTRIM(annual_inc)
             ~ '^-?[0-9]+(\.[0-9]+)?$'
             THEN annual_inc::NUMERIC END
    ) AS min_income,

    MAX(
        CASE WHEN BTRIM(annual_inc)
             ~ '^-?[0-9]+(\.[0-9]+)?$'
             THEN annual_inc::NUMERIC END
    ) AS max_income,

    ROUND(
        AVG(
            CASE WHEN BTRIM(annual_inc)
                 ~ '^-?[0-9]+(\.[0-9]+)?$'
                 THEN annual_inc::NUMERIC END
        ),
        2
    ) AS avg_income,

    MIN(
        CASE WHEN BTRIM(dti)
             ~ '^-?[0-9]+(\.[0-9]+)?$'
             THEN dti::NUMERIC END
    ) AS min_dti,

    MAX(
        CASE WHEN BTRIM(dti)
             ~ '^-?[0-9]+(\.[0-9]+)?$'
             THEN dti::NUMERIC END
    ) AS max_dti,

    ROUND(
        AVG(
            CASE WHEN BTRIM(dti)
                 ~ '^-?[0-9]+(\.[0-9]+)?$'
                 THEN dti::NUMERIC END
        ),
        2
    ) AS avg_dti

FROM staging.lending_club_raw;

SELECT
    MIN(delinq_2yrs::NUMERIC) AS min_delinq_2yrs,
    MAX(delinq_2yrs::NUMERIC) AS max_delinq_2yrs,

    MIN(inq_last_6mths::NUMERIC) AS min_inquiries,
    MAX(inq_last_6mths::NUMERIC) AS max_inquiries,

    MIN(open_acc::NUMERIC) AS min_open_accounts,
    MAX(open_acc::NUMERIC) AS max_open_accounts,

    MIN(pub_rec::NUMERIC) AS min_public_records,
    MAX(pub_rec::NUMERIC) AS max_public_records,

    MIN(total_acc::NUMERIC) AS min_total_accounts,
    MAX(total_acc::NUMERIC) AS max_total_accounts

FROM staging.lending_club_raw

WHERE NULLIF(BTRIM(delinq_2yrs), '') IS NOT NULL
  AND NULLIF(BTRIM(inq_last_6mths), '') IS NOT NULL
  AND NULLIF(BTRIM(open_acc), '') IS NOT NULL
  AND NULLIF(BTRIM(pub_rec), '') IS NOT NULL
  AND NULLIF(BTRIM(total_acc), '') IS NOT NULL;

 SELECT
    addr_state,
    COUNT(*) AS loan_count
FROM staging.lending_club_raw
GROUP BY addr_state
ORDER BY loan_count DESC;

SELECT
    addr_state,
    COUNT(*) AS loan_count
FROM staging.lending_club_raw
WHERE NULLIF(BTRIM(addr_state), '') IS NOT NULL
  AND LENGTH(BTRIM(addr_state)) <> 2
GROUP BY addr_state
ORDER BY loan_count DESC;

SELECT
    COUNT(*) AS total_loans,

    COUNT(annual_inc_joint) AS annual_inc_joint_populated,

    COUNT(dti_joint) AS dti_joint_populated,

    COUNT(sec_app_earliest_cr_line)
        AS secondary_credit_history_populated,

    COUNT(revol_bal_joint)
        AS joint_revolving_balance_populated

FROM staging.lending_club_raw;

SELECT
    ROUND(
        100.0 * COUNT(annual_inc_joint) / COUNT(*),
        2
    ) AS annual_inc_joint_pct,

    ROUND(
        100.0 * COUNT(dti_joint) / COUNT(*),
        2
    ) AS dti_joint_pct,

    ROUND(
        100.0 * COUNT(sec_app_earliest_cr_line) / COUNT(*),
        2
    ) AS secondary_applicant_pct

FROM staging.lending_club_raw;

SELECT
    COALESCE(
        NULLIF(BTRIM(hardship_flag), ''),
        '[Missing]'
    ) AS hardship_flag,

    COUNT(*) AS loan_count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS portfolio_pct

FROM staging.lending_club_raw

GROUP BY
    COALESCE(
        NULLIF(BTRIM(hardship_flag), ''),
        '[Missing]'
    )

ORDER BY loan_count DESC;

SELECT
    hardship_reason,
    COUNT(*) AS loan_count
FROM staging.lending_club_raw
WHERE NULLIF(BTRIM(hardship_reason), '') IS NOT NULL
GROUP BY hardship_reason
ORDER BY loan_count DESC;

SELECT
    COALESCE(
        NULLIF(BTRIM(debt_settlement_flag), ''),
        '[Missing]'
    ) AS debt_settlement_flag,

    COUNT(*) AS loan_count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS portfolio_pct

FROM staging.lending_club_raw

GROUP BY
    COALESCE(
        NULLIF(BTRIM(debt_settlement_flag), ''),
        '[Missing]'
    )

ORDER BY loan_count DESC;

SELECT
    settlement_status,
    COUNT(*) AS loan_count
FROM staging.lending_club_raw
WHERE NULLIF(BTRIM(settlement_status), '') IS NOT NULL
GROUP BY settlement_status
ORDER BY loan_count DESC;

SELECT
    column_position,
    column_name,
    approx_null_pct,
    approx_distinct_count,
    common_values

FROM staging.lending_club_column_profile

WHERE column_name IN (

    'id',
    'loan_amnt',
    'funded_amnt',
    'term',
    'int_rate',
    'installment',
    'grade',
    'sub_grade',
    'emp_length',
    'home_ownership',
    'annual_inc',
    'verification_status',
    'issue_d',
    'loan_status',
    'purpose',
    'addr_state',

    'dti',
    'delinq_2yrs',
    'earliest_cr_line',
    'inq_last_6mths',
    'mths_since_last_delinq',
    'open_acc',
    'pub_rec',
    'revol_bal',
    'revol_util',
    'total_acc',
    'application_type',

    'acc_now_delinq',
    'tot_coll_amt',
    'tot_cur_bal',
    'acc_open_past_24mths',
    'avg_cur_bal',
    'bc_open_to_buy',
    'bc_util',
    'chargeoff_within_12_mths',
    'delinq_amnt',
    'mort_acc',
    'mths_since_recent_inq',
    'num_accts_ever_120_pd',
    'num_tl_90g_dpd_24m',
    'pct_tl_nvr_dlq',
    'percent_bc_gt_75',
    'pub_rec_bankruptcies',
    'tax_liens',
    'tot_hi_cred_lim',
    'total_bal_ex_mort',
    'total_bc_limit',

    'out_prncp',
    'total_pymnt',
    'total_rec_prncp',
    'total_rec_int',
    'total_rec_late_fee',
    'recoveries',
    'collection_recovery_fee',
    'last_pymnt_d',
    'last_pymnt_amnt',

    'hardship_flag',
    'debt_settlement_flag',
    'disbursement_method'
)

ORDER BY column_position;

SELECT

    (SELECT COUNT(*)
     FROM staging.lending_club_raw)
        AS total_raw_rows,

    (SELECT COUNT(*)
     FROM information_schema.columns
     WHERE table_schema = 'staging'
       AND table_name = 'lending_club_raw')
        AS total_raw_columns,

    (SELECT COUNT(DISTINCT NULLIF(BTRIM(id), ''))
     FROM staging.lending_club_raw)
        AS distinct_loan_ids,

    (SELECT COUNT(DISTINCT loan_status)
     FROM staging.lending_club_raw)
        AS loan_status_categories,

    (SELECT COUNT(DISTINCT grade)
     FROM staging.lending_club_raw)
        AS grade_categories,

    (SELECT COUNT(DISTINCT purpose)
     FROM staging.lending_club_raw)
        AS purpose_categories,

    (SELECT COUNT(DISTINCT addr_state)
     FROM staging.lending_club_raw)
        AS state_categories,

    (SELECT COUNT(*)
     FROM staging.lending_club_column_profile
     WHERE approx_null_pct > 75)
        AS highly_sparse_columns;