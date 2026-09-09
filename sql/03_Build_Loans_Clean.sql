-- ============================================================
-- PROJECT 2: CREDIT RISK & LOAN PORTFOLIO PERFORMANCE ANALYSIS
-- STEP 3: BUILD analytics.loans_clean
-- RAW SOURCE: staging.lending_club_raw
-- ============================================================


SELECT
    COUNT(*) AS total_raw_rows,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(loan_amnt), '') IS NULL
    ) AS missing_loan_amount,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(issue_d), '') IS NULL
    ) AS missing_issue_date,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(loan_status), '') IS NULL
    ) AS missing_loan_status

FROM staging.lending_club_raw;

SELECT
    COUNT(*) AS invalid_loan_amount_values
FROM staging.lending_club_raw
WHERE NULLIF(BTRIM(loan_amnt), '') IS NOT NULL
  AND BTRIM(loan_amnt)
      !~ '^[0-9]+(\.[0-9]+)?$';

SELECT
    COUNT(*) AS invalid_issue_date_values
FROM staging.lending_club_raw
WHERE NULLIF(BTRIM(issue_d), '') IS NOT NULL
  AND BTRIM(issue_d)
      !~ '^[A-Za-z]{3}-[0-9]{4}$';

SELECT
    BTRIM(term) AS term,
    COUNT(*) AS loan_count
FROM staging.lending_club_raw
GROUP BY BTRIM(term)
ORDER BY loan_count DESC;

DROP TABLE IF EXISTS analytics.loans_clean;

CREATE TABLE analytics.loans_clean (

    -- Surrogate identifier
    loan_row_id BIGSERIAL PRIMARY KEY,

    -- Source identifier
    source_id TEXT,

    -- =====================================================
    -- Loan characteristics
    -- =====================================================

    loan_amnt NUMERIC(12,2),
    funded_amnt NUMERIC(12,2),
    funded_amnt_inv NUMERIC(12,2),

    term_months SMALLINT,

    int_rate NUMERIC(6,3),
    installment NUMERIC(12,2),

    grade VARCHAR(5),
    sub_grade VARCHAR(5),

    -- =====================================================
    -- Borrower characteristics
    -- =====================================================

    emp_length_raw VARCHAR(30),
    employment_years SMALLINT,

    home_ownership VARCHAR(30),

    annual_inc NUMERIC(18,2),

    verification_status VARCHAR(30),

    application_type VARCHAR(30),

    annual_inc_joint NUMERIC(18,2),
    dti_joint NUMERIC(10,4),
    verification_status_joint VARCHAR(30),

    -- =====================================================
    -- Origination / outcome
    -- =====================================================

    issue_date DATE,

    loan_status VARCHAR(60),

    purpose VARCHAR(60),

    addr_state VARCHAR(10),

    -- =====================================================
    -- Credit-risk characteristics
    -- =====================================================

    dti NUMERIC(10,4),

    delinq_2yrs INTEGER,

    earliest_credit_date DATE,

    credit_history_months INTEGER,

    inq_last_6mths INTEGER,

    mths_since_last_delinq INTEGER,

    open_acc INTEGER,

    pub_rec INTEGER,

    revol_bal NUMERIC(18,2),

    revol_util NUMERIC(8,3),

    total_acc INTEGER,

    acc_now_delinq INTEGER,

    tot_coll_amt NUMERIC(18,2),

    tot_cur_bal NUMERIC(18,2),

    acc_open_past_24mths INTEGER,

    avg_cur_bal NUMERIC(18,2),

    bc_open_to_buy NUMERIC(18,2),

    bc_util NUMERIC(8,3),

    chargeoff_within_12_mths INTEGER,

    delinq_amnt NUMERIC(18,2),

    mort_acc INTEGER,

    mths_since_recent_inq INTEGER,

    num_accts_ever_120_pd INTEGER,

    num_tl_90g_dpd_24m INTEGER,

    pct_tl_nvr_dlq NUMERIC(8,3),

    percent_bc_gt_75 NUMERIC(8,3),

    pub_rec_bankruptcies INTEGER,

    tax_liens INTEGER,

    tot_hi_cred_lim NUMERIC(18,2),

    total_bal_ex_mort NUMERIC(18,2),

    total_bc_limit NUMERIC(18,2),

    -- =====================================================
    -- Loan performance
    -- =====================================================

    out_prncp NUMERIC(18,2),

    total_pymnt NUMERIC(18,2),

    total_rec_prncp NUMERIC(18,2),

    total_rec_int NUMERIC(18,2),

    total_rec_late_fee NUMERIC(18,2),

    recoveries NUMERIC(18,2),

    collection_recovery_fee NUMERIC(18,2),

    last_pymnt_date DATE,

    last_pymnt_amnt NUMERIC(18,2),

    -- =====================================================
    -- Hardship / settlement
    -- =====================================================

    hardship_flag VARCHAR(10),

    hardship_reason VARCHAR(100),

    hardship_status VARCHAR(50),

    debt_settlement_flag VARCHAR(10),

    settlement_status VARCHAR(50),

    settlement_date DATE,

    settlement_amount NUMERIC(18,2),

    settlement_percentage NUMERIC(8,3),

    settlement_term INTEGER,

    disbursement_method VARCHAR(30)
);

