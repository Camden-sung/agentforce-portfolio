-- Equipment_Fault_Aggregates__cio
-- Recovered from the org 2026-09-03 via:
--   sf api request rest "/services/data/v67.0/ssot/calculated-insights"
-- (the `expression` field; Calculated Insight definitions are NOT retrievable
--  through the Metadata API, so this endpoint is the only programmatic source)
--
-- Stage 2 of 3 in the Equipment Health Score pipeline.
-- Feeds Equipment_Health_Score__cio (alongside Equipment_Telemetry_Aggregates__cio).
--
-- Rows:     881 rows.
-- Source:   Equipment_Fault_DMO__dlm (1,490 raw fault events).
-- Schedule: 24h, start 05:00 UTC.
-- Dialect:  ANSI_SQL   Data Space: default   Status: IN_USE / ACTIVE

SELECT
    Equipment_Fault_DMO__dlm.equipment_external_id__c AS EquipmentId__c,
    SUM(CASE WHEN Equipment_Fault_DMO__dlm.still_active__c = true AND Equipment_Fault_DMO__dlm.severity__c = 'Critical' THEN 10
             WHEN Equipment_Fault_DMO__dlm.still_active__c = true AND Equipment_Fault_DMO__dlm.severity__c = 'Major'    THEN 4
             WHEN Equipment_Fault_DMO__dlm.still_active__c = true AND Equipment_Fault_DMO__dlm.severity__c = 'Minor'    THEN 1
             ELSE 0 END) AS ActiveFaultScore__c,
    SUM(CASE WHEN Equipment_Fault_DMO__dlm.still_active__c = true THEN 1 ELSE 0 END) AS ActiveFaultCount__c,
    COUNT(Equipment_Fault_DMO__dlm.fault_event_id__c) AS TotalFaultCount__c
FROM Equipment_Fault_DMO__dlm
GROUP BY Equipment_Fault_DMO__dlm.equipment_external_id__c
