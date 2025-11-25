import pandas as pd
import numpy as np
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, classification_report
from sklearn.model_selection import train_test_split, GridSearchCV, StratifiedKFold
from sklearn.preprocessing import StandardScaler, PolynomialFeatures
from sklearn.ensemble import RandomForestClassifier
from sklearn.utils.class_weight import compute_class_weight
import xgboost as xgb
from datetime import datetime
import json

class WildfireRiskPredictor:

    def __init__(self):
        self.models = {}
        self.scalers = {}
        self.feature_generators = {}

    def generate_enhanced_data(self, n_samples=10000):

        print(f"🔄 Generating {n_samples} enhanced wildfire risk samples...")

        regions = [
            {"name": "Paradise", "base_risk": 0.90, "lat": 39.76, "lon": -121.62, "elevation": 1800, "veg": "forest", "slope": 25, "aspect": "south"},
            {"name": "Malibu Canyon", "base_risk": 0.85, "lat": 34.03, "lon": -118.78, "elevation": 400, "veg": "chaparral", "slope": 30, "aspect": "south"},
            {"name": "Santa Rosa Hills", "base_risk": 0.80, "lat": 38.44, "lon": -122.71, "elevation": 300, "veg": "grassland", "slope": 20, "aspect": "southwest"},

            {"name": "Napa Wildlands", "base_risk": 0.75, "lat": 38.30, "lon": -122.29, "elevation": 500, "veg": "mixed", "slope": 15, "aspect": "west"},
            {"name": "Sonoma Interface", "base_risk": 0.70, "lat": 38.29, "lon": -122.87, "elevation": 200, "veg": "chaparral", "slope": 18, "aspect": "south"},
            {"name": "Big Sur", "base_risk": 0.75, "lat": 36.27, "lon": -121.81, "elevation": 600, "veg": "forest", "slope": 35, "aspect": "southwest"},

            {"name": "Riverside County", "base_risk": 0.60, "lat": 33.95, "lon": -117.40, "elevation": 250, "veg": "desert", "slope": 10, "aspect": "east"},
            {"name": "San Bernardino Mtns", "base_risk": 0.65, "lat": 34.24, "lon": -117.29, "elevation": 1200, "veg": "forest", "slope": 28, "aspect": "north"},
            {"name": "Ventura County", "base_risk": 0.58, "lat": 34.28, "lon": -119.29, "elevation": 150, "veg": "chaparral", "slope": 12, "aspect": "southwest"},

            {"name": "Central Valley", "base_risk": 0.40, "lat": 36.74, "lon": -119.79, "elevation": 100, "veg": "agricultural", "slope": 2, "aspect": "flat"},
            {"name": "Sacramento Suburbs", "base_risk": 0.45, "lat": 38.58, "lon": -121.49, "elevation": 50, "veg": "urban", "slope": 3, "aspect": "flat"},
            {"name": "Stockton Area", "base_risk": 0.42, "lat": 37.96, "lon": -121.29, "elevation": 8, "veg": "agricultural", "slope": 1, "aspect": "flat"},

            {"name": "San Francisco", "base_risk": 0.25, "lat": 37.77, "lon": -122.42, "elevation": 100, "veg": "urban", "slope": 8, "aspect": "west"},
            {"name": "San Diego Coast", "base_risk": 0.30, "lat": 32.72, "lon": -117.16, "elevation": 20, "veg": "urban", "slope": 5, "aspect": "west"},
            {"name": "Los Angeles Basin", "base_risk": 0.35, "lat": 34.05, "lon": -118.24, "elevation": 80, "veg": "urban", "slope": 4, "aspect": "flat"},
            {"name": "Oakland Hills", "base_risk": 0.55, "lat": 37.80, "lon": -122.18, "elevation": 400, "veg": "mixed", "slope": 20, "aspect": "east"},
        ]

        samples = []

        for i in range(n_samples):
            region = np.random.choice(regions)

            month = np.random.randint(1, 13)
            day_of_year = np.random.randint(1, 366)
            is_fire_season = month in [5, 6, 7, 8, 9, 10]
            is_peak_season = month in [7, 8, 9]
            is_shoulder_season = month in [5, 6, 10]

            sample = self._generate_enhanced_weather(region, month, is_fire_season, is_peak_season)

            fire_features = self._generate_fire_proximity_features(region, is_fire_season, is_peak_season)
            sample.update(fire_features)

            terrain_features = self._generate_terrain_features(region)
            sample.update(terrain_features)

            sample.update({
                'month': month,
                'day_of_year': day_of_year,
                'is_fire_season': int(is_fire_season),
                'is_peak_season': int(is_peak_season),
                'is_shoulder_season': int(is_shoulder_season),
                'days_since_rain': self._calculate_days_since_rain(month, region),
                'fire_season_progress': (month - 5) / 6 if is_fire_season else 0,
            })

            sample.update({
                'years_since_last_major_fire': np.random.exponential(8) + 1,
                'fire_return_interval': self._calculate_fire_return_interval(region),
                'suppression_difficulty': self._calculate_suppression_difficulty(region, sample),
                'evacuation_time_estimate': self._calculate_evacuation_time(region),
                'fuel_load_index': self._calculate_fuel_load(region, sample),
                'ignition_risk_sources': self._calculate_ignition_sources(region),
            })

            sample.update({
                'haines_index': self._calculate_haines_index(sample),
                'burning_index': self._calculate_burning_index(sample),
                'energy_release_component': self._calculate_erc(sample),
                'spread_component': self._calculate_spread_component(sample),
            })

            target = self._generate_enhanced_target(sample, region)
            sample['fire_risk_level'] = target
            sample['region_name'] = region['name']

            samples.append(sample)

        df = pd.DataFrame(samples)

        df = self._add_interaction_features(df)

        print(f"✅ Generated {len(df)} enhanced samples with {len(df.columns)} features")
        print(f"📊 Risk distribution: {df['fire_risk_level'].value_counts().sort_index().to_dict()}")

        return df

    def _generate_enhanced_weather(self, region, month, is_fire_season, is_peak_season):

        if region['veg'] in ['forest', 'chaparral'] and is_peak_season:
            temp_base = 95 + np.random.normal(0, 8)
            humidity_base = 12 + np.random.exponential(8)
            wind_base = 18 + np.random.exponential(6)
        elif region['veg'] in ['forest', 'chaparral'] and is_fire_season:
            temp_base = 85 + np.random.normal(0, 10)
            humidity_base = 20 + np.random.exponential(10)
            wind_base = 12 + np.random.exponential(5)
        elif region['veg'] == 'desert':
            temp_base = 105 + np.random.normal(0, 12)
            humidity_base = 8 + np.random.exponential(5)
            wind_base = 8 + np.random.exponential(4)
        else:
            temp_base = 75 + np.random.normal(0, 12)
            humidity_base = 35 + np.random.normal(0, 15)
            wind_base = 8 + np.random.exponential(4)

        temp_f = temp_base - (region['elevation'] * 0.003)
        humidity = max(5, min(95, humidity_base + (region['elevation'] * 0.01)))
        wind_speed_mph = max(0, wind_base + (region['elevation'] * 0.002))

        if region['lon'] < -121:
            temp_f -= 5
            humidity += 10
            wind_speed_mph += 3

        temp_c = (temp_f - 32) * 5/9
        vapor_pressure_deficit = self._calculate_vpd(temp_c, humidity)

        return {
            'temperature_f': temp_f,
            'temperature_c': temp_c,
            'humidity': humidity,
            'wind_speed_mph': wind_speed_mph,
            'vapor_pressure_deficit': vapor_pressure_deficit,
            'heat_index': self._calculate_heat_index(temp_f, humidity),
        }

    def _generate_fire_proximity_features(self, region, is_fire_season, is_peak_season):

        if region['base_risk'] > 0.7 and is_peak_season:
            fire_prob = 0.6
        elif region['base_risk'] > 0.5 and is_fire_season:
            fire_prob = 0.4
        elif region['base_risk'] > 0.3:
            fire_prob = 0.2
        else:
            fire_prob = 0.1

        if np.random.random() < fire_prob:
            num_fires = np.random.choice([1, 2, 3], p=[0.7, 0.25, 0.05])

            distances = []
            sizes = []
            containments = []
            ages = []

            for _ in range(num_fires):
                distance = np.random.pareto(1.5) * 2 + 0.5
                size = np.random.lognormal(6, 2)
                containment = np.random.beta(2, 3) * 100
                age_days = np.random.exponential(5)

                distances.append(distance)
                sizes.append(size)
                containments.append(containment)
                ages.append(age_days)

            return {
                'distance_to_nearest_fire': min(distances),
                'fire_size_nearby': max(sizes),
                'fire_containment_nearby': min(containments),
                'num_nearby_fires': num_fires,
                'total_fire_area': sum(sizes),
                'avg_fire_age_days': np.mean(ages),
                'fire_threat_index': self._calculate_fire_threat_index(distances, sizes, containments),
            }
        else:
            return {
                'distance_to_nearest_fire': np.random.uniform(50, 200),
                'fire_size_nearby': 0,
                'fire_containment_nearby': 100,
                'num_nearby_fires': 0,
                'total_fire_area': 0,
                'avg_fire_age_days': 999,
                'fire_threat_index': 0,
            }

    def _generate_terrain_features(self, region):
        return {
            'elevation': region['elevation'],
            'slope': region['slope'],
            'aspect_numeric': self._aspect_to_numeric(region['aspect']),
            'vegetation_type_numeric': self._vegetation_to_numeric(region['veg']),
            'topographic_position': self._calculate_topo_position(region),
            'distance_to_coast': abs(region['lon'] + 120) * 111,
            'distance_to_urban': self._calculate_distance_to_urban(region),
            'road_density': self._calculate_road_density(region),
        }

    def _generate_enhanced_target(self, sample, region):

        risk_score = region['base_risk']

        weather_risk = 0
        if sample['temperature_f'] > 100:
            weather_risk += 0.3
        elif sample['temperature_f'] > 90:
            weather_risk += 0.2
        elif sample['temperature_f'] > 80:
            weather_risk += 0.1

        if sample['humidity'] < 10:
            weather_risk += 0.4
        elif sample['humidity'] < 20:
            weather_risk += 0.3
        elif sample['humidity'] < 30:
            weather_risk += 0.2

        if sample['wind_speed_mph'] > 35:
            weather_risk += 0.3
        elif sample['wind_speed_mph'] > 25:
            weather_risk += 0.2
        elif sample['wind_speed_mph'] > 15:
            weather_risk += 0.1

        proximity_risk = 0
        if sample['distance_to_nearest_fire'] < 2:
            proximity_risk = 0.5
        elif sample['distance_to_nearest_fire'] < 5:
            proximity_risk = 0.4
        elif sample['distance_to_nearest_fire'] < 10:
            proximity_risk = 0.3
        elif sample['distance_to_nearest_fire'] < 20:
            proximity_risk = 0.2
        elif sample['distance_to_nearest_fire'] < 40:
            proximity_risk = 0.1

        if sample['num_nearby_fires'] > 1:
            proximity_risk *= 1.5

        terrain_risk = 0
        if sample['slope'] > 30:
            terrain_risk += 0.2
        elif sample['slope'] > 20:
            terrain_risk += 0.15
        elif sample['slope'] > 10:
            terrain_risk += 0.1

        if 135 <= sample['aspect_numeric'] <= 225:
            terrain_risk += 0.1

        temporal_risk = 0
        if sample['is_peak_season']:
            temporal_risk += 0.15
        elif sample['is_fire_season']:
            temporal_risk += 0.1

        if sample['days_since_rain'] > 30:
            temporal_risk += 0.15
        elif sample['days_since_rain'] > 14:
            temporal_risk += 0.1

        total_risk = risk_score + weather_risk + proximity_risk + terrain_risk + temporal_risk

        total_risk += np.random.normal(0, 0.03)
        total_risk = max(0, min(1, total_risk))

        if total_risk >= 0.80:
            return 3
        elif total_risk >= 0.60:
            return 2
        elif total_risk >= 0.40:
            return 1
        else:
            return 0

    def _add_interaction_features(self, df):

        df['temp_humidity_interaction'] = df['temperature_f'] * (100 - df['humidity']) / 100
        df['temp_wind_interaction'] = df['temperature_f'] * df['wind_speed_mph'] / 100
        df['humidity_wind_interaction'] = (100 - df['humidity']) * df['wind_speed_mph'] / 100
        df['weather_stress_index'] = (df['temperature_f'] - 32) * (100 - df['humidity']) * df['wind_speed_mph'] / 10000

        df['fire_size_distance_ratio'] = df['fire_size_nearby'] / (df['distance_to_nearest_fire'] + 1)
        df['fire_containment_urgency'] = (100 - df['fire_containment_nearby']) * df['fire_size_nearby'] / 100

        df['slope_wind_interaction'] = df['slope'] * df['wind_speed_mph'] / 100
        df['elevation_temp_interaction'] = df['elevation'] * df['temperature_f'] / 1000

        df['season_weather_risk'] = df['is_fire_season'] * df['weather_stress_index']
        df['peak_season_multiplier'] = df['is_peak_season'] * (df['temperature_f'] + df['wind_speed_mph']) / 100

        return df

    def _calculate_vpd(self, temp_c, humidity):
        es = 0.6108 * np.exp(17.27 * temp_c / (temp_c + 237.3))
        ea = es * humidity / 100
        return es - ea

    def _calculate_heat_index(self, temp_f, humidity):
        if temp_f < 80:
            return temp_f

        hi = (-42.379 + 2.04901523 * temp_f + 10.14333127 * humidity
              - 0.22475541 * temp_f * humidity - 6.83783e-3 * temp_f**2
              - 5.481717e-2 * humidity**2 + 1.22874e-3 * temp_f**2 * humidity
              + 8.5282e-4 * temp_f * humidity**2 - 1.99e-6 * temp_f**2 * humidity**2)

        return max(temp_f, hi)

    def _aspect_to_numeric(self, aspect):
        aspects = {
            'north': 0, 'northeast': 45, 'east': 90, 'southeast': 135,
            'south': 180, 'southwest': 225, 'west': 270, 'northwest': 315,
            'flat': 0
        }
        return aspects.get(aspect, 0)

    def _vegetation_to_numeric(self, veg):
        veg_risk = {
            'urban': 1, 'agricultural': 2, 'grassland': 3,
            'mixed': 4, 'desert': 5, 'chaparral': 6, 'forest': 7
        }
        return veg_risk.get(veg, 3)

    def _calculate_days_since_rain(self, month, region):
        if month in [6, 7, 8, 9]:
            return np.random.exponential(45) + 10
        elif month in [11, 12, 1, 2, 3]:
            return np.random.exponential(5) + 1
        else:
            return np.random.exponential(20) + 5

    def _calculate_fire_threat_index(self, distances, sizes, containments):
        threat = 0
        for d, s, c in zip(distances, sizes, containments):
            fire_threat = (s * (100 - c)) / (d**2 + 1)
            threat += fire_threat
        return min(100, threat / 1000)

    def _calculate_topo_position(self, region):
        return region['elevation'] / 100

    def _calculate_distance_to_urban(self, region):
        return 50 if region['veg'] == 'urban' else np.random.uniform(5, 100)

    def _calculate_road_density(self, region):
        return 10 if region['veg'] == 'urban' else np.random.uniform(0.1, 5)

    def _calculate_fire_return_interval(self, region):
        return 20 if region['base_risk'] > 0.7 else 50

    def _calculate_suppression_difficulty(self, region, sample):
        return (region['slope'] + sample['wind_speed_mph']) / 10

    def _calculate_evacuation_time(self, region):
        return 30 if region['veg'] == 'urban' else 120

    def _calculate_fuel_load(self, region, sample):
        base_fuel = {'forest': 8, 'chaparral': 7, 'grassland': 5, 'mixed': 6, 'desert': 3, 'agricultural': 2, 'urban': 1}
        return base_fuel.get(region['veg'], 5) + sample['days_since_rain'] / 30

    def _calculate_ignition_sources(self, region):
        return 5 if region['veg'] == 'urban' else 2

    def _calculate_haines_index(self, sample):
        return min(6, (sample['temperature_f'] - 32) / 20 + sample['wind_speed_mph'] / 10)

    def _calculate_burning_index(self, sample):
        return min(100, sample['temperature_f'] * (100 - sample['humidity']) / 100)

    def _calculate_erc(self, sample):
        return min(100, sample['temperature_f'] * sample['wind_speed_mph'] / 10)

    def _calculate_spread_component(self, sample):
        return min(100, sample['wind_speed_mph'] * (100 - sample['humidity']) / 100)

    def train_enhanced_model(self, data):

        print("🚀 Training enhanced model for 85%+ performance...")

        feature_columns = [col for col in data.columns if col not in ['fire_risk_level', 'region_name']]
        X = data[feature_columns]
        y = data['fire_risk_level']

        print(f"📊 Training with {len(feature_columns)} features on {len(data)} samples")

        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )

        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)

        class_weights = compute_class_weight('balanced', classes=np.unique(y_train), y=y_train)
        class_weight_dict = {i: weight for i, weight in enumerate(class_weights)}

        print(f"🎯 Class weights: {class_weight_dict}")

        print("🔧 Tuning XGBoost hyperparameters...")

        xgb_param_grid = {
            'n_estimators': [200, 300, 500],
            'max_depth': [6, 8, 10],
            'learning_rate': [0.05, 0.1, 0.15],
            'subsample': [0.8, 0.9, 1.0],
            'colsample_bytree': [0.8, 0.9, 1.0],
            'min_child_weight': [1, 3, 5]
        }

        xgb_param_grid_small = {
            'n_estimators': [300, 500],
            'max_depth': [8, 10],
            'learning_rate': [0.05, 0.1],
            'subsample': [0.9],
            'colsample_bytree': [0.9],
        }

        xgb_model = xgb.XGBClassifier(
            random_state=42,
            eval_metric='mlogloss',
            class_weight=class_weight_dict
        )

        xgb_grid = GridSearchCV(
            xgb_model, xgb_param_grid_small,
            cv=3, scoring='f1_weighted', n_jobs=-1, verbose=1
        )

        xgb_grid.fit(X_train_scaled, y_train)
        best_xgb = xgb_grid.best_estimator_

        print(f"✅ Best XGBoost params: {xgb_grid.best_params_}")

        print("🌲 Training Random Forest...")
        rf_model = RandomForestClassifier(
            n_estimators=500,
            max_depth=15,
            min_samples_split=5,
            min_samples_leaf=2,
            class_weight='balanced',
            random_state=42,
            n_jobs=-1
        )
        rf_model.fit(X_train_scaled, y_train)

        self.models = {
            'xgboost': best_xgb,
            'random_forest': rf_model
        }
        self.scalers['main'] = scaler

        xgb_pred = best_xgb.predict(X_test_scaled)
        xgb_proba = best_xgb.predict_proba(X_test_scaled)

        rf_pred = rf_model.predict(X_test_scaled)
        rf_proba = rf_model.predict_proba(X_test_scaled)

        ensemble_proba = 0.7 * xgb_proba + 0.3 * rf_proba
        ensemble_pred = np.argmax(ensemble_proba, axis=1)

        results = {}

        for name, y_pred in [('XGBoost', xgb_pred), ('RandomForest', rf_pred), ('Ensemble', ensemble_pred)]:
            results[name] = {
                'accuracy': accuracy_score(y_test, y_pred),
                'precision_weighted': precision_score(y_test, y_pred, average='weighted', zero_division=0),
                'recall_weighted': recall_score(y_test, y_pred, average='weighted', zero_division=0),
                'f1_weighted': f1_score(y_test, y_pred, average='weighted', zero_division=0),
                'precision_macro': precision_score(y_test, y_pred, average='macro', zero_division=0),
                'recall_macro': recall_score(y_test, y_pred, average='macro', zero_division=0),
                'f1_macro': f1_score(y_test, y_pred, average='macro', zero_division=0),
            }

        feature_importance = dict(zip(feature_columns, best_xgb.feature_importances_))
        results['feature_importance'] = {k: float(v) for k, v in sorted(feature_importance.items(), key=lambda x: x[1], reverse=True)}

        results['predictions'] = {
            'y_true': y_test.tolist(),
            'y_pred_ensemble': ensemble_pred.tolist(),
            'y_proba_ensemble': ensemble_proba.tolist()
        }

        print("✅ Enhanced model training completed!")

        return results, X_test, y_test, ensemble_pred