WITH typed AS (

    SELECT

        NULLIF(BTRIM(id), '') AS source_id,

        -- Loan amounts
        NULLIF(BTRIM(loan_amnt), '')::NUMERIC
            AS loan_amnt,

        NULLIF(BTRIM(funded_amnt), '')::NUMERIC
            AS funded_amnt,

        NULLIF(BTRIM(funded_amnt_inv), '')::NUMERIC
            AS funded_amnt_inv,

        -- Term
        CASE
            WHEN NULLIF(BTRIM(term), '') IS NULL
                THEN NULL
            ELSE
                NULLIF(
                    REGEXP_REPLACE(
                        term,
                        '[^0-9]',
                        '',
                        'g'
                    ),
                    ''
                )::SMALLINT
        END AS term_months,

        -- Interest rate
        NULLIF(
            REPLACE(
                BTRIM(int_rate),
                '%',
                ''
            ),
            ''
        )::NUMERIC AS int_rate,

        NULLIF(BTRIM(installment), '')::NUMERIC
            AS installment,

        NULLIF(UPPER(BTRIM(grade)), '')
            AS grade,

        NULLIF(UPPER(BTRIM(sub_grade)), '')
            AS sub_grade,

        -- Employment
        NULLIF(BTRIM(emp_length), '')
            AS emp_length_raw,

        CASE
            WHEN NULLIF(BTRIM(emp_length), '') IS NULL
                THEN NULL

            WHEN BTRIM(emp_length) = '< 1 year'
                THEN 0

            WHEN BTRIM(emp_length) = '10+ years'
                THEN 10

            ELSE
                NULLIF(
                    REGEXP_REPLACE(
                        emp_length,
                        '[^0-9]',
                        '',
                        'g'
                    ),
                    ''
                )::SMALLINT
        END AS employment_years,

        NULLIF(BTRIM(home_ownership), '')
            AS home_ownership,

        NULLIF(BTRIM(annual_inc), '')::NUMERIC
            AS annual_inc,

        NULLIF(BTRIM(verification_status), '')
            AS verification_status,

        NULLIF(BTRIM(application_type), '')
            AS application_type,

        NULLIF(BTRIM(annual_inc_joint), '')::NUMERIC
            AS annual_inc_joint,

        NULLIF(BTRIM(dti_joint), '')::NUMERIC
            AS dti_joint,

        NULLIF(BTRIM(verification_status_joint), '')
            AS verification_status_joint,

        -- Dates
        CASE
            WHEN NULLIF(BTRIM(issue_d), '') IS NULL
                THEN NULL
            ELSE
                TO_DATE(
                    '01-' || BTRIM(issue_d),
                    'DD-Mon-YYYY'
                )
        END AS issue_date,

        NULLIF(BTRIM(loan_status), '')
            AS loan_status,

        NULLIF(BTRIM(purpose), '')
            AS purpose,

        NULLIF(UPPER(BTRIM(addr_state)), '')
            AS addr_state,

        -- Core risk variables
        NULLIF(BTRIM(dti), '')::NUMERIC
            AS dti,

        NULLIF(BTRIM(delinq_2yrs), '')::NUMERIC::INTEGER
            AS delinq_2yrs,

        CASE
            WHEN NULLIF(BTRIM(earliest_cr_line), '') IS NULL
                THEN NULL
            ELSE
                TO_DATE(
                    '01-' || BTRIM(earliest_cr_line),
                    'DD-Mon-YYYY'
                )
        END AS earliest_credit_date,

        NULLIF(BTRIM(inq_last_6mths), '')::NUMERIC::INTEGER
            AS inq_last_6mths,

        NULLIF(BTRIM(mths_since_last_delinq), '')::NUMERIC::INTEGER
            AS mths_since_last_delinq,

        NULLIF(BTRIM(open_acc), '')::NUMERIC::INTEGER
            AS open_acc,

        NULLIF(BTRIM(pub_rec), '')::NUMERIC::INTEGER
            AS pub_rec,

        NULLIF(BTRIM(revol_bal), '')::NUMERIC
            AS revol_bal,

        NULLIF(
            REPLACE(BTRIM(revol_util), '%', ''),
            ''
        )::NUMERIC AS revol_util,

        NULLIF(BTRIM(total_acc), '')::NUMERIC::INTEGER
            AS total_acc,

        NULLIF(BTRIM(acc_now_delinq), '')::NUMERIC::INTEGER
            AS acc_now_delinq,

        NULLIF(BTRIM(tot_coll_amt), '')::NUMERIC
            AS tot_coll_amt,

        NULLIF(BTRIM(tot_cur_bal), '')::NUMERIC
            AS tot_cur_bal,

        NULLIF(BTRIM(acc_open_past_24mths), '')::NUMERIC::INTEGER
            AS acc_open_past_24mths,

        NULLIF(BTRIM(avg_cur_bal), '')::NUMERIC
            AS avg_cur_bal,

        NULLIF(BTRIM(bc_open_to_buy), '')::NUMERIC
            AS bc_open_to_buy,

        NULLIF(
            REPLACE(BTRIM(bc_util), '%', ''),
            ''
        )::NUMERIC AS bc_util,

        NULLIF(BTRIM(chargeoff_within_12_mths), '')::NUMERIC::INTEGER
            AS chargeoff_within_12_mths,

        NULLIF(BTRIM(delinq_amnt), '')::NUMERIC
            AS delinq_amnt,

        NULLIF(BTRIM(mort_acc), '')::NUMERIC::INTEGER
            AS mort_acc,

        NULLIF(BTRIM(mths_since_recent_inq), '')::NUMERIC::INTEGER
            AS mths_since_recent_inq,

        NULLIF(BTRIM(num_accts_ever_120_pd), '')::NUMERIC::INTEGER
            AS num_accts_ever_120_pd,

        NULLIF(BTRIM(num_tl_90g_dpd_24m), '')::NUMERIC::INTEGER
            AS num_tl_90g_dpd_24m,

        NULLIF(BTRIM(pct_tl_nvr_dlq), '')::NUMERIC
            AS pct_tl_nvr_dlq,

        NULLIF(BTRIM(percent_bc_gt_75), '')::NUMERIC
            AS percent_bc_gt_75,

        NULLIF(BTRIM(pub_rec_bankruptcies), '')::NUMERIC::INTEGER
            AS pub_rec_bankruptcies,

        NULLIF(BTRIM(tax_liens), '')::NUMERIC::INTEGER
            AS tax_liens,

        NULLIF(BTRIM(tot_hi_cred_lim), '')::NUMERIC
            AS tot_hi_cred_lim,

        NULLIF(BTRIM(total_bal_ex_mort), '')::NUMERIC
            AS total_bal_ex_mort,

        NULLIF(BTRIM(total_bc_limit), '')::NUMERIC
            AS total_bc_limit,

        -- Performance
        NULLIF(BTRIM(out_prncp), '')::NUMERIC
            AS out_prncp,

        NULLIF(BTRIM(total_pymnt), '')::NUMERIC
            AS total_pymnt,

        NULLIF(BTRIM(total_rec_prncp), '')::NUMERIC
            AS total_rec_prncp,

        NULLIF(BTRIM(total_rec_int), '')::NUMERIC
            AS total_rec_int,

        NULLIF(BTRIM(total_rec_late_fee), '')::NUMERIC
            AS total_rec_late_fee,

        NULLIF(BTRIM(recoveries), '')::NUMERIC
            AS recoveries,

        NULLIF(BTRIM(collection_recovery_fee), '')::NUMERIC
            AS collection_recovery_fee,

        CASE
            WHEN NULLIF(BTRIM(last_pymnt_d), '') IS NULL
                THEN NULL
            ELSE
                TO_DATE(
                    '01-' || BTRIM(last_pymnt_d),
                    'DD-Mon-YYYY'
                )
        END AS last_pymnt_date,

        NULLIF(BTRIM(last_pymnt_amnt), '')::NUMERIC
            AS last_pymnt_amnt,

        -- Distress / settlement
        NULLIF(BTRIM(hardship_flag), '')
            AS hardship_flag,

        NULLIF(BTRIM(hardship_reason), '')
            AS hardship_reason,

        NULLIF(BTRIM(hardship_status), '')
            AS hardship_status,

        NULLIF(BTRIM(debt_settlement_flag), '')
            AS debt_settlement_flag,

        NULLIF(BTRIM(settlement_status), '')
            AS settlement_status,

        CASE
            WHEN NULLIF(BTRIM(settlement_date), '') IS NULL
                THEN NULL
            ELSE
                TO_DATE(
                    '01-' || BTRIM(settlement_date),
                    'DD-Mon-YYYY'
                )
        END AS settlement_date,

        NULLIF(BTRIM(settlement_amount), '')::NUMERIC
            AS settlement_amount,

        NULLIF(BTRIM(settlement_percentage), '')::NUMERIC
            AS settlement_percentage,

        NULLIF(BTRIM(settlement_term), '')::NUMERIC::INTEGER
            AS settlement_term,

        NULLIF(BTRIM(disbursement_method), '')
            AS disbursement_method

    FROM staging.lending_club_raw
),

