-- =============================================================
--  IoT Agricultural Monitoring System
--  Données d'exemple — seed_data.sql
--  Fichier : db/seed_data.sql
-- =============================================================

-- =============================================================
--  USERS
-- =============================================================
INSERT INTO Users (userId, userName, userEmail, userRole, passwordHash, lastLogin) VALUES
(1, 'John Soh',        'john.soh@agrifarm.com',        'Farm Manager',          '$2b$12$xyz1hashedpassword1', '2026-02-20 08:15:00+00'),
(2, 'Alamine Lopez',   'maria.alamine@agrifarm.com',   'Agronomist',            '$2b$12$xyz2hashedpassword2', '2026-02-21 09:42:00+00'),
(3, 'Moussa Diallo',   'moussa.diallo@agrifarm.com',   'IoT Systems Manager',   '$2b$12$xyz3hashedpassword3', '2026-02-22 07:30:00+00'),
(4, 'Fatou Ndiaye',    'fatou.ndiaye@agrifarm.com',    'Data Analyst',          '$2b$12$xyz4hashedpassword4', '2026-02-23 10:00:00+00'),
(5, 'Ibrahima Sarr',   'ibrahima.sarr@agrifarm.com',   'Cybersecurity Officer', '$2b$12$xyz5hashedpassword5', '2026-02-24 08:00:00+00'),
-- Owners des fermes
(71, 'Oumar Ba',       'oumar.ba@agrifarm.com',        'Farm Manager',          '$2b$12$xyz71hashedpassword', '2026-02-19 07:00:00+00'),
(81, 'Aminata Sow',    'aminata.sow@agrifarm.com',     'Farm Manager',          '$2b$12$xyz81hashedpassword', '2026-02-18 06:45:00+00');

-- Reset séquence après insertion manuelle
SELECT setval('users_userid_seq', 100);

-- =============================================================
--  FARMS
-- =============================================================
INSERT INTO Farms (farmId, name, location, totalAreaHa, ownerId) VALUES
(101, 'Green Valley Farm', 'Dakar, Sénégal',  250.00, 81),
(202, 'Sunrise Agro Ltd',  'MBour, Sénégal',  180.50, 71);

SELECT setval('farms_farmid_seq', 300);

-- =============================================================
--  FIELDS
-- =============================================================
INSERT INTO Fields (fieldId, farmId, name, areaHa, soilType, gpsBoundary) VALUES
(1,  101, 'North Field',   50.00, 'Loamy',     'POLYGON((17.45 14.72, 17.46 14.72, 17.46 14.73, 17.45 14.73, 17.45 14.72))'),
(2,  101, 'South Field',   45.00, 'Sandy Loam','POLYGON((17.45 14.71, 17.46 14.71, 17.46 14.72, 17.45 14.72, 17.45 14.71))'),
(3,  101, 'East Field',    60.00, 'Clay',      'POLYGON((17.46 14.72, 17.47 14.72, 17.47 14.73, 17.46 14.73, 17.46 14.72))'),
(4,  202, 'Sector A',      35.50, 'Clay Loam', 'POLYGON((16.90 14.42, 16.91 14.42, 16.91 14.43, 16.90 14.43, 16.90 14.42))'),
(5,  202, 'Sector B',      40.00, 'Loamy',     'POLYGON((16.91 14.42, 16.92 14.42, 16.92 14.43, 16.91 14.43, 16.91 14.42))'),
(6,  202, 'Sector C',      30.00, 'Sandy',     'POLYGON((16.90 14.43, 16.91 14.43, 16.91 14.44, 16.90 14.44, 16.90 14.43))');

SELECT setval('fields_fieldid_seq', 20);

-- =============================================================
--  CROPS
-- =============================================================
INSERT INTO Crops (cropId, cropName, optimalPhMin, optimalPhMax, optimalMoistureMin, optimalMoistureMax, growthCycleDays) VALUES
(1, 'Wheat',     6.0, 7.0, 20.0, 40.0, 120),
(2, 'Maize',     5.5, 7.5, 25.0, 60.0, 150),
(3, 'Rice',      5.0, 6.5, 60.0, 80.0, 180),
(4, 'Millet',    5.5, 7.0, 15.0, 35.0, 90),
(5, 'Groundnut', 5.8, 6.5, 20.0, 45.0, 110),
(6, 'Sorghum',   5.5, 7.5, 18.0, 40.0, 130);

SELECT setval('crops_cropid_seq', 10);

-- =============================================================
--  CROP CYCLES
-- =============================================================
INSERT INTO CropCycles (fieldId, cropId, plantingDate, expectedHarvestDate, actualHarvestDate, yieldTons, status) VALUES
-- Cycles en cours
(1, 1, '2026-03-01', '2026-06-29', NULL,         NULL,   'Growing'),
(2, 2, '2026-02-15', '2026-07-15', NULL,         NULL,   'Growing'),
(4, 4, '2026-01-10', '2026-04-10', NULL,         NULL,   'Growing'),
(5, 5, '2026-02-01', '2026-05-21', NULL,         NULL,   'Growing'),
-- Cycles complétés
(2, 1, '2025-03-01', '2025-06-29', '2025-06-27', 185.50, 'Completed'),
(3, 2, '2025-09-10', '2026-02-07', '2026-02-05', 210.50, 'Completed'),
(4, 6, '2025-04-01', '2025-08-09', '2025-08-10', 95.20,  'Completed'),
(6, 3, '2025-06-01', '2025-11-28', '2025-11-25', 312.00, 'Completed'),
(1, 5, '2025-01-15', '2025-05-05', '2025-05-03', 142.80, 'Completed'),
-- Cycle échoué
(3, 3, '2025-01-01', '2025-06-30', NULL,         NULL,   'Failed');

