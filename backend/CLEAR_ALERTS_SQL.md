# Quick Way to Clear Alerts

If you need to clear alerts, you can use PostgreSQL directly:

```bash
# Connect to PostgreSQL
sudo -u postgres psql ids_idps_db

# Then run this SQL command:
DELETE FROM alerts;

# Exit PostgreSQL
\q
```

Or as a one-liner:
```bash
sudo -u postgres psql ids_idps_db -c "DELETE FROM alerts;"
```

This will clear all alerts from the database immediately, no Python/venv needed.