derived AS (

    SELECT
        *,

        CASE
            WHEN issue_date IS NOT NULL
             AND earliest_credit_date IS NOT NULL
             AND earliest_credit_date <= issue_date

            THEN
                (
                    EXTRACT(
                        YEAR FROM AGE(
                            issue_date,
                            earliest_credit_date
                        )
                    ) * 12

                    +

                    EXTRACT(
                        MONTH FROM AGE(
                            issue_date,
                            earliest_credit_date
                        )
                    )
                )::INTEGER

            ELSE NULL
        END AS credit_history_months

    FROM typed
)

INSERT INTO analytics.loans_clean (

    source_id,

    loan_amnt,
    funded_amnt,
    funded_amnt_inv,
    term_months,
    int_rate,
    installment,
    grade,
    sub_grade,

    emp_length_raw,
    employment_years,
    home_ownership,
    annual_inc,
    verification_status,
    application_type,

    annual_inc_joint,
    dti_joint,
    verification_status_joint,

    issue_date,
    loan_status,
    purpose,
    addr_state,

    dti,
    delinq_2yrs,
    earliest_credit_date,
    credit_history_months,
    inq_last_6mths,
    mths_since_last_delinq,
    open_acc,
    pub_rec,
    revol_bal,
    revol_util,
    total_acc,

    acc_now_delinq,
    tot_coll_amt,
    tot_cur_bal,
    acc_open_past_24mths,
    avg_cur_bal,
    bc_open_to_buy,
    bc_util,
    chargeoff_within_12_mths,
    delinq_amnt,
    mort_acc,
    mths_since_recent_inq,
    num_accts_ever_120_pd,
    num_tl_90g_dpd_24m,
    pct_tl_nvr_dlq,
    percent_bc_gt_75,
    pub_rec_bankruptcies,
    tax_liens,
    tot_hi_cred_lim,
    total_bal_ex_mort,
    total_bc_limit,

    out_prncp,
    total_pymnt,
    total_rec_prncp,
    total_rec_int,
    total_rec_late_fee,
    recoveries,
    collection_recovery_fee,
    last_pymnt_date,
    last_pymnt_amnt,

    hardship_flag,
    hardship_reason,
    hardship_status,

    debt_settlement_flag,
    settlement_status,
    settlement_date,
    settlement_amount,
    settlement_percentage,
    settlement_term,

    disbursement_method

)