-- =============================================================
--  IOT DEVICES
-- =============================================================
INSERT INTO IotDevices (deviceId, fieldId, deviceType, deviceSerialNumber, firmwareVersion, devicePublicKey, lastSeen, deviceStatus) VALUES
(1,  1, 'Soil Moisture Sensor', 'SM-45892', 'v1.3.2', 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1a', '2026-02-27 10:10:00+00', 'Active'),
(2,  1, 'Weather Station',      'WS-88321', 'v2.0.1', 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2b', '2026-02-27 10:08:00+00', 'Active'),
(3,  2, 'Soil Moisture Sensor', 'SM-45893', 'v1.3.2', 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3c', '2026-02-27 10:05:00+00', 'Active'),
(4,  2, 'Soil pH Sensor',       'PH-11201', 'v1.1.0', 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4d', '2026-02-27 09:55:00+00', 'Active'),
(5,  3, 'Soil Moisture Sensor', 'SM-45894', 'v1.3.2', 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5e', '2026-02-26 22:00:00+00', 'Inactive'),
(6,  3, 'Weather Station',      'WS-88322', 'v2.0.1', 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6f', '2026-02-27 10:07:00+00', 'Active'),
(7,  4, 'Soil Moisture Sensor', 'SM-45895', 'v1.4.0', 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7g', '2026-02-27 10:12:00+00', 'Active'),
(8,  5, 'Soil Moisture Sensor', 'SM-45896', 'v1.4.0', 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA8h', '2026-02-27 10:11:00+00', 'Active'),
(9,  5, 'Soil pH Sensor',       'PH-11202', 'v1.1.0', 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA9i', '2026-02-27 10:09:00+00', 'Active'),
(10, 6, 'Weather Station',      'WS-88323', 'v2.0.1', 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0j', '2026-02-27 10:06:00+00', 'Active');

SELECT setval('iotdevices_deviceid_seq', 20);

-- =============================================================
--  SENSOR READINGS (30 derniers jours — données réalistes)
-- =============================================================
INSERT INTO SensorReadings (deviceId, timestamp, metricType, value, unit, anomalyFlag)
SELECT
    d.deviceId,
    NOW() - (n || ' hours')::INTERVAL AS ts,
    d.metricType,
    CASE d.metricType
        WHEN 'soil_moisture'   THEN ROUND((RANDOM() * 30 + 15)::NUMERIC, 2)   -- 15–45%
        WHEN 'soil_ph'         THEN ROUND((RANDOM() * 2  + 5.5)::NUMERIC, 2)  -- 5.5–7.5
        WHEN 'air_temperature' THEN ROUND((RANDOM() * 20 + 20)::NUMERIC, 2)   -- 20–40°C
        WHEN 'air_humidity'    THEN ROUND((RANDOM() * 40 + 40)::NUMERIC, 2)   -- 40–80%
        WHEN 'rainfall'        THEN ROUND((RANDOM() * 10)::NUMERIC, 2)        -- 0–10mm
    END AS value,
    d.unit,
    CASE WHEN RANDOM() < 0.05 THEN TRUE ELSE FALSE END AS anomalyFlag  -- 5% anomalies
FROM
    generate_series(1, 720) AS n,   -- 720 heures = 30 jours
    (VALUES
        (1,  'soil_moisture',   '%'),
        (2,  'air_temperature', '°C'),
        (2,  'air_humidity',    '%'),
        (2,  'rainfall',        'mm'),
        (3,  'soil_moisture',   '%'),
        (4,  'soil_ph',         'pH'),
        (6,  'air_temperature', '°C'),
        (6,  'air_humidity',    '%'),
        (7,  'soil_moisture',   '%'),
        (8,  'soil_moisture',   '%'),
        (9,  'soil_ph',         'pH'),
        (10, 'air_temperature', '°C')
    ) AS d(deviceId, metricType, unit)
WHERE n % 4 = 0;  -- 1 lecture toutes les 4h pour garder un volume raisonnable

-- Quelques anomalies explicites pour les tests
UPDATE SensorReadings SET anomalyFlag = TRUE, value = 8.5
WHERE deviceId = 4 AND timestamp >= NOW() - INTERVAL '2 days'
  AND metricType = 'soil_ph'
LIMIT 3;

UPDATE SensorReadings SET anomalyFlag = TRUE, value = 9.0
WHERE deviceId = 2 AND timestamp >= NOW() - INTERVAL '5 days'
  AND metricType = 'air_temperature'
LIMIT 5;

-- =============================================================
--  IRRIGATION EVENTS
-- =============================================================
INSERT INTO IrrigationEvents (fieldId, irrigStartTime, irrigEndTime, waterVolumeM3, irrigAutomated, triggeredBy) VALUES
(1, '2026-02-26 05:00:00+00', '2026-02-26 06:30:00+00', 120.00, TRUE,  NULL),
(2, '2026-02-25 04:30:00+00', '2026-02-25 05:45:00+00',  95.50, FALSE, 1),
(3, '2026-02-24 05:00:00+00', '2026-02-24 06:00:00+00', 110.00, TRUE,  NULL),
(4, '2026-02-26 04:00:00+00', '2026-02-26 05:00:00+00',  75.00, TRUE,  NULL),
(5, '2026-02-25 05:00:00+00', '2026-02-25 06:15:00+00',  88.00, FALSE, 71),
(1, '2026-02-23 05:00:00+00', '2026-02-23 06:30:00+00', 115.00, TRUE,  NULL),
(2, '2026-02-22 04:30:00+00', '2026-02-22 05:30:00+00',  90.00, TRUE,  NULL),
(4, '2026-02-21 04:00:00+00', '2026-02-21 05:15:00+00',  80.00, TRUE,  NULL),
(5, '2026-02-20 05:00:00+00', '2026-02-20 06:00:00+00',  85.00, TRUE,  NULL),
(6, '2026-02-19 04:30:00+00', '2026-02-19 05:45:00+00',  70.00, FALSE, 71),
(1, '2026-02-18 05:00:00+00', '2026-02-18 06:30:00+00', 125.00, TRUE,  NULL),
(3, '2026-02-17 05:00:00+00', '2026-02-17 06:00:00+00', 100.00, TRUE,  NULL),
-- Aujourd'hui
(1, NOW() - INTERVAL '3 hours', NOW() - INTERVAL '1 hour', 118.00, TRUE, NULL),
(4, NOW() - INTERVAL '4 hours', NOW() - INTERVAL '3 hours', 77.00, TRUE, NULL);

-- =============================================================
--  ALERTS
-- =============================================================
INSERT INTO Alerts (fieldId, deviceId, alertType, severity, message, createdAt, resolved, resolvedAt, resolvedBy) VALUES
-- Alertes résolues
(1, 1, 'Low Soil Moisture',  'High',     'Moisture below 18% threshold in North Field',         '2026-02-26 04:45:00+00', TRUE,  '2026-02-26 06:45:00+00', 1),
(3, 6, 'High Temperature',   'Medium',   'Temperature exceeded 35°C in East Field',             '2026-02-20 14:10:00+00', TRUE,  '2026-02-20 16:00:00+00', 2),
(2, 4, 'Abnormal Soil pH',   'Medium',   'pH reading 8.2 — above optimal range for Maize',      '2026-02-18 09:00:00+00', TRUE,  '2026-02-19 10:00:00+00', 2),
-- Alertes ouvertes
(2, 3, 'Low Soil Moisture',  'High',     'Moisture at 14% — irrigation required immediately',   '2026-02-27 03:00:00+00', FALSE, NULL, NULL),
(3, NULL,'Device Offline',   'Critical', 'Soil Moisture Sensor SM-45894 offline since 22:00',   '2026-02-26 23:00:00+00', FALSE, NULL, NULL),
(4, 7, 'Low Soil Moisture',  'Medium',   'Moisture at 17% in Sector A — monitor closely',       '2026-02-27 05:30:00+00', FALSE, NULL, NULL),
(5, 9, 'Abnormal Soil pH',   'High',     'pH reading 4.9 — below optimal range for Groundnut', '2026-02-27 06:00:00+00', FALSE, NULL, NULL),
(1, 2, 'High Temperature',   'Medium',   'Air temperature reached 37°C in North Field',         NOW() - INTERVAL '2 hours', FALSE, NULL, NULL),
(6, 10,'Low Rainfall',       'Low',      'No rainfall detected for 15 consecutive days',        NOW() - INTERVAL '1 day',  FALSE, NULL, NULL);

-- =============================================================
--  DROITS SUR LES TABLES POUR agri_user
-- =============================================================
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO agri_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO agri_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO agri_user;

-- =============================================================
--  CONFIRMATION
-- =============================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Données insérées avec succès !';
    RAISE NOTICE '   Users             : 7';
    RAISE NOTICE '   Farms             : 2 (Dakar + MBour)';
    RAISE NOTICE '   Fields            : 6';
    RAISE NOTICE '   Crops             : 6 (Wheat, Maize, Rice, Millet, Groundnut, Sorghum)';
    RAISE NOTICE '   CropCycles        : 10 (4 en cours, 5 complétés, 1 échoué)';
    RAISE NOTICE '   IoTDevices        : 10';
    RAISE NOTICE '   SensorReadings    : ~2160 lectures (30 jours)';
    RAISE NOTICE '   IrrigationEvents  : 14';
    RAISE NOTICE '   Alerts            : 9 (3 résolues, 6 ouvertes)';
END $$;