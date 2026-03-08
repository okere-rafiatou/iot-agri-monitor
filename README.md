# IoT Agricultural Monitoring System

This project is a smart agriculture monitoring system built with Python, Streamlit and PostgreSQL. It collects real-time data from IoT soil sensors deployed across farm fields and displays everything through a web dashboard that farm managers can access from any browser.

## What the system does

The system monitors two farms — Green Valley Farm and Sunrise Agro Ltd — across 6 fields. Soil sensors measure moisture, temperature and pH every hour. The data is transmitted via LoRaWAN to a PostgreSQL database, then displayed live on the dashboard.

When sensor values go outside safe ranges, the system automatically generates alerts so the farm manager can take action before crops are damaged.

## Dashboard pages

- Overview — global KPIs showing active fields, average soil moisture, water used today, active alerts and active devices
- Moisture Analysis — 30-day soil moisture trends per field
- Irrigation — irrigation events with volume, duration and automation rate
- Alerts — list of all alerts sorted by severity level
- Crop Cycles — Gantt chart of all crop cycles with planting dates and yield data

## Tech stack

- Python and Streamlit for the web dashboard
- PostgreSQL for the database (hosted on Neon.tech)
- Plotly for charts and visualizations
- LoRaWAN for IoT data transmission

## Database

The database has 9 tables and contains 2,161 sensor readings, 10 IoT devices across 6 fields, 14 irrigation events and 10 crop cycles.

## How to run
```bash
git clone https://github.com/okere-rafiatou/iot-agri-monitor.git
cd iot-agri-monitor
pip install -r requirements.txt
cd dashboard
streamlit run app.py
```

Set up your .env file with your PostgreSQL credentials before running.

## Demo login

Email: john.soh@agrifarm.com  
Password: admin123

## Author

Rafiatou Okere
