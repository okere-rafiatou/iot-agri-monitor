-- =============================================================
--  IoT Agricultural Monitoring System
--  Base de données PostgreSQL — Schema complet
--  Fichier : db/schema.sql
-- =============================================================

-- Activation des extensions utiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";   -- UUIDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";    -- Chiffrement / hash

-- Suppression dans l'ordre inverse des dépendances (pour reset propre)
DROP TABLE IF EXISTS Alerts           CASCADE;
DROP TABLE IF EXISTS SensorReadings   CASCADE;
DROP TABLE IF EXISTS IrrigationEvents CASCADE;
DROP TABLE IF EXISTS CropCycles       CASCADE;
DROP TABLE IF EXISTS IotDevices       CASCADE;
DROP TABLE IF EXISTS Fields           CASCADE;
DROP TABLE IF EXISTS Crops            CASCADE;
DROP TABLE IF EXISTS Farms            CASCADE;
DROP TABLE IF EXISTS Users            CASCADE;

-- =============================================================
--  TABLE : Users
-- =============================================================
CREATE TABLE Users (
    userId       SERIAL          PRIMARY KEY,
    userName     VARCHAR(100)    NOT NULL,
    userEmail    VARCHAR(150)    NOT NULL UNIQUE,
    userRole     VARCHAR(50)     NOT NULL
                                 CHECK (userRole IN ('Farm Manager','Agronomist','IoT Systems Manager','Data Analyst','Cybersecurity Officer')),
    passwordHash TEXT            NOT NULL,
    lastLogin    TIMESTAMP WITH TIME ZONE,
    createdAt    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    isActive     BOOLEAN         DEFAULT TRUE
);

