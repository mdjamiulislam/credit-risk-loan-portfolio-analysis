SELECT 
	current_database() AS database_name,
	current_schema() AS schema_name;

CREATE SCHEMA IF NOT EXISTS staging;

CREATE SCHEMA IF NOT EXISTS analytics;

SELECT
	schema_name
FROM information_schema.schemata
WHERE schema_name IN (
	'staging',
	'analytics'
)
ORDER BY schema_name;

DROP TABLE IF EXISTS staging.lending_club_raw;

CREATE TABLE staging.lending_club_raw (

    id TEXT,
    member_id TEXT,
    loan_amnt TEXT,
    funded_amnt TEXT,
    funded_amnt_inv TEXT,
    term TEXT,
    int_rate TEXT,
    installment TEXT,
    grade TEXT,
    sub_grade TEXT,
    emp_title TEXT,
    emp_length TEXT,
    home_ownership TEXT,
    annual_inc TEXT,
    verification_status TEXT,
    issue_d TEXT,
    loan_status TEXT,
    pymnt_plan TEXT,
    url TEXT,

    -- Source CSV column = desc
    loan_description TEXT,

    purpose TEXT,
    title TEXT,
    zip_code TEXT,
    addr_state TEXT,
    dti TEXT,
    delinq_2yrs TEXT,
    earliest_cr_line TEXT,
    inq_last_6mths TEXT,
    mths_since_last_delinq TEXT,
    mths_since_last_record TEXT,
    open_acc TEXT,
    pub_rec TEXT,
    revol_bal TEXT,
    revol_util TEXT,
    total_acc TEXT,
    initial_list_status TEXT,
    out_prncp TEXT,
    out_prncp_inv TEXT,
    total_pymnt TEXT,
    total_pymnt_inv TEXT,
    total_rec_prncp TEXT,
    total_rec_int TEXT,
    total_rec_late_fee TEXT,
    recoveries TEXT,
    collection_recovery_fee TEXT,
    last_pymnt_d TEXT,
    last_pymnt_amnt TEXT,
    next_pymnt_d TEXT,
    last_credit_pull_d TEXT,
    collections_12_mths_ex_med TEXT,
    mths_since_last_major_derog TEXT,
    policy_code TEXT,
    application_type TEXT,
    annual_inc_joint TEXT,
    dti_joint TEXT,
    verification_status_joint TEXT,
    acc_now_delinq TEXT,
    tot_coll_amt TEXT,
    tot_cur_bal TEXT,
    open_acc_6m TEXT,
    open_il_6m TEXT,
    open_il_12m TEXT,
    open_il_24m TEXT,
    mths_since_rcnt_il TEXT,
    total_bal_il TEXT,
    il_util TEXT,
    open_rv_12m TEXT,
    open_rv_24m TEXT,
    max_bal_bc TEXT,
    all_util TEXT,
    total_rev_hi_lim TEXT,
    inq_fi TEXT,
    total_cu_tl TEXT,
    inq_last_12m TEXT
);

SELECT
    COUNT(*) AS number_of_columns

FROM information_schema.columns

WHERE table_schema = 'staging'
  AND table_name = 'lending_club_raw';

SELECT
    ordinal_position,
    column_name,
    data_type

FROM information_schema.columns

WHERE table_schema = 'staging'
  AND table_name = 'lending_club_raw'

ORDER BY ordinal_position;