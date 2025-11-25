import asyncio
import httpx
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
import pandas as pd
import time
import json
import os

class OpenMeteoWeatherService:

    def __init__(self):
        self.base_url = "https://api.open-meteo.com/v1"
        self.historical_url = "https://archive-api.open-meteo.com/v1"

        self.last_request_time = 0
        self.min_request_interval = 10

        self.cache = {}
        self.cache_duration = 600

    async def get_current_weather(self, latitude: float, longitude: float) -> Dict:
        cache_key = f"weather_{latitude:.2f}_{longitude:.2f}"

        if cache_key in self.cache:
            cached_data, cached_time = self.cache[cache_key]
            if time.time() - cached_time < self.cache_duration:
                return cached_data

        current_time = time.time()
        time_since_last_request = current_time - self.last_request_time
        if time_since_last_request < self.min_request_interval:
            wait_time = self.min_request_interval - time_since_last_request
            print(f"Rate limiting: waiting {wait_time:.1f} seconds...")
            await asyncio.sleep(wait_time)
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "current": [
                "temperature_2m",
                "relative_humidity_2m",
                "wind_speed_10m",
                "wind_direction_10m",
                "surface_pressure",
                "precipitation"
            ],
            "hourly": [
                "temperature_2m",
                "relative_humidity_2m",
                "wind_speed_10m",
                "precipitation_probability"
            ],
            "daily": [
                "temperature_2m_max",
                "temperature_2m_min",
                "precipitation_sum",
                "wind_speed_10m_max"
            ],
            "timezone": "America/Los_Angeles",
            "forecast_days": 3
        }

        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.get(f"{self.base_url}/forecast", params=params)
                response.raise_for_status()
                data = response.json()

            self.last_request_time = time.time()

            processed_data = self._process_current_weather(data)
            self.cache[cache_key] = (processed_data, time.time())

            return processed_data

        except httpx.HTTPStatusError as e:
            if e.response.status_code == 429:
                print(f"Rate limit exceeded for {latitude}, {longitude}. Using fallback data.")
                return self._get_fallback_weather_data(latitude, longitude)
            else:
                print(f"Weather API HTTP error {e.response.status_code}: {e}")
                return self._get_fallback_weather_data(latitude, longitude)
        except Exception as e:
            print(f"Weather API error: {e}")
            return self._get_fallback_weather_data(latitude, longitude)

    async def get_historical_weather(
        self,
        latitude: float,
        longitude: float,
        start_date: str,
        end_date: str
    ) -> pd.DataFrame:
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "start_date": start_date,
            "end_date": end_date,
            "daily": [
                "temperature_2m_max",
                "temperature_2m_min",
                "temperature_2m_mean",
                "relative_humidity_2m_max",
                "relative_humidity_2m_min",
                "relative_humidity_2m_mean",
                "wind_speed_10m_max",
                "wind_speed_10m_mean",
                "surface_pressure_mean",
                "precipitation_sum",
                "et0_fao_evapotranspiration"
            ],
            "timezone": "America/Los_Angeles"
        }

        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.historical_url}/archive", params=params)
            response.raise_for_status()
            data = response.json()

        return self._process_historical_weather(data)

    def _process_current_weather(self, data: Dict) -> Dict:
        current = data.get("current", {})
        hourly = data.get("hourly", {})
        daily = data.get("daily", {})

        temp_f = self._celsius_to_fahrenheit(current.get("temperature_2m", 20))
        humidity = current.get("relative_humidity_2m", 50)
        wind_speed_mph = self._kmh_to_mph(current.get("wind_speed_10m", 0))

        precipitation = current.get("precipitation", 0)
        drought_code = self._calculate_drought_code(temp_f, humidity, precipitation)

        fwi = self._calculate_fire_weather_index(temp_f, humidity, wind_speed_mph, drought_code)

        red_flag_warning = self._check_red_flag_conditions(temp_f, humidity, wind_speed_mph)

        return {
            "temperature_f": temp_f,
            "temperature_c": current.get("temperature_2m", 20),
            "humidity": humidity,
            "wind_speed_mph": wind_speed_mph,
            "wind_speed_kmh": current.get("wind_speed_10m", 0),
            "wind_direction": current.get("wind_direction_10m", 0),
            "pressure": current.get("surface_pressure", 1013.25),
            "precipitation": precipitation,
            "drought_code": drought_code,
            "fire_weather_index": fwi,
            "red_flag_warning": red_flag_warning,
            "last_updated": datetime.now().isoformat(),
            "forecast": self._process_forecast(hourly, daily)
        }

    def _process_historical_weather(self, data: Dict) -> pd.DataFrame:
        daily = data.get("daily", {})

        df = pd.DataFrame({
            "date": pd.to_datetime(daily.get("time", [])),
            "temp_max_f": [self._celsius_to_fahrenheit(t) for t in daily.get("temperature_2m_max", [])],
            "temp_min_f": [self._celsius_to_fahrenheit(t) for t in daily.get("temperature_2m_min", [])],
            "temp_mean_f": [self._celsius_to_fahrenheit(t) for t in daily.get("temperature_2m_mean", [])],
            "humidity_max": daily.get("relative_humidity_2m_max", []),
            "humidity_min": daily.get("relative_humidity_2m_min", []),
            "humidity_mean": daily.get("relative_humidity_2m_mean", []),
            "wind_max_mph": [self._kmh_to_mph(w) for w in daily.get("wind_speed_10m_max", [])],
            "wind_mean_mph": [self._kmh_to_mph(w) for w in daily.get("wind_speed_10m_mean", [])],
            "pressure": daily.get("surface_pressure_mean", []),
            "precipitation": daily.get("precipitation_sum", []),
            "evapotranspiration": daily.get("et0_fao_evapotranspiration", [])
        })

        df["drought_code"] = df.apply(lambda row: self._calculate_drought_code(
            row["temp_mean_f"], row["humidity_mean"], row["precipitation"]
        ), axis=1)

        df["fire_weather_index"] = df.apply(lambda row: self._calculate_fire_weather_index(
            row["temp_mean_f"], row["humidity_mean"], row["wind_mean_mph"], row["drought_code"]
        ), axis=1)

        df["red_flag_conditions"] = df.apply(lambda row: self._check_red_flag_conditions(
            row["temp_max_f"], row["humidity_min"], row["wind_max_mph"]
        ), axis=1)

        return df

    def _process_forecast(self, hourly: Dict, daily: Dict) -> Dict:
        return {
            "next_24h_max_temp": max(hourly.get("temperature_2m", [20])[:24]) if hourly.get("temperature_2m") else 20,
            "next_24h_min_humidity": min(hourly.get("relative_humidity_2m", [50])[:24]) if hourly.get("relative_humidity_2m") else 50,
            "next_24h_max_wind": max(hourly.get("wind_speed_10m", [0])[:24]) if hourly.get("wind_speed_10m") else 0,
            "precipitation_probability": max(hourly.get("precipitation_probability", [0])[:24]) if hourly.get("precipitation_probability") else 0
        }

    def _celsius_to_fahrenheit(self, celsius: float) -> float:
        return (celsius * 9/5) + 32

    def _kmh_to_mph(self, kmh: float) -> float:
        return kmh * 0.621371

    def _calculate_drought_code(self, temp_f: float, humidity: float, precipitation: float) -> float:
        base_drought = max(0, (temp_f - 32) / 100)
        humidity_factor = max(0, (100 - humidity) / 100)
        precip_factor = max(0, 1 - (precipitation / 10))

        return min(100, (base_drought + humidity_factor + precip_factor) * 33.33)

    def _calculate_fire_weather_index(self, temp_f: float, humidity: float, wind_mph: float, drought_code: float) -> float:
        ffmc = max(0, min(100, 100 - humidity + (temp_f - 32) * 0.5))

        dmc = drought_code

        isi = max(0, ffmc * wind_mph * 0.05)

        bui = max(0, (dmc + drought_code) * 0.5)

        fwi = max(0, min(100, isi * bui * 0.01))

        return fwi

    def _check_red_flag_conditions(self, temp_f: float, humidity: float, wind_mph: float) -> bool:
        high_temp = temp_f >= 85
        low_humidity = humidity <= 20
        high_wind = wind_mph >= 25

        conditions_met = sum([high_temp, low_humidity, high_wind])
        return conditions_met >= 2

    def _get_fallback_weather_data(self, latitude: float, longitude: float) -> Dict:
        current_month = datetime.now().month

        if current_month in [6, 7, 8, 9]:
            temp_f = 85.0
            humidity = 30.0
            wind_speed_mph = 12.0
        elif current_month in [12, 1, 2]:
            temp_f = 65.0
            humidity = 60.0
            wind_speed_mph = 8.0
        else:
            temp_f = 75.0
            humidity = 45.0
            wind_speed_mph = 10.0

        if longitude > -118:
            temp_f += 10
            humidity -= 10
            wind_speed_mph += 3

        return {
            "temperature_f": temp_f,
            "temperature_c": (temp_f - 32) * 5/9,
            "humidity": max(10, humidity),
            "wind_speed_mph": wind_speed_mph,
            "wind_speed_kmh": wind_speed_mph / 0.621371,
            "wind_direction": 270,
            "pressure": 1013.25,
            "precipitation": 0.0,
            "drought_code": self._calculate_drought_code(temp_f, humidity, 0),
            "fire_weather_index": self._calculate_fire_weather_index(temp_f, humidity, wind_speed_mph, 50),
            "red_flag_warning": self._check_red_flag_conditions(temp_f, humidity, wind_speed_mph),
            "last_updated": datetime.now().isoformat(),
            "forecast": {
                "next_24h_max_temp": temp_f + 5,
                "next_24h_min_humidity": max(10, humidity - 10),
                "next_24h_max_wind": wind_speed_mph + 5,
                "precipitation_probability": 5 if current_month in [11, 12, 1, 2, 3] else 0
            },
            "data_source": "fallback_estimates"
        }

async def test_weather_service():
    service = OpenMeteoWeatherService()

    current = await service.get_current_weather(34.0194, -118.4912)
    print("Current weather:", current)

    end_date = datetime.now().strftime("%Y-%m-%d")
    start_date = (datetime.now() - timedelta(days=30)).strftime("%Y-%m-%d")

    historical = await service.get_historical_weather(34.0194, -118.4912, start_date, end_date)
    print("Historical data shape:", historical.shape)
    print("Historical data columns:", historical.columns.tolist())

if __name__ == "__main__":
    asyncio.run(test_weather_service())
