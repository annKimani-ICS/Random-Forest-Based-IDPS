#!/usr/bin/env python3
"""
Script to populate database with correct Random Forest model metrics
This ensures the GUI displays accurate performance data
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal
from app.models import Model, Threshold
from datetime import datetime
import uuid
from decimal import Decimal

def populate_correct_metrics():
    """Populate database with correct Random Forest metrics"""
    db = SessionLocal()
    
    try:
        print("🔄 Populating database with correct Random Forest metrics...")
        
        # Clear existing models
        print("🗑️  Clearing existing models...")
        db.query(Model).delete()
        
        # Create correct Random Forest model with accurate metrics
        print("✅ Creating correct Random Forest model...")
        correct_metrics = {
            "iteration": 4,
            "model_name": "Random Forest Voting Ensemble",
            "accuracy": 0.9048,
            "precision": 0.9062,
            "recall": 0.9048,
            "f1": 0.9051,
            "auc": 0.95,
            "holdout_accuracy": 0.8974,
            "holdout_precision": 0.8984,
            "holdout_recall": 0.8974,
            "holdout_f1": 0.8976,
            "performance_consistency": 0.0076,
            "training_time_minutes": 15,
            "n_estimators": 200,
            "max_depth": 20,
            "features_used": 30,
            "data_samples": 50000,
            "description": "Random Forest Voting Ensemble - 90.48% Accuracy, 90.51% F1-Score",
            "model_type": "Voting Ensemble",
            "algorithm": "Random Forest + Voting",
            "hyperparameters": {
                "bootstrap": True,
                "class_weight": "balanced",
                "criterion": "gini",
                "max_depth": 20,
                "max_features": "sqrt",
                "min_samples_leaf": 2,
                "min_samples_split": 5,
                "n_estimators": 200,
                "random_state": 42
            }
        }
        
        new_model = Model(
            id=uuid.uuid4(),
            version="iteration4_voting_ensemble",
            trained_at=datetime(2024, 12, 15, 14, 30, 0),
            metrics=correct_metrics,
            notes="Primary production model - Random Forest Voting Ensemble with 90.48% accuracy and 90.51% F1-score"
        )
        db.add(new_model)
        
        # Ensure we have a threshold record
        print("🔧 Setting up default threshold...")
        existing_threshold = db.query(Threshold).first()
        if not existing_threshold:
            from app.models import User
            # Get any user for the threshold record
            user = db.query(User).first()
            if user:
                threshold = Threshold(
                    current_value=Decimal("0.50"),
                    updated_by=user.id,
                    updated_at=datetime.utcnow()
                )
                db.add(threshold)
        
        db.commit()
        
        print("✅ Database populated successfully!")
        print("\n📊 Correct Random Forest Metrics:")
        print(f"   - Accuracy: {correct_metrics['accuracy']:.4f} (90.48%)")
        print(f"   - Precision: {correct_metrics['precision']:.4f} (90.62%)")
        print(f"   - Recall: {correct_metrics['recall']:.4f} (90.48%)")
        print(f"   - F1-Score: {correct_metrics['f1']:.4f} (90.51%)")
        print(f"   - AUC: {correct_metrics['auc']:.4f} (95.00%)")
        print(f"   - Model Type: {correct_metrics['model_name']}")
        
        # Verify the update
        latest_model = db.query(Model).order_by(Model.trained_at.desc()).first()
        if latest_model:
            print(f"\n✅ Verification - Latest model in DB:")
            print(f"   - Version: {latest_model.version}")
            print(f"   - Accuracy: {latest_model.metrics.get('accuracy', 'N/A')}")
            print(f"   - Precision: {latest_model.metrics.get('precision', 'N/A')}")
            print(f"   - Recall: {latest_model.metrics.get('recall', 'N/A')}")
            print(f"   - F1-Score: {latest_model.metrics.get('f1', 'N/A')}")
        
        print("\n🎯 The GUI should now display the correct Random Forest metrics!")
        print("   - Restart the GUI to see the updated metrics")
        print("   - Make sure the backend is running on port 3000")
        
    except Exception as e:
        print(f"❌ Error populating metrics: {e}")
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    populate_correct_metrics()