SELECT

    source_id,

    loan_amnt,
    funded_amnt,
    funded_amnt_inv,
    term_months,
    int_rate,
    installment,
    grade,
    sub_grade,

    emp_length_raw,
    employment_years,
    home_ownership,
    annual_inc,
    verification_status,
    application_type,

    annual_inc_joint,
    dti_joint,
    verification_status_joint,

    issue_date,
    loan_status,
    purpose,
    addr_state,

    dti,
    delinq_2yrs,
    earliest_credit_date,
    credit_history_months,
    inq_last_6mths,
    mths_since_last_delinq,
    open_acc,
    pub_rec,
    revol_bal,
    revol_util,
    total_acc,

    acc_now_delinq,
    tot_coll_amt,
    tot_cur_bal,
    acc_open_past_24mths,
    avg_cur_bal,
    bc_open_to_buy,
    bc_util,
    chargeoff_within_12_mths,
    delinq_amnt,
    mort_acc,
    mths_since_recent_inq,
    num_accts_ever_120_pd,
    num_tl_90g_dpd_24m,
    pct_tl_nvr_dlq,
    percent_bc_gt_75,
    pub_rec_bankruptcies,
    tax_liens,
    tot_hi_cred_lim,
    total_bal_ex_mort,
    total_bc_limit,

    out_prncp,
    total_pymnt,
    total_rec_prncp,
    total_rec_int,
    total_rec_late_fee,
    recoveries,
    collection_recovery_fee,
    last_pymnt_date,
    last_pymnt_amnt,

    hardship_flag,
    hardship_reason,
    hardship_status,

    debt_settlement_flag,
    settlement_status,
    settlement_date,
    settlement_amount,
    settlement_percentage,
    settlement_term,

    disbursement_method

