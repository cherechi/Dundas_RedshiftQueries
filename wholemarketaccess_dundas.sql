/* Flattened view of research.wholemarketaccess (Redshift) */
/* One output row per source row; every JSON key becomes its own column. */
/* Arrays are flattened positionally (_1, _2) -- the data has at most */
/* 2 document types per document and at most 1 secondary document. */

WITH base AS (
    SELECT
        w.*,
        /* JSON columns are VARCHAR. Wrapping in [ ] and taking element 0 returns the JSON text */
        /* whether it is stored normally or double-encoded as a quoted string. */
        json_extract_array_element_text('[' || w.primarydocument || ']', 0, true)    AS pd,
        json_extract_array_element_text('[' || w.secondarydocument || ']', 0, true)  AS sd,
        json_extract_array_element_text('[' || w.policydata || ']', 0, true)         AS pol,
        json_extract_array_element_text('[' || w.cdv || ']', 0, true)                AS cdvj,
        json_extract_array_element_text('[' || w.changedfields || ']', 0, true)      AS changedfields_txt
    FROM research.wholemarketaccess w
    WHERE w.reportid = 2040
      AND w.refreshid = 8699
),
lvl1 AS (
    SELECT
        b.*,
        NULLIF(json_extract_path_text(pd, 'documenttypes', true), '')                AS pd_doctypes,
        NULLIF(json_extract_path_text(pd, 'assetrevisiondates', true), '')           AS pd_revdates,
        NULLIF(json_extract_array_element_text(sd, 0, true), '')                     AS sd1,
        NULLIF(json_extract_array_element_text(sd, 1, true), '')                     AS sd2
    FROM base b
),
lvl2 AS (
    SELECT
        l.*,
        NULLIF(json_extract_array_element_text(pd_doctypes, 0, true), '')            AS pd_dt1,
        NULLIF(json_extract_array_element_text(pd_doctypes, 1, true), '')            AS pd_dt2,
        NULLIF(json_extract_path_text(sd1, 'documenttypes', true), '')               AS sd1_doctypes,
        NULLIF(json_extract_path_text(sd1, 'assetrevisiondates', true), '')          AS sd1_revdates,
        NULLIF(json_extract_path_text(sd2, 'documenttypes', true), '')               AS sd2_doctypes,
        NULLIF(json_extract_path_text(sd2, 'assetrevisiondates', true), '')          AS sd2_revdates
    FROM lvl1 l
),
lvl3 AS (
    SELECT
        l.*,
        NULLIF(json_extract_array_element_text(sd1_doctypes, 0, true), '')          AS sd1_dt1,
        NULLIF(json_extract_array_element_text(sd1_doctypes, 1, true), '')          AS sd1_dt2,
        NULLIF(json_extract_array_element_text(sd2_doctypes, 0, true), '')          AS sd2_dt1,
        NULLIF(json_extract_array_element_text(sd2_doctypes, 1, true), '')          AS sd2_dt2
    FROM lvl2 l
)
SELECT
    /* ---------- plain columns ---------- */
    reportid,
    projectname,
    refreshid,
    companyid,
    companyname,
    plantypeid,
    plantypename,
    vanityplantypeid,
    stateid,
    benefitmanagerid,
    benefitmanagername,
    benefittype,
    coveredlives,
    publisheddate,
    cutoffdate,
    ingested_at,
    changesinceprevious,
    changedfields_txt AS changedfields,  /* always [] in current data; kept raw */

    /* ---------- cdv ---------- */
    NULLIF(json_extract_path_text(cdvj, 'product', 'id', true), '')::bigint           AS product_id,
    NULLIF(json_extract_path_text(cdvj, 'product', 'name', true), '')                 AS product_name,
    NULLIF(json_extract_path_text(cdvj, 'indication', 'id', true), '')::bigint        AS indication_id,
    NULLIF(json_extract_path_text(cdvj, 'indication', 'name', true), '')              AS indication_name,

    /* ---------- policydata ---------- */
    NULLIF(json_extract_path_text(pol, 'Covered', true), '')                                                AS policy_covered,
    NULLIF(json_extract_path_text(pol, 'Policy Title', true), '')                                           AS policy_title,
    NULLIF(json_extract_path_text(pol, 'Review Date', true), '')                                            AS policy_review_date,
    NULLIF(json_extract_path_text(pol, 'Coverage Criteria', true), '')                                      AS policy_coverage_criteria,
    NULLIF(json_extract_path_text(pol, 'Prior Authorization (Explicit/Implicit/No/Unspecified)', true), '') AS policy_prior_authorization,
    NULLIF(json_extract_path_text(pol, 'Step Therapy Requirement (Single-Select) (Standard)', true), '')     AS policy_step_therapy_requirement,
    NULLIF(json_extract_path_text(pol, 'Step Therapy (Verbatim)', true), '')                                AS policy_step_therapy_verbatim,
    NULLIF(json_extract_path_text(pol, 'ePA Portal Link', true), '')                                        AS policy_epa_portal_link,

    /* ---------- primarydocument ---------- */
    NULLIF(json_extract_path_text(pd, 'documentid', true), '')::bigint                AS pd_documentid,
    NULLIF(json_extract_path_text(pd, 'assetrevisionid', true), '')::bigint           AS pd_assetrevisionid,
    NULLIF(json_extract_path_text(pd, 'urlalias', true), '')                          AS pd_urlalias,
    NULLIF(json_extract_path_text(pd, 'source', true), '')                            AS pd_source,
    NULLIF(json_extract_path_text(pd, 'firstfetchtime', true), '')                    AS pd_firstfetchtime,
    NULLIF(json_extract_path_text(pd, 'lastreviewdate', true), '')                    AS pd_lastreviewdate,
    NULLIF(json_extract_path_text(pd_revdates, 'Review date', true), '')              AS pd_review_date,
    NULLIF(json_extract_path_text(pd_revdates, 'Next review date (est.)', true), '')  AS pd_next_review_date_est,
    NULLIF(json_extract_path_text(pd_dt1, 'id', true), '')::int                       AS pd_documenttype_1_id,
    NULLIF(json_extract_path_text(pd_dt1, 'name', true), '')                          AS pd_documenttype_1_name,
    NULLIF(json_extract_path_text(pd_dt2, 'id', true), '')::int                       AS pd_documenttype_2_id,
    NULLIF(json_extract_path_text(pd_dt2, 'name', true), '')                          AS pd_documenttype_2_name,

    /* ---------- secondarydocument[0] ---------- */
    NULLIF(json_extract_path_text(sd1, 'documentid', true), '')::bigint               AS sd1_documentid,
    NULLIF(json_extract_path_text(sd1, 'assetrevisionid', true), '')::bigint          AS sd1_assetrevisionid,
    NULLIF(json_extract_path_text(sd1, 'urlalias', true), '')                         AS sd1_urlalias,
    NULLIF(json_extract_path_text(sd1, 'source', true), '')                           AS sd1_source,
    NULLIF(json_extract_path_text(sd1, 'firstfetchtime', true), '')                   AS sd1_firstfetchtime,
    NULLIF(json_extract_path_text(sd1, 'lastreviewdate', true), '')                   AS sd1_lastreviewdate,
    NULLIF(json_extract_path_text(sd1_revdates, 'Review date', true), '')             AS sd1_review_date,
    NULLIF(json_extract_path_text(sd1_revdates, 'Next review date (est.)', true), '') AS sd1_next_review_date_est,
    NULLIF(json_extract_path_text(sd1_dt1, 'id', true), '')::int                      AS sd1_documenttype_1_id,
    NULLIF(json_extract_path_text(sd1_dt1, 'name', true), '')                         AS sd1_documenttype_1_name,
    NULLIF(json_extract_path_text(sd1_dt2, 'id', true), '')::int                      AS sd1_documenttype_2_id,
    NULLIF(json_extract_path_text(sd1_dt2, 'name', true), '')                         AS sd1_documenttype_2_name,

    /* ---------- secondarydocument[1] (empty today; future-proofing) ---------- */
    NULLIF(json_extract_path_text(sd2, 'documentid', true), '')::bigint               AS sd2_documentid,
    NULLIF(json_extract_path_text(sd2, 'assetrevisionid', true), '')::bigint          AS sd2_assetrevisionid,
    NULLIF(json_extract_path_text(sd2, 'urlalias', true), '')                         AS sd2_urlalias,
    NULLIF(json_extract_path_text(sd2, 'source', true), '')                           AS sd2_source,
    NULLIF(json_extract_path_text(sd2, 'firstfetchtime', true), '')                   AS sd2_firstfetchtime,
    NULLIF(json_extract_path_text(sd2, 'lastreviewdate', true), '')                   AS sd2_lastreviewdate,
    NULLIF(json_extract_path_text(sd2_revdates, 'Review date', true), '')             AS sd2_review_date,
    NULLIF(json_extract_path_text(sd2_revdates, 'Next review date (est.)', true), '') AS sd2_next_review_date_est,
    NULLIF(json_extract_path_text(sd2_dt1, 'id', true), '')::int                      AS sd2_documenttype_1_id,
    NULLIF(json_extract_path_text(sd2_dt1, 'name', true), '')                         AS sd2_documenttype_1_name,
    NULLIF(json_extract_path_text(sd2_dt2, 'id', true), '')::int                      AS sd2_documenttype_2_id,
    NULLIF(json_extract_path_text(sd2_dt2, 'name', true), '')                         AS sd2_documenttype_2_name
FROM lvl3
