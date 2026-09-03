-- Account_Portal_Aggregates__cio
-- Recovered from the org 2026-09-03 via:
--   sf api request rest "/services/data/v67.0/ssot/calculated-insights"
-- (the `expression` field; Calculated Insight definitions are NOT retrievable
--  through the Metadata API, so this endpoint is the only programmatic source)
--
-- Stage 1 of 3 in the Account Risk Score pipeline.
-- Feeds Account_Risk_Score__cio (alongside Account_Case_Aggregates__cio).
--
-- Rows:     48 rows. Portal/CSR sources cover ~48 of 50 accounts.
-- Source:   Portal_Engagement_DMO__dlm (1,834 rows from portal_engagement.csv).
-- Schedule: 24h, start 05:00 UTC.
-- Dialect:  ANSI_SQL   Data Space: default   Status: IN_USE / ACTIVE

SELECT
    Portal_Engagement_DMO__dlm.account_external_id__c AS AccountExternalId__c,
    COUNT(Portal_Engagement_DMO__dlm.event_id__c) AS TotalEvents__c,
    SUM(CASE WHEN Portal_Engagement_DMO__dlm.event_type__c = 'login' THEN 1 ELSE 0 END) AS LoginCount__c
FROM Portal_Engagement_DMO__dlm
GROUP BY Portal_Engagement_DMO__dlm.account_external_id__c
