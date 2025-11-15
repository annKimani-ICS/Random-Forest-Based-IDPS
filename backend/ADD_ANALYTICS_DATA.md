# Adding Analytics Dummy Data

To see the analytics charts with sample data, run one of these scripts:

## Quick Method (Recommended)

```bash
cd backend
python add_analytics_dummy_data.py
```

This script creates 50 alerts with:
- **Specific DDoS attack types**: DDoS TCP SYN Flood, DDoS UDP Flood, DDoS ICMP, etc.
- **Distributed over 7 days** for time series visualization
- **Common source IPs** for top IPs chart
- **Various statuses** (NEW, ACK, BLOCKED, CLOSED) for status distribution
- **Weighted distribution** for realistic chart display

## Alternative Method

```bash
cd backend
python populate_dummy_data.py
```

This also creates dummy data but includes model metrics updates.

## What You'll See

After running the script, refresh your dashboard to see:

1. **Attack Type Distribution** - Bar chart showing counts of each attack type
2. **Status Distribution** - Pie chart showing alert status breakdown
3. **Top Source IPs** - Horizontal bar chart of most active source IPs
4. **Alerts Over Time** - Line chart showing daily trends
5. **Summary Statistics** - Total, malicious, and benign counts

## Notes

- The script clears existing alerts before creating new ones
- Data is distributed over the last 7 days
- Attack types use the new specific identification system (DDoS TCP SYN Flood, etc.)