FROM derived

WHERE loan_amnt > 0
  AND issue_date IS NOT NULL
  AND loan_status IS NOT NULL;

SELECT COUNT(*) AS clean_rows
FROM analytics.loans_clean;

SELECT

    (SELECT COUNT(*)
     FROM staging.lending_club_raw)
        AS raw_rows,

    (SELECT COUNT(*)
     FROM analytics.loans_clean)
        AS clean_rows,

    (SELECT COUNT(*)
     FROM staging.lending_club_raw)

    -

    (SELECT COUNT(*)
     FROM analytics.loans_clean)
        AS excluded_rows;

SELECT
    loan_row_id,
    loan_amnt,
    funded_amnt,
    term_months,
    int_rate,
    installment,
    grade,
    sub_grade,
    employment_years,
    annual_inc,
    issue_date,
    loan_status,
    purpose,
    dti
FROM analytics.loans_clean
LIMIT 20;

SELECT
    term_months,
    COUNT(*) AS loans
FROM analytics.loans_clean
GROUP BY term_months
ORDER BY term_months;

SELECT
    emp_length_raw,
    employment_years,
    COUNT(*) AS loans
FROM analytics.loans_clean
GROUP BY
    emp_length_raw,
    employment_years
ORDER BY
    employment_years NULLS LAST;

