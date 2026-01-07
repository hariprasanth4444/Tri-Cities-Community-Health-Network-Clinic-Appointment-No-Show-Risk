🏥 Clinic Appointment No-Show Analysis

Goal: Reduce clinic appointment no-shows using simple, data-driven interventions without increasing provider overruns.

🔍 Project Summary

Built a reproducible data pipeline to analyze appointment no-shows using operational and external signals.

Identified high-impact predictors: lead time, weather × time of day, and symptom chatter spikes.

Delivered decision-ready analytics and a 2-week A/B pilot plan targeting a 1–3% no-show reduction.

🧱 Data & Pipeline

Data Sources

De-identified appointment records

City-day weather data

City-day symptom chatter data

Pipeline

CSV → GCS → BigQuery → fact_day analysis view → summary tables


Standardized joins on city + date

LEFT JOINs to preserve appointment coverage

Centralized analysis view for consistent querying

🧹 Key Features Engineered

Lead time (booking → visit)

AM / PM time buckets

Temperature buckets + rain flag

High vs normal chatter days (top 25%)

📈 Key Findings

Long lead times and hot PM slots show higher no-show risk.

High symptom chatter days increase no-shows by ~2 pp.

Certain clinic × visit × time combinations are consistently higher risk.

🚀 Proposed Pilot

Enhanced reminders for new patients with long lead times.

Micro-overbooking (1 low-acuity slot) on flagged high-risk days.

Guardrails: no provider overruns, weekly monitoring.

📊 KPIs

No-show rate (target: −1 to −3 pp)

Filled slots per provider ↑

Provider overrun rate ↔

🛠️ Tech Stack

Python · SQL (BigQuery) · GCS · Pandas · Jupyter · OpenRefine