-- =============================================================
--  TABLE : Farms
-- =============================================================
CREATE TABLE Farms (
    farmId        SERIAL          PRIMARY KEY,
    name          VARCHAR(150)    NOT NULL,
    location      VARCHAR(200),
    totalAreaHa   NUMERIC(10,2)   NOT NULL CHECK (totalAreaHa > 0),
    ownerId       INTEGER         NOT NULL REFERENCES Users(userId) ON DELETE RESTRICT,
    createdAt     TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================
--  TABLE : Fields
-- =============================================================
CREATE TABLE Fields (
    fieldId      SERIAL          PRIMARY KEY,
    farmId       INTEGER         NOT NULL REFERENCES Farms(farmId) ON DELETE CASCADE,
    name         VARCHAR(150)    NOT NULL,
    areaHa       NUMERIC(10,2)   NOT NULL CHECK (areaHa > 0),
    soilType     VARCHAR(100),
    gpsBoundary  TEXT,
    createdAt    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================
--  TABLE : Crops
-- =============================================================
CREATE TABLE Crops (
    cropId              SERIAL          PRIMARY KEY,
    cropName            VARCHAR(100)    NOT NULL UNIQUE,
    optimalPhMin        NUMERIC(4,2),
    optimalPhMax        NUMERIC(4,2),
    optimalMoistureMin  NUMERIC(5,2),
    optimalMoistureMax  NUMERIC(5,2),
    growthCycleDays     INTEGER         CHECK (growthCycleDays > 0),
    createdAt           TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================
--  TABLE : CropCycles
-- =============================================================
CREATE TABLE CropCycles (
    cycleId             SERIAL          PRIMARY KEY,
    fieldId             INTEGER         NOT NULL REFERENCES Fields(fieldId) ON DELETE CASCADE,
    cropId              INTEGER         NOT NULL REFERENCES Crops(cropId)  ON DELETE RESTRICT,
    plantingDate        DATE            NOT NULL,
    expectedHarvestDate DATE,
    actualHarvestDate   DATE,
    yieldTons           NUMERIC(10,2)   CHECK (yieldTons >= 0),
    status              VARCHAR(50)     DEFAULT 'Growing'
                                        CHECK (status IN ('Growing','Completed','Failed','Planned')),
    notes               TEXT,
    createdAt           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Cohérence des dates
    CONSTRAINT chk_harvest_dates CHECK (
        actualHarvestDate IS NULL OR actualHarvestDate >= plantingDate
    )
);

-- =============================================================
--  TABLE : IotDevices
-- =============================================================
CREATE TABLE IotDevices (
    deviceId           SERIAL          PRIMARY KEY,
    fieldId            INTEGER         NOT NULL REFERENCES Fields(fieldId) ON DELETE CASCADE,
    deviceType         VARCHAR(100)    NOT NULL,
    deviceSerialNumber VARCHAR(100)    UNIQUE,
    firmwareVersion    VARCHAR(50),
    devicePublicKey    TEXT,
    lastSeen           TIMESTAMP WITH TIME ZONE,
    deviceStatus       VARCHAR(50)     DEFAULT 'Active'
                                       CHECK (deviceStatus IN ('Active','Inactive','Maintenance','Decommissioned')),
    installedAt        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================
--  TABLE : SensorReadings
-- =============================================================
CREATE TABLE SensorReadings (
    readingId    SERIAL          PRIMARY KEY,
    deviceId     INTEGER         NOT NULL REFERENCES IotDevices(deviceId) ON DELETE CASCADE,
    timestamp    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    metricType   VARCHAR(100)    NOT NULL
                                 CHECK (metricType IN (
                                     'soil_moisture','soil_ph','soil_temperature',
                                     'air_temperature','air_humidity',
                                     'rainfall','wind_speed','light_intensity','nitrogen'
                                 )),
    value        NUMERIC(10,4)   NOT NULL,
    unit         VARCHAR(30),
    anomalyFlag  BOOLEAN         DEFAULT FALSE
);

-- Index sur timestamp + deviceId pour les requêtes time-series
CREATE INDEX idx_sensor_timestamp  ON SensorReadings (timestamp DESC);
CREATE INDEX idx_sensor_device     ON SensorReadings (deviceId, timestamp DESC);
CREATE INDEX idx_sensor_metric     ON SensorReadings (metricType, timestamp DESC);
CREATE INDEX idx_sensor_anomaly    ON SensorReadings (anomalyFlag) WHERE anomalyFlag = TRUE;

-- =============================================================
--  TABLE : IrrigationEvents
-- =============================================================
CREATE TABLE IrrigationEvents (
    irrigId           SERIAL          PRIMARY KEY,
    fieldId           INTEGER         NOT NULL REFERENCES Fields(fieldId) ON DELETE CASCADE,
    irrigStartTime    TIMESTAMP WITH TIME ZONE NOT NULL,
    irrigEndTime      TIMESTAMP WITH TIME ZONE,
    waterVolumeM3     NUMERIC(10,3)   CHECK (waterVolumeM3 >= 0),
    irrigAutomated    BOOLEAN         DEFAULT TRUE,
    triggeredBy       INTEGER         REFERENCES Users(userId) ON DELETE SET NULL,
    notes             TEXT,
    createdAt         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- L'heure de fin doit être après l'heure de début
    CONSTRAINT chk_irrig_times CHECK (
        irrigEndTime IS NULL OR irrigEndTime > irrigStartTime
    )
);

CREATE INDEX idx_irrig_field_time ON IrrigationEvents (fieldId, irrigStartTime DESC);

-- =============================================================
--  TABLE : Alerts
-- =============================================================
CREATE TABLE Alerts (
    alertId     SERIAL          PRIMARY KEY,
    fieldId     INTEGER         NOT NULL REFERENCES Fields(fieldId) ON DELETE CASCADE,
    deviceId    INTEGER         REFERENCES IotDevices(deviceId) ON DELETE SET NULL,
    alertType   VARCHAR(100)    NOT NULL,
    severity    VARCHAR(20)     NOT NULL
                                CHECK (severity IN ('Low','Medium','High','Critical')),
    message     TEXT,
    createdAt   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved    BOOLEAN         DEFAULT FALSE,
    resolvedAt  TIMESTAMP WITH TIME ZONE,
    resolvedBy  INTEGER         REFERENCES Users(userId) ON DELETE SET NULL,
    -- Si resolved=TRUE, resolvedAt doit être renseigné
    CONSTRAINT chk_resolved CHECK (
        resolved = FALSE OR resolvedAt IS NOT NULL
    )
);

CREATE INDEX idx_alerts_field    ON Alerts (fieldId, createdAt DESC);
CREATE INDEX idx_alerts_severity ON Alerts (severity) WHERE resolved = FALSE;
CREATE INDEX idx_alerts_open     ON Alerts (resolved) WHERE resolved = FALSE;

-- =============================================================
--  VUES UTILES pour Streamlit
-- =============================================================

-- Vue : lectures capteurs avec infos device + champ
CREATE OR REPLACE VIEW v_sensor_readings_full AS
SELECT
    sr.readingId,
    sr.timestamp,
    sr.metricType,
    sr.value,
    sr.unit,
    sr.anomalyFlag,
    d.deviceId,
    d.deviceType,
    d.deviceSerialNumber,
    f.fieldId,
    f.name        AS fieldName,
    f.soilType,
    fa.farmId,
    fa.name       AS farmName,
    fa.location   AS farmLocation
FROM SensorReadings sr
JOIN IotDevices   d  ON d.deviceId = sr.deviceId
JOIN Fields       f  ON f.fieldId  = d.fieldId
JOIN Farms        fa ON fa.farmId  = f.farmId;

-- Vue : alertes ouvertes avec infos champ + device
CREATE OR REPLACE VIEW v_open_alerts AS
SELECT
    a.alertId,
    a.alertType,
    a.severity,
    a.message,
    a.createdAt,
    f.name      AS fieldName,
    fa.name     AS farmName,
    d.deviceType,
    d.deviceSerialNumber
FROM Alerts     a
JOIN Fields     f  ON f.fieldId  = a.fieldId
JOIN Farms      fa ON fa.farmId  = f.farmId
LEFT JOIN IotDevices d ON d.deviceId = a.deviceId
WHERE a.resolved = FALSE
ORDER BY
    CASE a.severity
        WHEN 'Critical' THEN 1
        WHEN 'High'     THEN 2
        WHEN 'Medium'   THEN 3
        WHEN 'Low'      THEN 4
    END,
    a.createdAt DESC;

-- Vue : humidité moyenne par champ sur les dernières 24h
CREATE OR REPLACE VIEW v_avg_moisture_24h AS
SELECT
    f.fieldId,
    f.name          AS fieldName,
    fa.name         AS farmName,
    ROUND(AVG(sr.value)::NUMERIC, 2) AS avgMoisture,
    MAX(sr.timestamp)                AS lastReading
FROM SensorReadings sr
JOIN IotDevices d  ON d.deviceId = sr.deviceId
JOIN Fields     f  ON f.fieldId  = d.fieldId
JOIN Farms      fa ON fa.farmId  = f.farmId
WHERE sr.metricType = 'soil_moisture'
  AND sr.timestamp  >= NOW() - INTERVAL '24 hours'
GROUP BY f.fieldId, f.name, fa.name;

-- Vue : eau utilisée aujourd'hui par champ
CREATE OR REPLACE VIEW v_water_usage_today AS
SELECT
    f.fieldId,
    f.name                          AS fieldName,
    fa.name                         AS farmName,
    COALESCE(SUM(ie.waterVolumeM3), 0) AS totalWaterM3,
    COUNT(ie.irrigId)               AS eventCount
FROM Fields f
JOIN Farms fa ON fa.farmId = f.farmId
LEFT JOIN IrrigationEvents ie
    ON ie.fieldId = f.fieldId
    AND DATE(ie.irrigStartTime) = CURRENT_DATE
GROUP BY f.fieldId, f.name, fa.name;

-- Vue : rendement moyen par culture (tons/ha)
CREATE OR REPLACE VIEW v_yield_per_crop AS
SELECT
    c.cropName,
    COUNT(cc.cycleId)                                    AS totalCycles,
    ROUND(AVG(cc.yieldTons)::NUMERIC, 2)                 AS avgYieldTons,
    ROUND(AVG(cc.yieldTons / f.areaHa)::NUMERIC, 2)      AS avgYieldPerHa
FROM CropCycles cc
JOIN Crops  c ON c.cropId  = cc.cropId
JOIN Fields f ON f.fieldId = cc.fieldId
WHERE cc.yieldTons IS NOT NULL
  AND cc.status = 'Completed'
GROUP BY c.cropName
ORDER BY avgYieldPerHa DESC;

-- Vue : fréquence d'anomalies par champ
CREATE OR REPLACE VIEW v_anomaly_by_field AS
SELECT
    f.fieldId,
    f.name      AS fieldName,
    fa.name     AS farmName,
    COUNT(*)    AS anomalyCount,
    MAX(sr.timestamp) AS lastAnomaly
FROM SensorReadings sr
JOIN IotDevices d  ON d.deviceId = sr.deviceId
JOIN Fields     f  ON f.fieldId  = d.fieldId
JOIN Farms      fa ON fa.farmId  = f.farmId
WHERE sr.anomalyFlag = TRUE
GROUP BY f.fieldId, f.name, fa.name
ORDER BY anomalyCount DESC;

-- =============================================================
--  MESSAGE DE CONFIRMATION
-- =============================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Schema IoT Agri Monitor créé avec succès !';
    RAISE NOTICE '   Tables    : Users, Farms, Fields, Crops, CropCycles, IotDevices, SensorReadings, IrrigationEvents, Alerts';
    RAISE NOTICE '   Index     : 7 index créés';
    RAISE NOTICE '   Vues      : v_sensor_readings_full, v_open_alerts, v_avg_moisture_24h, v_water_usage_today, v_yield_per_crop, v_anomaly_by_field';
END $$;