SELECT
    MIN(issue_date) AS first_issue_date,
    MAX(issue_date) AS last_issue_date
FROM analytics.loans_clean;

SELECT
    issue_date,
    earliest_credit_date,
    credit_history_months
FROM analytics.loans_clean
WHERE earliest_credit_date IS NOT NULL
ORDER BY loan_row_id
LIMIT 20;

SELECT
    MIN(credit_history_months) AS min_months,
    MAX(credit_history_months) AS max_months,
    ROUND(
        AVG(credit_history_months),
        1
    ) AS avg_months
FROM analytics.loans_clean;

SELECT
    grade,
    COUNT(*) AS loans
FROM analytics.loans_clean
GROUP BY grade
ORDER BY grade;

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

    MIN(loan_amnt) AS min_loan,
    MAX(loan_amnt) AS max_loan,
    ROUND(AVG(loan_amnt), 2) AS avg_loan,

    MIN(int_rate) AS min_rate,
    MAX(int_rate) AS max_rate,
    ROUND(AVG(int_rate), 2) AS avg_rate,

    MIN(annual_inc) AS min_income,
    MAX(annual_inc) AS max_income,
    ROUND(AVG(annual_inc), 2) AS avg_income,

    MIN(dti) AS min_dti,
    MAX(dti) AS max_dti,
    ROUND(AVG(dti), 2) AS avg_dti

FROM analytics.loans_clean;

SELECT
    COUNT(*) AS funded_greater_than_loan
FROM analytics.loans_clean
WHERE funded_amnt > loan_amnt;

SELECT
    COALESCE(hardship_flag, '[Missing]') AS hardship_flag,
    COUNT(*) AS loans
FROM analytics.loans_clean
GROUP BY hardship_flag
ORDER BY loans DESC;

SELECT
    COALESCE(
        debt_settlement_flag,
        '[Missing]'
    ) AS debt_settlement_flag,

    COUNT(*) AS loans

FROM analytics.loans_clean

GROUP BY debt_settlement_flag

ORDER BY loans DESC;

CREATE INDEX idx_loans_clean_issue_date
ON analytics.loans_clean(issue_date);

CREATE INDEX idx_loans_clean_status
ON analytics.loans_clean(loan_status);

CREATE INDEX idx_loans_clean_grade
ON analytics.loans_clean(grade);

CREATE INDEX idx_loans_clean_term
ON analytics.loans_clean(term_months);

CREATE INDEX idx_loans_clean_purpose
ON analytics.loans_clean(purpose);

CREATE INDEX idx_loans_clean_state
ON analytics.loans_clean(addr_state);

CREATE INDEX idx_loans_clean_application
ON analytics.loans_clean(application_type);

ANALYZE analytics.loans_clean;

SELECT

    (SELECT COUNT(*)
     FROM staging.lending_club_raw)
        AS raw_records,

    (SELECT COUNT(*)
     FROM analytics.loans_clean)
        AS clean_records,

    (SELECT COUNT(*)
     FROM staging.lending_club_raw)

    -

    (SELECT COUNT(*)
     FROM analytics.loans_clean)
        AS excluded_records,

    (SELECT COUNT(DISTINCT loan_status)
     FROM analytics.loans_clean)
        AS loan_statuses,

    (SELECT COUNT(DISTINCT grade)
     FROM analytics.loans_clean)
        AS grades,

    (SELECT MIN(issue_date)
     FROM analytics.loans_clean)
        AS first_issue_date,

    (SELECT MAX(issue_date)
     FROM analytics.loans_clean)
        AS last_issue_date,

    (SELECT ROUND(SUM(funded_amnt), 2)
     FROM analytics.loans_clean)
        AS total_funded_amount;

SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'analytics'
  AND table_name = 'loans_clean'
ORDER BY ordinal_position;