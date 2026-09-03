-- Equipment_Telemetry_Aggregates__cio
-- Recovered from the org 2026-09-03 via:
--   sf api request rest "/services/data/v67.0/ssot/calculated-insights"
-- (the `expression` field; Calculated Insight definitions are NOT retrievable
--  through the Metadata API, so this endpoint is the only programmatic source)
--
-- Stage 1 of 3 in the Equipment Health Score pipeline.
-- Feeds Equipment_Health_Score__cio (alongside Equipment_Fault_Aggregates__cio).
--
-- Rows:     999 rows, one per monitored unit.
-- Source:   Equipment_Telemetry_DMO__dlm (29,970 raw readings).
-- Schedule: 24h, start 05:00 UTC.
-- Dialect:  ANSI_SQL   Data Space: default   Status: IN_USE / ACTIVE

SELECT
    Equipment_Telemetry_DMO__dlm.equipment_external_id__c AS EquipmentId__c,
    AVG(Equipment_Telemetry_DMO__dlm.vibration_score__c) AS AvgVibration__c,
    AVG(Equipment_Telemetry_DMO__dlm.setpoint_delta_f__c * Equipment_Telemetry_DMO__dlm.setpoint_delta_f__c) AS SetpointDeviationSq__c,
    COUNT(Equipment_Telemetry_DMO__dlm.reading_id__c) AS ReadingCount__c
FROM Equipment_Telemetry_DMO__dlm
GROUP BY Equipment_Telemetry_DMO__dlm.equipment_external_id__c
