-- Equipment_Health_Score__cio
-- Recovered from the org 2026-09-03 via:
--   sf api request rest "/services/data/v67.0/ssot/calculated-insights"
-- (the `expression` field; Calculated Insight definitions are NOT retrievable
--  through the Metadata API, so this endpoint is the only programmatic source)
--
-- Stage 3 of 3 in the Equipment Health Score pipeline.
-- Read by Sync_Health_Score_To_CRM, which writes the score onto Equipment_Asset__c.
--
-- Rows:     999 rows. Verified min 13.41, max 100, mean 90.71.
-- Source:   Equipment_Telemetry_Aggregates__cio LEFT JOIN Equipment_Fault_Aggregates__cio.
-- Schedule: 24h, start 07:30 UTC. The 2.5h offset from stages 1 and 2 IS the dependency mechanism.
-- Dialect:  ANSI_SQL   Data Space: default   Status: IN_USE / ACTIVE

SELECT
    Equipment_Telemetry_Aggregates__cio.EquipmentId__c AS EquipmentId__c,
    SUM(
      CASE WHEN (
            100
            - (CASE WHEN Equipment_Telemetry_Aggregates__cio.AvgVibration__c > 0.9
                    THEN (Equipment_Telemetry_Aggregates__cio.AvgVibration__c - 0.9) * 25 ELSE 0 END)
            - (CASE WHEN Equipment_Telemetry_Aggregates__cio.SetpointDeviationSq__c > 2.5
                    THEN (Equipment_Telemetry_Aggregates__cio.SetpointDeviationSq__c - 2.5) * 3 ELSE 0 END)
            - (CASE WHEN Equipment_Fault_Aggregates__cio.ActiveFaultScore__c IS NULL
                    THEN 0 ELSE Equipment_Fault_Aggregates__cio.ActiveFaultScore__c * 2.5 END)
           ) < 0 THEN 0
           ELSE (
            100
            - (CASE WHEN Equipment_Telemetry_Aggregates__cio.AvgVibration__c > 0.9
                    THEN (Equipment_Telemetry_Aggregates__cio.AvgVibration__c - 0.9) * 25 ELSE 0 END)
            - (CASE WHEN Equipment_Telemetry_Aggregates__cio.SetpointDeviationSq__c > 2.5
                    THEN (Equipment_Telemetry_Aggregates__cio.SetpointDeviationSq__c - 2.5) * 3 ELSE 0 END)
            - (CASE WHEN Equipment_Fault_Aggregates__cio.ActiveFaultScore__c IS NULL
                    THEN 0 ELSE Equipment_Fault_Aggregates__cio.ActiveFaultScore__c * 2.5 END)
           )
      END
    ) AS HealthScore__c
FROM Equipment_Telemetry_Aggregates__cio
LEFT JOIN Equipment_Fault_Aggregates__cio
  ON Equipment_Telemetry_Aggregates__cio.EquipmentId__c = Equipment_Fault_Aggregates__cio.EquipmentId__c
GROUP BY Equipment_Telemetry_Aggregates__cio.EquipmentId__c
