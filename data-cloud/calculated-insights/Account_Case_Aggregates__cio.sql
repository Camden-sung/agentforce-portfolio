-- Account_Case_Aggregates__cio
-- Recovered from the org 2026-09-03 via:
--   sf api request rest "/services/data/v67.0/ssot/calculated-insights"
-- (the `expression` field; Calculated Insight definitions are NOT retrievable
--  through the Metadata API, so this endpoint is the only programmatic source)
--
-- Stage 2 of 3 in the Account Risk Score pipeline.
-- Feeds Account_Risk_Score__cio (alongside Account_Portal_Aggregates__cio).
--
-- Rows:     Row count not independently verified.
-- Source:   ssot__Case__dlm, the standard Case object via the CRM connector.
-- Schedule: 24h, start 05:00 UTC.
-- Dialect:  ANSI_SQL   Data Space: default   Status: IN_USE / ACTIVE

SELECT
    ssot__Case__dlm.ssot__AccountId__c AS AccountId__c,
    SUM(CASE WHEN ssot__Case__dlm.ssot__CaseStatusId__c = 'Closed' THEN 0 ELSE 1 END) AS OpenCaseCount__c,
    SUM(CASE
          WHEN ssot__Case__dlm.ssot__CaseStatusId__c = 'Closed' THEN 0
          WHEN ssot__Case__dlm.ssot__CasePriorityId__c = 'High'   THEN 5
          WHEN ssot__Case__dlm.ssot__CasePriorityId__c = 'Medium' THEN 2
          WHEN ssot__Case__dlm.ssot__CasePriorityId__c = 'Low'    THEN 1
          ELSE 0 END) AS WeightedOpenScore__c
FROM ssot__Case__dlm
GROUP BY ssot__Case__dlm.ssot__AccountId__c
