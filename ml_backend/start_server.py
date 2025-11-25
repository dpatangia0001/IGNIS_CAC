import sys
import os
import subprocess
import asyncio
from pathlib import Path

def check_dependencies():
    try:
        import fastapi
        import uvicorn
        import pandas
        import numpy
        import sklearn
        import xgboost
        import requests
        import joblib
        print("✅ All dependencies are installed")
        return True
    except ImportError as e:
        print(f"❌ Missing dependency: {e}")
        print("Please run: pip install -r requirements.txt")
        return False

def check_model_files():
    model_files = [
        'enhanced_wildfire_model.joblib',
        'enhanced_model_scalers.joblib',
        'enhanced_model_results.json'
    ]

    missing_files = []
    for file in model_files:
        if not Path(file).exists():
            missing_files.append(file)

    if missing_files:
        print(f"⚠️  Model files not found: {missing_files}")
        print("The model will be trained automatically on first request.")
        return False
    else:
        print("✅ All model files found")
        return True

def start_server():
    print("🚀 Starting Ignis Enhanced Wildfire Risk Prediction API...")
    print("📊 Model: Enhanced Ensemble (XGBoost + Random Forest)")
    print("🎯 Accuracy: 94%+")
    print("🌤️  Weather: Open-Meteo API")
    print("🔗 URL: http://localhost:8000")
    print("📖 Docs: http://localhost:8000/docs")
    print("-" * 60)

    try:
        subprocess.run([
            sys.executable, "-m", "uvicorn",
            "production_api:app",
            "--host", "0.0.0.0",
            "--port", "8000",
            "--reload",
            "--log-level", "info"
        ], check=True)
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"❌ Server failed to start: {e}")

def main():
    print("🔥 Ignis Enhanced Wildfire Risk Prediction API")
    print("=" * 60)

    if not check_dependencies():
        sys.exit(1)

    check_model_files()

    start_server()

if __name__ == "__main__":
    main()
