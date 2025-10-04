"""
Add reports table to match the provided schema
"""
from sqlalchemy import create_engine, text
from app.config import settings

def add_reports_table():
    """Add reports table to the database"""
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        # Create reports table
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS reports (
                report_id SERIAL PRIMARY KEY,
                generated_by UUID NOT NULL REFERENCES users(id),
                created_by UUID NOT NULL REFERENCES users(id),
                report_type VARCHAR(50) NOT NULL,
                period_start DATE NOT NULL,
                period_end DATE NOT NULL,
                file_path VARCHAR(255),
                created_at TIMESTAMP DEFAULT NOW()
            );
        """))
        
        # Create indexes
        conn.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_reports_generated_by 
            ON reports(generated_by);
        """))
        
        conn.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_reports_created_by 
            ON reports(created_by);
        """))
        
        conn.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_reports_period 
            ON reports(period_start, period_end);
        """))
        
        conn.commit()
        print("✅ Reports table created successfully!")

if __name__ == "__main__":
    add_reports_table()