def main():
    print("🚀 Enhanced XGBoost Model - Targeting 85%+ Performance")
    print("="*60)

    predictor = WildfireRiskPredictor()

    data = predictor.generate_enhanced_data(n_samples=15000)

    results, X_test, y_test, y_pred = predictor.train_enhanced_model(data)

    print("\n" + "="*60)
    print("📊 ENHANCED MODEL PERFORMANCE RESULTS")
    print("="*60)

    for model_name, metrics in results.items():
        if model_name == 'feature_importance' or model_name == 'predictions':
            continue

        print(f"\n🤖 {model_name.upper()} MODEL:")
        print(f"  🎯 Accuracy:           {metrics['accuracy']:.4f} ({metrics['accuracy']*100:.2f}%)")
        print(f"  🎯 Precision (Weighted): {metrics['precision_weighted']:.4f} ({metrics['precision_weighted']*100:.2f}%)")
        print(f"  🎯 Recall (Weighted):    {metrics['recall_weighted']:.4f} ({metrics['recall_weighted']*100:.2f}%)")
        print(f"  🎯 F1-Score (Weighted):  {metrics['f1_weighted']:.4f} ({metrics['f1_weighted']*100:.2f}%)")
        print(f"  📊 Precision (Macro):    {metrics['precision_macro']:.4f} ({metrics['precision_macro']*100:.2f}%)")
        print(f"  📊 Recall (Macro):       {metrics['recall_macro']:.4f} ({metrics['recall_macro']*100:.2f}%)")
        print(f"  📊 F1-Score (Macro):     {metrics['f1_macro']:.4f} ({metrics['f1_macro']*100:.2f}%)")

        if (metrics['accuracy'] >= 0.85 and
            metrics['precision_weighted'] >= 0.85 and
            metrics['recall_weighted'] >= 0.85):
            print(f"  ✅ TARGET ACHIEVED! All metrics ≥ 85%")
        else:
            print(f"  ⚠️  Target not fully achieved")

    print(f"\n🎯 TOP 10 MOST IMPORTANT FEATURES:")
    for i, (feature, importance) in enumerate(list(results['feature_importance'].items())[:10]):
        feature_name = feature.replace('_', ' ').title()
        print(f"  {i+1:2d}. {feature_name:<30}: {importance:.4f}")

    class_names = ['Low', 'Moderate', 'High', 'Extreme']
    print(f"\n📋 DETAILED CLASSIFICATION REPORT (Ensemble):")
    print(classification_report(y_test, y_pred, target_names=class_names))

    with open('enhanced_model_results.json', 'w') as f:
        json.dump(results, f, indent=2, default=str)

    print(f"\n💾 Results saved to 'enhanced_model_results.json'")

    return results

if __name__ == "__main__":
    results = main()
