-- Account_Risk_Score__cio
-- Recovered from the org 2026-09-03 via:
--   sf api request rest "/services/data/v67.0/ssot/calculated-insights"
-- (the `expression` field; Calculated Insight definitions are NOT retrievable
--  through the Metadata API, so this endpoint is the only programmatic source)
--
-- Stage 3 of 3 in the Account Risk Score pipeline.
-- Read by Sync_Risk_Score_to_CRM, which writes the score and its three components onto Account.
--
-- Rows:     50 rows. Verified min 0, max 84, mean 14.02. Higher = more risk.
-- Source:   ssot__Account__dlm joined to both stage-2 outputs and ERP_AR_Aging_DMO__dlm.
-- Schedule: 24h, start 05:00 UTC. NOTE: same start as its own inputs, unlike the equipment pipeline.
-- Dialect:  ANSI_SQL   Data Space: default   Status: IN_USE / ACTIVE

SELECT
  ssot__Account__dlm.External_ERP_Customer_Id__c AS AccountExternalId__c,

  SUM( CASE WHEN Account_Portal_Aggregates__cio.TotalEvents__c IS NULL THEN 30
            WHEN Account_Portal_Aggregates__cio.TotalEvents__c >= 20 THEN 0
            ELSE (20 - Account_Portal_Aggregates__cio.TotalEvents__c) * 1.5 END )
    AS PortalRiskPoints__c,

  SUM( CASE WHEN Account_Case_Aggregates__cio.WeightedOpenScore__c IS NULL THEN 0
            ELSE Account_Case_Aggregates__cio.WeightedOpenScore__c * 2.5 END )
    AS CaseRiskPoints__c,

  SUM( CASE WHEN ERP_AR_Aging_DMO__dlm.erp_customer_id__c IS NULL THEN 0
            ELSE (CASE WHEN ERP_AR_Aging_DMO__dlm.credit_status__c = 'On Hold' THEN 30 ELSE 0 END)
               + (ERP_AR_Aging_DMO__dlm.days_90_120__c + ERP_AR_Aging_DMO__dlm.days_120_plus__c) * 0.005
               + ERP_AR_Aging_DMO__dlm.days_60_90__c * 0.002 END )
    AS ARRiskPoints__c,

  SUM( CASE WHEN Account_Portal_Aggregates__cio.TotalEvents__c IS NULL THEN 0
            ELSE Account_Portal_Aggregates__cio.TotalEvents__c END )
    AS PortalEventCount__c,

  SUM( CASE WHEN Account_Case_Aggregates__cio.OpenCaseCount__c IS NULL THEN 0
            ELSE Account_Case_Aggregates__cio.OpenCaseCount__c END )
    AS OpenCaseCount__c,

  SUM( CASE WHEN ERP_AR_Aging_DMO__dlm.total_outstanding__c IS NULL THEN 0
            ELSE ERP_AR_Aging_DMO__dlm.total_outstanding__c END )
    AS ARTotalOutstanding__c,

  SUM( CASE WHEN (
            (CASE WHEN Account_Portal_Aggregates__cio.TotalEvents__c IS NULL THEN 30
                  WHEN Account_Portal_Aggregates__cio.TotalEvents__c >= 20 THEN 0
                  ELSE (20 - Account_Portal_Aggregates__cio.TotalEvents__c) * 1.5 END)
          + (CASE WHEN Account_Case_Aggregates__cio.WeightedOpenScore__c IS NULL THEN 0
                  ELSE Account_Case_Aggregates__cio.WeightedOpenScore__c * 2.5 END)
          + (CASE WHEN ERP_AR_Aging_DMO__dlm.erp_customer_id__c IS NULL THEN 0
                  ELSE (CASE WHEN ERP_AR_Aging_DMO__dlm.credit_status__c = 'On Hold' THEN 30 ELSE 0 END)
                     + (ERP_AR_Aging_DMO__dlm.days_90_120__c + ERP_AR_Aging_DMO__dlm.days_120_plus__c) * 0.005
                     + ERP_AR_Aging_DMO__dlm.days_60_90__c * 0.002 END)
          ) > 100 THEN 100
       ELSE (
            (CASE WHEN Account_Portal_Aggregates__cio.TotalEvents__c IS NULL THEN 30
                  WHEN Account_Portal_Aggregates__cio.TotalEvents__c >= 20 THEN 0
                  ELSE (20 - Account_Portal_Aggregates__cio.TotalEvents__c) * 1.5 END)
          + (CASE WHEN Account_Case_Aggregates__cio.WeightedOpenScore__c IS NULL THEN 0
                  ELSE Account_Case_Aggregates__cio.WeightedOpenScore__c * 2.5 END)
          + (CASE WHEN ERP_AR_Aging_DMO__dlm.erp_customer_id__c IS NULL THEN 0
                  ELSE (CASE WHEN ERP_AR_Aging_DMO__dlm.credit_status__c = 'On Hold' THEN 30 ELSE 0 END)
                     + (ERP_AR_Aging_DMO__dlm.days_90_120__c + ERP_AR_Aging_DMO__dlm.days_120_plus__c) * 0.005
                     + ERP_AR_Aging_DMO__dlm.days_60_90__c * 0.002 END)
          ) END )
    AS RiskScore__c

FROM ssot__Account__dlm
LEFT JOIN ERP_AR_Aging_DMO__dlm
  ON ERP_AR_Aging_DMO__dlm.erp_customer_id__c = ssot__Account__dlm.External_ERP_Customer_Id__c
LEFT JOIN Account_Portal_Aggregates__cio
  ON Account_Portal_Aggregates__cio.AccountExternalId__c = ssot__Account__dlm.External_ERP_Customer_Id__c
LEFT JOIN Account_Case_Aggregates__cio
  ON Account_Case_Aggregates__cio.AccountId__c = ssot__Account__dlm.ssot__Id__c
GROUP BY ssot__Account__dlm.External_ERP_Customer_Id__c
