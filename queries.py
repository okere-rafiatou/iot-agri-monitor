# =============================================================
#  IoT Agricultural Monitoring System
#  Fichier : dashboard/queries.py
#  Rôle    : Connexion Supabase + requêtes SQL
# =============================================================

import streamlit as st
import pandas as pd
from sqlalchemy import create_engine, text


# ─── CONNEXION ────────────────────────────────────────────────
def get_engine():
    """
    Crée et retourne le moteur SQLAlchemy connecté à Supabase.
    La variable DATABASE_URL est stockée dans Streamlit Secrets.
    """
    db_url = st.secrets["DATABASE_URL"]
    return create_engine(db_url, pool_pre_ping=True)


def run_query(sql: str, params: dict = None) -> pd.DataFrame:
    """
    Exécute une requête SQL et retourne un DataFrame pandas.
    """
    engine = get_engine()
    with engine.connect() as conn:
        result = conn.execute(text(sql), params or {})
        rows = result.fetchall()
        return pd.DataFrame(rows, columns=result.keys())


# =============================================================
#  KPIs — PAGE OVERVIEW
# =============================================================

def get_total_active_fields() -> int:
    sql = """
        SELECT COUNT(DISTINCT f."fieldId") AS total
        FROM   "Fields" f
        JOIN   "IotDevices" d ON d."fieldId" = f."fieldId"
        WHERE  d."deviceStatus" = 'Active'
    """
    df = run_query(sql)
    return int(df["total"].iloc[0])


def get_avg_soil_moisture() -> float:
    sql = """
        SELECT ROUND(AVG(sr.value)::NUMERIC, 1) AS avg_moisture
        FROM   "SensorReadings" sr
        WHERE  sr."metricType" = 'soil_moisture'
          AND  sr."timestamp"  >= NOW() - INTERVAL '24 hours'
    """
    df = run_query(sql)
    val = df["avg_moisture"].iloc[0]
    return float(val) if val is not None else 0.0


def get_water_usage_today() -> float:
    sql = """
        SELECT COALESCE(SUM("waterVolumeM3"), 0) AS total_water
        FROM   "IrrigationEvents"
        WHERE  DATE("irrigStartTime") = CURRENT_DATE
    """
    df = run_query(sql)
    return float(df["total_water"].iloc[0])


def get_active_alerts_count() -> int:
    sql = """
        SELECT COUNT(*) AS total
        FROM   "Alerts"
        WHERE  resolved = FALSE
    """
    df = run_query(sql)
    return int(df["total"].iloc[0])


def get_active_devices_count() -> int:
    sql = """
        SELECT COUNT(*) AS total
        FROM   "IotDevices"
        WHERE  "deviceStatus" = 'Active'
    """
    df = run_query(sql)
    return int(df["total"].iloc[0])


# =============================================================
#  MOISTURE — PAGE
# =============================================================

def get_moisture_last_30_days(field_id: int = None) -> pd.DataFrame:
    sql = """
        SELECT
            DATE(sr."timestamp") AS date,
            f."name" AS field_name,
            ROUND(AVG(sr.value)::NUMERIC, 2) AS avg_moisture
        FROM   "SensorReadings" sr
        JOIN   "IotDevices" d ON d."deviceId" = sr."deviceId"
        JOIN   "Fields" f ON f."fieldId" = d."fieldId"
        WHERE  sr."metricType" = 'soil_moisture'
          AND  sr."timestamp" >= NOW() - INTERVAL '30 days'
          AND  (:field_id IS NULL OR f."fieldId" = :field_id)
        GROUP BY DATE(sr."timestamp"), f."fieldId", f."name"
        ORDER BY date ASC
    """
    return run_query(sql, {"field_id": field_id})


def get_fields_list() -> pd.DataFrame:
    sql = """
        SELECT f."fieldId", f."name" AS field_name, fa."name" AS farm_name
        FROM   "Fields" f
        JOIN   "Farms" fa ON fa."farmId" = f."farmId"
        ORDER BY fa."name", f."name"
    """
    return run_query(sql)


# =============================================================
#  TEMPERATURE
# =============================================================

def get_temperature_trend(days: int = 30) -> pd.DataFrame:
    sql = """
        SELECT
            DATE(sr."timestamp") AS date,
            ROUND(MIN(sr.value)::NUMERIC, 1) AS temp_min,
            ROUND(AVG(sr.value)::NUMERIC, 1) AS temp_avg,
            ROUND(MAX(sr.value)::NUMERIC, 1) AS temp_max
        FROM   "SensorReadings" sr
        WHERE  sr."metricType" = 'air_temperature'
          AND  sr."timestamp" >= NOW() - INTERVAL :days
        GROUP BY DATE(sr."timestamp")
        ORDER BY date ASC
    """
    return run_query(sql, {"days": f"{days} days"})


# =============================================================
#  IRRIGATION
# =============================================================

def get_irrigation_events(field_id: int = None) -> pd.DataFrame:
    sql = """
        SELECT
            ie."irrigId",
            f."name" AS field_name,
            fa."name" AS farm_name,
            ie."irrigStartTime" AS start_time,
            ie."irrigEndTime" AS end_time,
            ROUND(ie."waterVolumeM3"::NUMERIC, 2) AS volume_m3,
            ie."irrigAutomated",
            EXTRACT(EPOCH FROM (ie."irrigEndTime" - ie."irrigStartTime")) / 3600 AS duration_hours
        FROM   "IrrigationEvents" ie
        JOIN   "Fields" f ON f."fieldId" = ie."fieldId"
        JOIN   "Farms" fa ON fa."farmId" = f."farmId"
        WHERE  (:field_id IS NULL OR ie."fieldId" = :field_id)
        ORDER BY ie."irrigStartTime" DESC
        LIMIT 100
    """
    return run_query(sql, {"field_id": field_id})


def get_water_usage_by_field() -> pd.DataFrame:
    sql = """
        SELECT
            f."name" AS field_name,
            fa."name" AS farm_name,
            ROUND(SUM(ie."waterVolumeM3")::NUMERIC, 2) AS total_volume_m3,
            COUNT(ie."irrigId") AS event_count
        FROM   "IrrigationEvents" ie
        JOIN   "Fields" f ON f."fieldId" = ie."fieldId"
        JOIN   "Farms" fa ON fa."farmId" = f."farmId"
        GROUP BY f."fieldId", f."name", fa."name"
        ORDER BY total_volume_m3 DESC
    """
    return run_query(sql)


# =============================================================
#  ALERTES
# =============================================================

def get_open_alerts() -> pd.DataFrame:
    sql = """
        SELECT
            a."alertId",
            f."name" AS field_name,
            fa."name" AS farm_name,
            a."alertType",
            a."severity",
            a."message",
            a."createdAt"
        FROM   "Alerts" a
        JOIN   "Fields" f ON f."fieldId" = a."fieldId"
        JOIN   "Farms" fa ON fa."farmId" = f."farmId"
        WHERE  a."resolved" = FALSE
        ORDER BY a."createdAt" DESC
    """
    return run_query(sql)


def resolve_alert(alert_id: int, user_id: int) -> None:
    sql = """
        UPDATE "Alerts"
        SET resolved = TRUE,
            "resolvedAt" = NOW(),
            "resolvedBy" = :user_id
        WHERE "alertId" = :alert_id
    """
    engine = get_engine()
    with engine.connect() as conn:
        conn.execute(text(sql), {"alert_id": alert_id, "user_id": user_id})
        conn.commit()