# 🔥 Ignis - Wildfire Safety Application

A comprehensive iOS application for wildfire prediction, safety, and education. Built with SwiftUI and powered by machine learning to help communities stay safe during wildfire season.

## 📱 Features

- **Real-time Wildfire Map**: Track active wildfires with live data from CAL FIRE and NASA FIRMS
- **Fire Risk Prediction**: ML-powered risk assessment for different geographic areas
- **WildSafe Academy**: Interactive educational modules with quizzes and flashcards
- **Emergency Resources**: Find nearby shelters, evacuation information, and safety guidelines
- **AI Chatbot**: Get expert answers to wildfire safety questions
- **Mental Health Support**: Guided breathing exercises and wellness resources
- **Legislative Updates**: Stay informed about wildfire-related policies

## 🛠️ Tech Stack

**iOS App:**
- SwiftUI
- CoreLocation & MapKit
- Supabase (Authentication & Cloud Storage)
- UserNotifications

**Backend:**
- Python FastAPI
- XGBoost ML Model
- OpenMeteo Weather API

## 📋 Prerequisites

### For iOS Development:
- macOS (Ventura or later recommended)
- Xcode 15.0 or later
- iOS 17.0+ device or simulator
- Apple Developer account (for physical device testing)

### For ML Backend:
- Python 3.8 or later
- pip package manager

## 🚀 Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/areenjain09/CAC_IGNIS.git
cd CAC_IGNIS
```

### 2. Set Up the ML Backend

Navigate to the backend directory and install dependencies:

```bash
cd ml_backend
pip install -r requirements.txt
```

Create a `requirements.txt` file if it doesn't exist:

```txt
fastapi
uvicorn
joblib
numpy
pandas
scikit-learn
xgboost
requests
```

Start the backend server:

```bash
python start_server.py
```

The API will run on `http://localhost:8000`

**Note:** You'll need to train or provide the ML model files:
- `enhanced_wildfire_model.joblib`
- `enhanced_model_scalers.joblib`

### 3. Configure the iOS App

#### a. Open the Project in Xcode

```bash
cd ..
open Ignis.xcodeproj
```

#### b. Install Swift Dependencies

The project uses Swift Package Manager. Dependencies should resolve automatically, but if needed:
- Go to **File → Packages → Resolve Package Versions**

Required packages (defined in `Package.swift`):
- Supabase SDK
- Auth (for authentication)
- PostgREST (for database)
- Storage (for file storage)

#### c. Configure API Keys

**Important:** The app uses several external APIs. You'll need to add your own API keys.

Create a new file `Ignis/Config.swift`:

```swift
enum Config {
    static let deepSeekAPIKey = "YOUR_DEEPSEEK_API_KEY"
    static let geminiAPIKey = "YOUR_GEMINI_API_KEY"
    
    static let supabaseURL = "YOUR_SUPABASE_URL"
    static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
}
```

Then update the service files to use these keys instead of hardcoded values:
- `DeepSeekService.swift`
- `GeminiService.swift`
- `SupabaseService.swift`

#### d. Update Backend URL

If running the ML backend on localhost, ensure your device/simulator can reach it:

- **Simulator:** Use `http://localhost:8000`
- **Physical Device:** Use your Mac's local IP address (e.g., `http://192.168.1.XXX:8000`)

Update the URL in `EnhancedFireRiskService.swift`:

```swift
private let baseURL = "http://YOUR_IP_ADDRESS:8000"
```

### 4. Build and Run

1. Select your target device (simulator or physical device)
2. Press **Cmd + R** or click the Play button
3. Grant location permissions when prompted
4. Explore the app!

## 📱 Running on a Physical Device

1. Connect your iPhone/iPad via USB
2. In Xcode, select your device from the device menu
3. Go to **Signing & Capabilities** tab
4. Select your Apple Developer team
5. Change the bundle identifier if needed
6. Build and run

**Note:** You may need to trust the developer certificate on your device:
- Settings → General → VPN & Device Management → Trust

## 🗂️ Project Structure

```
Ignis/
├── Ignis/                          # Main iOS app source code
│   ├── IgnisApp.swift             # App entry point
│   ├── LandingPageView.swift     # Welcome screen
│   ├── HomePageView.swift        # Main dashboard
│   ├── WildfireMap.swift         # Live wildfire tracking
│   ├── AreaFireRiskMapView.swift # ML risk predictions
│   ├── EducationView.swift       # Learning modules
│   ├── ResourcesView.swift       # Emergency resources
│   ├── WildfireChatbotView.swift # AI assistant
│   ├── MentalHelpView.swift      # Wellness support
│   ├── Services/
│   │   ├── FireDataService.swift
│   │   ├── EnhancedFireRiskService.swift
│   │   ├── SupabaseService.swift
│   │   ├── AuthService.swift
│   │   ├── DeepSeekService.swift
│   │   └── ... (other services)
│   └── Models/
│       ├── CALFireIncident.swift
│       ├── AreaFireRiskModels.swift
│       └── ... (other models)
├── ml_backend/                     # Python ML backend
│   ├── production_api.py          # FastAPI server
│   ├── enhanced_model.py          # ML model implementation
│   ├── weather_service.py         # Weather data integration
│   └── start_server.py            # Server startup script
├── IgnisTests/                     # Unit tests
└── IgnisUITests/                   # UI tests
```

## ⚠️ Disclaimer

This app provides information and predictions for educational purposes. Always follow official guidance from local authorities and emergency services during wildfire events.

---
