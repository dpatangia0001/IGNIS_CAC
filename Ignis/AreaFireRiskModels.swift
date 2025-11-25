import Foundation
import CoreLocation
import SwiftUI

enum FireRiskLevel: String, CaseIterable, Codable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case extreme = "Extreme"

    var color: String {
        switch self {
        case .low:
            return "#4CAF50"
        case .moderate:
            return "#FF9800"
        case .high:
            return "#FF5722"
        case .extreme:
            return "#F44336"
        }
    }

    var description: String {
        switch self {
        case .low:
            return "Low fire risk - Normal precautions recommended"
        case .moderate:
            return "Moderate fire risk - Stay alert and prepared"
        case .high:
            return "High fire risk - Exercise extreme caution"
        case .extreme:
            return "Extreme fire risk - Immediate action may be required"
        }
    }
}

struct RiskFactor: Identifiable, Codable {
    let id = UUID()
    let name: String
    let impact: Double
    let description: String
    let weight: Double
}

struct FireRiskPrediction: Identifiable, Codable {
    let id: UUID
    let location: CLLocationCoordinate2D
    let riskLevel: FireRiskLevel
    let riskScore: Double
    let confidence: Double
    let factors: [RiskFactor]
    let lastUpdated: Date
    let weatherImpact: String
    let recommendations: [String]

    init(id: UUID = UUID(), location: CLLocationCoordinate2D, riskLevel: FireRiskLevel, riskScore: Double, confidence: Double, factors: [RiskFactor], lastUpdated: Date, weatherImpact: String, recommendations: [String]) {
        self.id = id
        self.location = location
        self.riskLevel = riskLevel
        self.riskScore = riskScore
        self.confidence = confidence
        self.factors = factors
        self.lastUpdated = lastUpdated
        self.weatherImpact = weatherImpact
        self.recommendations = recommendations
    }

    enum CodingKeys: String, CodingKey {
        case id, riskLevel, riskScore, confidence, factors, lastUpdated, weatherImpact, recommendations
        case location
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        riskLevel = try container.decode(FireRiskLevel.self, forKey: .riskLevel)
        riskScore = try container.decode(Double.self, forKey: .riskScore)
        confidence = try container.decode(Double.self, forKey: .confidence)
        factors = try container.decode([RiskFactor].self, forKey: .factors)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        weatherImpact = try container.decode(String.self, forKey: .weatherImpact)
        recommendations = try container.decode([String].self, forKey: .recommendations)

        let locationData = try container.decode([String: Double].self, forKey: .location)
        location = CLLocationCoordinate2D(
            latitude: locationData["latitude"] ?? 0.0,
            longitude: locationData["longitude"] ?? 0.0
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(riskLevel, forKey: .riskLevel)
        try container.encode(riskScore, forKey: .riskScore)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(factors, forKey: .factors)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encode(weatherImpact, forKey: .weatherImpact)
        try container.encode(recommendations, forKey: .recommendations)

        let locationData = ["latitude": location.latitude, "longitude": location.longitude]
        try container.encode(locationData, forKey: .location)
    }
}

struct GeographicArea: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let displayName: String
    let center: CLLocationCoordinate2D
    let bounds: AreaBounds
    let population: Int
    let areaType: AreaType

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: GeographicArea, rhs: GeographicArea) -> Bool {
        return lhs.id == rhs.id
    }
}

struct AreaBounds {
    let northEast: CLLocationCoordinate2D
    let southWest: CLLocationCoordinate2D

    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude <= northEast.latitude &&
               coordinate.latitude >= southWest.latitude &&
               coordinate.longitude <= northEast.longitude &&
               coordinate.longitude >= southWest.longitude
    }
}

enum AreaType: String, CaseIterable {
    case neighborhood = "Neighborhood"
    case city = "City"
    case district = "District"
    case region = "Region"
    case wildland = "Wildland"
    case wildlandUrbanInterface = "Wildland-Urban Interface"

    var icon: String {
        switch self {
        case .neighborhood: return "house.fill"
        case .city: return "building.2.fill"
        case .district: return "map.fill"
        case .region: return "globe.americas.fill"
        case .wildland: return "tree.fill"
        case .wildlandUrbanInterface: return "flame.fill"
        }
    }
}

struct AreaFireRiskPrediction: Identifiable {
    let id = UUID()
    let area: GeographicArea
    let riskLevel: FireRiskLevel
    let riskScore: Double
    let confidence: Double
    let factors: [RiskFactor]
    let nearbyFires: [NearbyFireInfo]
    let weatherImpact: String
    let evacuationRoutes: [String]
    let shelterCount: Int
    let lastUpdated: Date

    var riskPercentage: Int {
        return Int(riskScore * 100)
    }

    var riskColor: Color {
        switch riskLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .extreme: return .red
        }
    }

    var alertMessage: String {
        switch riskLevel {
        case .low:
            return "Low fire risk in \(area.displayName). Continue normal activities."
        case .moderate:
            return "Moderate fire risk in \(area.displayName). Stay informed about conditions."
        case .high:
            return "High fire risk in \(area.displayName). Be prepared for evacuation."
        case .extreme:
            return "EXTREME fire risk in \(area.displayName). Evacuate immediately if ordered."
        }
    }
}

struct NearbyFireInfo: Identifiable {
    let id = UUID()
    let name: String
    let distance: Double
    let acres: Double
    let containment: Double
    let isActive: Bool
}

class GeographicAreasData {
    static let californiaAreas: [GeographicArea] = [

        GeographicArea(
            name: "san_francisco",
            displayName: "San Francisco",
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 37.8100, longitude: -122.3500),
                southWest: CLLocationCoordinate2D(latitude: 37.7000, longitude: -122.5100)
            ),
            population: 875000,
            areaType: .city
        ),

        GeographicArea(
            name: "oakland",
            displayName: "Oakland",
            center: CLLocationCoordinate2D(latitude: 37.8044, longitude: -122.2711),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 37.8500, longitude: -122.2000),
                southWest: CLLocationCoordinate2D(latitude: 37.7500, longitude: -122.3500)
            ),
            population: 440000,
            areaType: .city
        ),

        GeographicArea(
            name: "san_jose",
            displayName: "San Jose",
            center: CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 37.4000, longitude: -121.8000),
                southWest: CLLocationCoordinate2D(latitude: 37.2500, longitude: -122.0000)
            ),
            population: 1035000,
            areaType: .city
        ),

        GeographicArea(
            name: "napa",
            displayName: "Napa",
            center: CLLocationCoordinate2D(latitude: 38.2975, longitude: -122.2869),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 38.3500, longitude: -122.2000),
                southWest: CLLocationCoordinate2D(latitude: 38.2000, longitude: -122.4000)
            ),
            population: 80000,
            areaType: .city
        ),

        GeographicArea(
            name: "santa_rosa",
            displayName: "Santa Rosa",
            center: CLLocationCoordinate2D(latitude: 38.4404, longitude: -122.7141),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 38.5000, longitude: -122.6000),
                southWest: CLLocationCoordinate2D(latitude: 38.3500, longitude: -122.8000)
            ),
            population: 180000,
            areaType: .city
        ),

        GeographicArea(
            name: "sacramento",
            displayName: "Sacramento",
            center: CLLocationCoordinate2D(latitude: 38.5816, longitude: -121.4944),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 38.7000, longitude: -121.3000),
                southWest: CLLocationCoordinate2D(latitude: 38.4000, longitude: -121.7000)
            ),
            population: 525000,
            areaType: .city
        ),

        GeographicArea(
            name: "stockton",
            displayName: "Stockton",
            center: CLLocationCoordinate2D(latitude: 37.9577, longitude: -121.2908),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 38.0500, longitude: -121.2000),
                southWest: CLLocationCoordinate2D(latitude: 37.8500, longitude: -121.4000)
            ),
            population: 315000,
            areaType: .city
        ),

        GeographicArea(
            name: "modesto",
            displayName: "Modesto",
            center: CLLocationCoordinate2D(latitude: 37.6391, longitude: -120.9969),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 37.7000, longitude: -120.9000),
                southWest: CLLocationCoordinate2D(latitude: 37.5500, longitude: -121.1000)
            ),
            population: 220000,
            areaType: .city
        ),

        GeographicArea(
            name: "paradise",
            displayName: "Paradise",
            center: CLLocationCoordinate2D(latitude: 39.7596, longitude: -121.6219),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 39.8000, longitude: -121.5500),
                southWest: CLLocationCoordinate2D(latitude: 39.7000, longitude: -121.7000)
            ),
            population: 26000,
            areaType: .city
        ),

        GeographicArea(
            name: "fresno",
            displayName: "Fresno",
            center: CLLocationCoordinate2D(latitude: 36.7378, longitude: -119.7871),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 36.8500, longitude: -119.6500),
                southWest: CLLocationCoordinate2D(latitude: 36.6000, longitude: -119.9000)
            ),
            population: 545000,
            areaType: .city
        ),

        GeographicArea(
            name: "bakersfield",
            displayName: "Bakersfield",
            center: CLLocationCoordinate2D(latitude: 35.3733, longitude: -119.0187),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 35.4500, longitude: -118.9000),
                southWest: CLLocationCoordinate2D(latitude: 35.2500, longitude: -119.1500)
            ),
            population: 385000,
            areaType: .city
        ),

        GeographicArea(
            name: "monterey",
            displayName: "Monterey",
            center: CLLocationCoordinate2D(latitude: 36.6002, longitude: -121.8947),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 36.6500, longitude: -121.8000),
                southWest: CLLocationCoordinate2D(latitude: 36.5500, longitude: -122.0000)
            ),
            population: 30000,
            areaType: .city
        ),

        GeographicArea(
            name: "santa_barbara",
            displayName: "Santa Barbara",
            center: CLLocationCoordinate2D(latitude: 34.4208, longitude: -119.6982),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.5000, longitude: -119.6000),
                southWest: CLLocationCoordinate2D(latitude: 34.3000, longitude: -119.8000)
            ),
            population: 92000,
            areaType: .city
        ),

        GeographicArea(
            name: "los_angeles",
            displayName: "Los Angeles",
            center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.3000, longitude: -118.1000),
                southWest: CLLocationCoordinate2D(latitude: 33.7000, longitude: -118.6700)
            ),
            population: 4000000,
            areaType: .city
        ),

        GeographicArea(
            name: "santa_monica",
            displayName: "Santa Monica",
            center: CLLocationCoordinate2D(latitude: 34.0194, longitude: -118.4912),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.0500, longitude: -118.4600),
                southWest: CLLocationCoordinate2D(latitude: 33.9900, longitude: -118.5200)
            ),
            population: 93000,
            areaType: .city
        ),

        GeographicArea(
            name: "westwood",
            displayName: "Westwood",
            center: CLLocationCoordinate2D(latitude: 34.0689, longitude: -118.4452),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.0850, longitude: -118.4300),
                southWest: CLLocationCoordinate2D(latitude: 34.0500, longitude: -118.4600)
            ),
            population: 47000,
            areaType: .neighborhood
        ),

        GeographicArea(
            name: "beverly_hills",
            displayName: "Beverly Hills",
            center: CLLocationCoordinate2D(latitude: 34.0736, longitude: -118.4004),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.0900, longitude: -118.3800),
                southWest: CLLocationCoordinate2D(latitude: 34.0570, longitude: -118.4200)
            ),
            population: 34000,
            areaType: .city
        ),

        GeographicArea(
            name: "brentwood",
            displayName: "Brentwood",
            center: CLLocationCoordinate2D(latitude: 34.0619, longitude: -118.4717),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.0800, longitude: -118.4500),
                southWest: CLLocationCoordinate2D(latitude: 34.0400, longitude: -118.4900)
            ),
            population: 31000,
            areaType: .neighborhood
        ),

        GeographicArea(
            name: "hollywood",
            displayName: "Hollywood",
            center: CLLocationCoordinate2D(latitude: 34.0928, longitude: -118.3287),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.1200, longitude: -118.3000),
                southWest: CLLocationCoordinate2D(latitude: 34.0700, longitude: -118.3600)
            ),
            population: 61000,
            areaType: .district
        ),

        GeographicArea(
            name: "downtown_la",
            displayName: "Downtown LA",
            center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.0700, longitude: -118.2200),
                southWest: CLLocationCoordinate2D(latitude: 34.0300, longitude: -118.2700)
            ),
            population: 58000,
            areaType: .district
        ),

        GeographicArea(
            name: "malibu",
            displayName: "Malibu",
            center: CLLocationCoordinate2D(latitude: 34.0259, longitude: -118.7798),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.0700, longitude: -118.7000),
                southWest: CLLocationCoordinate2D(latitude: 33.9800, longitude: -118.8500)
            ),
            population: 13000,
            areaType: .city
        ),

        GeographicArea(
            name: "calabasas",
            displayName: "Calabasas",
            center: CLLocationCoordinate2D(latitude: 34.1378, longitude: -118.6606),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.1600, longitude: -118.6300),
                southWest: CLLocationCoordinate2D(latitude: 34.1100, longitude: -118.6900)
            ),
            population: 24000,
            areaType: .city
        ),

        GeographicArea(
            name: "topanga",
            displayName: "Topanga",
            center: CLLocationCoordinate2D(latitude: 34.0947, longitude: -118.6020),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.1200, longitude: -118.5700),
                southWest: CLLocationCoordinate2D(latitude: 34.0700, longitude: -118.6300)
            ),
            population: 8000,
            areaType: .neighborhood
        ),

        GeographicArea(
            name: "woodland_hills",
            displayName: "Woodland Hills",
            center: CLLocationCoordinate2D(latitude: 34.1681, longitude: -118.6059),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.1900, longitude: -118.5800),
                southWest: CLLocationCoordinate2D(latitude: 34.1500, longitude: -118.6300)
            ),
            population: 67000,
            areaType: .neighborhood
        ),

        GeographicArea(
            name: "anaheim",
            displayName: "Anaheim",
            center: CLLocationCoordinate2D(latitude: 33.8366, longitude: -117.9143),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 33.8700, longitude: -117.8800),
                southWest: CLLocationCoordinate2D(latitude: 33.8000, longitude: -117.9500)
            ),
            population: 352000,
            areaType: .city
        ),

        GeographicArea(
            name: "irvine",
            displayName: "Irvine",
            center: CLLocationCoordinate2D(latitude: 33.6846, longitude: -117.8265),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 33.7200, longitude: -117.7900),
                southWest: CLLocationCoordinate2D(latitude: 33.6500, longitude: -117.8600)
            ),
            population: 287000,
            areaType: .city
        ),

        GeographicArea(
            name: "huntington_beach",
            displayName: "Huntington Beach",
            center: CLLocationCoordinate2D(latitude: 33.6603, longitude: -117.9992),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 33.7000, longitude: -117.9500),
                southWest: CLLocationCoordinate2D(latitude: 33.6000, longitude: -118.0500)
            ),
            population: 200000,
            areaType: .city
        ),

        GeographicArea(
            name: "san_diego",
            displayName: "San Diego",
            center: CLLocationCoordinate2D(latitude: 32.7157, longitude: -117.1611),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 32.9000, longitude: -117.0000),
                southWest: CLLocationCoordinate2D(latitude: 32.5000, longitude: -117.3000)
            ),
            population: 1420000,
            areaType: .city
        ),

        GeographicArea(
            name: "escondido",
            displayName: "Escondido",
            center: CLLocationCoordinate2D(latitude: 33.1192, longitude: -117.0864),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 33.1500, longitude: -117.0500),
                southWest: CLLocationCoordinate2D(latitude: 33.0800, longitude: -117.1200)
            ),
            population: 152000,
            areaType: .city
        ),

        GeographicArea(
            name: "riverside",
            displayName: "Riverside",
            center: CLLocationCoordinate2D(latitude: 33.9533, longitude: -117.3962),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.0000, longitude: -117.3000),
                southWest: CLLocationCoordinate2D(latitude: 33.9000, longitude: -117.5000)
            ),
            population: 330000,
            areaType: .city
        ),

        GeographicArea(
            name: "san_bernardino",
            displayName: "San Bernardino",
            center: CLLocationCoordinate2D(latitude: 34.1083, longitude: -117.2898),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.1500, longitude: -117.2000),
                southWest: CLLocationCoordinate2D(latitude: 34.0500, longitude: -117.4000)
            ),
            population: 222000,
            areaType: .city
        ),

        GeographicArea(
            name: "palm_springs",
            displayName: "Palm Springs",
            center: CLLocationCoordinate2D(latitude: 33.8303, longitude: -116.5453),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 33.8700, longitude: -116.5000),
                southWest: CLLocationCoordinate2D(latitude: 33.7900, longitude: -116.6000)
            ),
            population: 48000,
            areaType: .city
        ),

        GeographicArea(
            name: "big_sur",
            displayName: "Big Sur",
            center: CLLocationCoordinate2D(latitude: 36.2704, longitude: -121.8081),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 36.4000, longitude: -121.7000),
                southWest: CLLocationCoordinate2D(latitude: 36.1000, longitude: -121.9000)
            ),
            population: 1800,
            areaType: .region
        ),

        GeographicArea(
            name: "lake_tahoe",
            displayName: "Lake Tahoe",
            center: CLLocationCoordinate2D(latitude: 39.0968, longitude: -120.0324),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 39.2000, longitude: -119.9000),
                southWest: CLLocationCoordinate2D(latitude: 38.9000, longitude: -120.2000)
            ),
            population: 23000,
            areaType: .region
        ),

        GeographicArea(
            name: "yosemite",
            displayName: "Yosemite Area",
            center: CLLocationCoordinate2D(latitude: 37.8651, longitude: -119.5383),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 38.0000, longitude: -119.4000),
                southWest: CLLocationCoordinate2D(latitude: 37.7000, longitude: -119.7000)
            ),
            population: 5000,
            areaType: .region
        ),

        GeographicArea(
            name: "redding",
            displayName: "Redding",
            center: CLLocationCoordinate2D(latitude: 40.5865, longitude: -122.3917),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 40.6500, longitude: -122.3000),
                southWest: CLLocationCoordinate2D(latitude: 40.5000, longitude: -122.5000)
            ),
            population: 95000,
            areaType: .city
        ),

        GeographicArea(
            name: "chico",
            displayName: "Chico",
            center: CLLocationCoordinate2D(latitude: 39.7285, longitude: -121.8375),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 39.8000, longitude: -121.7500),
                southWest: CLLocationCoordinate2D(latitude: 39.6500, longitude: -121.9000)
            ),
            population: 101000,
            areaType: .city
        ),

        GeographicArea(
            name: "shasta_trinity",
            displayName: "Shasta-Trinity National Forest",
            center: CLLocationCoordinate2D(latitude: 40.8000, longitude: -122.8000),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 41.2000, longitude: -122.0000),
                southWest: CLLocationCoordinate2D(latitude: 40.4000, longitude: -123.6000)
            ),
            population: 5000,
            areaType: .wildland
        ),

        GeographicArea(
            name: "mendocino_national_forest",
            displayName: "Mendocino National Forest",
            center: CLLocationCoordinate2D(latitude: 39.4000, longitude: -122.7000),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 39.8000, longitude: -122.3000),
                southWest: CLLocationCoordinate2D(latitude: 39.0000, longitude: -123.1000)
            ),
            population: 2000,
            areaType: .wildland
        ),

        GeographicArea(
            name: "lassen_national_forest",
            displayName: "Lassen National Forest",
            center: CLLocationCoordinate2D(latitude: 40.4000, longitude: -121.2000),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 40.8000, longitude: -120.8000),
                southWest: CLLocationCoordinate2D(latitude: 40.0000, longitude: -121.6000)
            ),
            population: 1000,
            areaType: .wildland
        ),

        GeographicArea(
            name: "plumas_national_forest",
            displayName: "Plumas National Forest",
            center: CLLocationCoordinate2D(latitude: 39.8000, longitude: -120.8000),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 40.2000, longitude: -120.4000),
                southWest: CLLocationCoordinate2D(latitude: 39.4000, longitude: -121.2000)
            ),
            population: 3000,
            areaType: .wildland
        ),

        GeographicArea(
            name: "eldorado_national_forest",
            displayName: "Eldorado National Forest",
            center: CLLocationCoordinate2D(latitude: 38.8000, longitude: -120.3000),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 39.2000, longitude: -119.9000),
                southWest: CLLocationCoordinate2D(latitude: 38.4000, longitude: -120.7000)
            ),
            population: 4000,
            areaType: .wildland
        ),

        GeographicArea(
            name: "stanislaus_national_forest",
            displayName: "Stanislaus National Forest",
            center: CLLocationCoordinate2D(latitude: 38.2000, longitude: -119.8000),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 38.6000, longitude: -119.4000),
                southWest: CLLocationCoordinate2D(latitude: 37.8000, longitude: -120.2000)
            ),
            population: 2500,
            areaType: .wildland
        ),

        GeographicArea(
            name: "sierra_national_forest",
            displayName: "Sierra National Forest",
            center: CLLocationCoordinate2D(latitude: 37.2000, longitude: -119.3000),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 37.6000, longitude: -118.9000),
                southWest: CLLocationCoordinate2D(latitude: 36.8000, longitude: -119.7000)
            ),
            population: 1500,
            areaType: .wildland
        ),

        GeographicArea(
            name: "sequoia_national_forest",
            displayName: "Sequoia National Forest",
            center: CLLocationCoordinate2D(latitude: 36.0000, longitude: -118.8000),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 36.4000, longitude: -118.4000),
                southWest: CLLocationCoordinate2D(latitude: 35.6000, longitude: -119.2000)
            ),
            population: 2000,
            areaType: .wildland
        ),

        GeographicArea(
            name: "los_padres_national_forest",
            displayName: "Los Padres National Forest",
            center: CLLocationCoordinate2D(latitude: 36.2000, longitude: -121.5000),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 36.8000, longitude: -121.0000),
                southWest: CLLocationCoordinate2D(latitude: 35.6000, longitude: -122.0000)
            ),
            population: 1000,
            areaType: .wildland
        ),

        GeographicArea(
            name: "ventana_wilderness",
            displayName: "Ventana Wilderness",
            center: CLLocationCoordinate2D(latitude: 36.3000, longitude: -121.6000),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 36.5000, longitude: -121.4000),
                southWest: CLLocationCoordinate2D(latitude: 36.1000, longitude: -121.8000)
            ),
            population: 100,
            areaType: .wildland
        ),

        GeographicArea(
            name: "angeles_national_forest",
            displayName: "Angeles National Forest",
            center: CLLocationCoordinate2D(latitude: 34.3000, longitude: -117.9000),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.7000, longitude: -117.5000),
                southWest: CLLocationCoordinate2D(latitude: 33.9000, longitude: -118.3000)
            ),
            population: 3000,
            areaType: .wildland
        ),

        GeographicArea(
            name: "san_bernardino_national_forest",
            displayName: "San Bernardino National Forest",
            center: CLLocationCoordinate2D(latitude: 34.2000, longitude: -116.9000),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.6000, longitude: -116.5000),
                southWest: CLLocationCoordinate2D(latitude: 33.8000, longitude: -117.3000)
            ),
            population: 4000,
            areaType: .wildland
        ),

        GeographicArea(
            name: "cleveland_national_forest",
            displayName: "Cleveland National Forest",
            center: CLLocationCoordinate2D(latitude: 33.4000, longitude: -117.0000),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 33.8000, longitude: -116.6000),
                southWest: CLLocationCoordinate2D(latitude: 33.0000, longitude: -117.4000)
            ),
            population: 2000,
            areaType: .wildland
        ),

        GeographicArea(
            name: "grass_valley",
            displayName: "Grass Valley",
            center: CLLocationCoordinate2D(latitude: 39.2189, longitude: -121.0610),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 39.3000, longitude: -121.0000),
                southWest: CLLocationCoordinate2D(latitude: 39.1000, longitude: -121.1500)
            ),
            population: 13000,
            areaType: .wildlandUrbanInterface
        ),

        GeographicArea(
            name: "auburn",
            displayName: "Auburn",
            center: CLLocationCoordinate2D(latitude: 38.8966, longitude: -121.0770),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 38.9500, longitude: -121.0000),
                southWest: CLLocationCoordinate2D(latitude: 38.8000, longitude: -121.1500)
            ),
            population: 14000,
            areaType: .wildlandUrbanInterface
        ),

        GeographicArea(
            name: "oroville",
            displayName: "Oroville",
            center: CLLocationCoordinate2D(latitude: 39.5138, longitude: -121.5564),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 39.6000, longitude: -121.5000),
                southWest: CLLocationCoordinate2D(latitude: 39.4000, longitude: -121.6500)
            ),
            population: 20000,
            areaType: .wildlandUrbanInterface
        ),

        GeographicArea(
            name: "calistoga",
            displayName: "Calistoga",
            center: CLLocationCoordinate2D(latitude: 38.5796, longitude: -122.5797),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 38.6500, longitude: -122.5000),
                southWest: CLLocationCoordinate2D(latitude: 38.5000, longitude: -122.7000)
            ),
            population: 5000,
            areaType: .wildlandUrbanInterface
        ),

        GeographicArea(
            name: "forestville",
            displayName: "Forestville",
            center: CLLocationCoordinate2D(latitude: 38.4741, longitude: -122.8897),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 38.5500, longitude: -122.8000),
                southWest: CLLocationCoordinate2D(latitude: 38.4000, longitude: -122.9500)
            ),
            population: 3000,
            areaType: .wildlandUrbanInterface
        ),

        GeographicArea(
            name: "altadena",
            displayName: "Altadena",
            center: CLLocationCoordinate2D(latitude: 34.1897, longitude: -118.1314),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.2500, longitude: -118.0500),
                southWest: CLLocationCoordinate2D(latitude: 34.1000, longitude: -118.2000)
            ),
            population: 42000,
            areaType: .wildlandUrbanInterface
        ),

        GeographicArea(
            name: "julian",
            displayName: "Julian",
            center: CLLocationCoordinate2D(latitude: 33.0786, longitude: -116.6025),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 33.1500, longitude: -116.5000),
                southWest: CLLocationCoordinate2D(latitude: 33.0000, longitude: -116.7000)
            ),
            population: 1500,
            areaType: .wildlandUrbanInterface
        ),

        GeographicArea(
            name: "mojave_national_preserve",
            displayName: "Mojave National Preserve",
            center: CLLocationCoordinate2D(latitude: 35.0000, longitude: -115.5000),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 35.4000, longitude: -115.0000),
                southWest: CLLocationCoordinate2D(latitude: 34.6000, longitude: -116.0000)
            ),
            population: 500,
            areaType: .wildland
        ),

        GeographicArea(
            name: "joshua_tree_area",
            displayName: "Joshua Tree Area",
            center: CLLocationCoordinate2D(latitude: 34.1342, longitude: -116.3117),
            bounds: AreaBounds(
                northEast: CLLocationCoordinate2D(latitude: 34.3000, longitude: -116.0000),
                southWest: CLLocationCoordinate2D(latitude: 33.9000, longitude: -116.6000)
            ),
            population: 8000,
            areaType: .wildlandUrbanInterface
        )
    ]

    static var losAngelesAreas: [GeographicArea] {
        return californiaAreas.filter { area in
            let lat = area.center.latitude
            let lon = area.center.longitude
            return lat >= 33.7 && lat <= 34.8 && lon >= -118.8 && lon <= -117.0
        }
    }

    static var priorityAreas: [GeographicArea] {
        let priorityNames = [
            "san_francisco", "oakland", "san_jose", "los_angeles", "santa_monica",
            "malibu", "calabasas", "topanga", "big_sur", "napa",
            "redding", "chico", "san_diego", "paradise", "grass_valley"
        ]
        return californiaAreas.filter { area in
            priorityNames.contains(area.name)
        }
    }

    static var allAreas: [GeographicArea] {
        return californiaAreas + gridAreas
    }

    static var gridAreas: [GeographicArea] {
        var gridPoints: [GeographicArea] = []

        let northLat = 42.0
        let southLat = 32.5
        let westLon = -124.4
        let eastLon = -114.1

        let gridSpacing = 0.5
        var lat = southLat
        var gridIndex = 1

        while lat <= northLat {
            var lon = westLon
            while lon <= eastLon {

                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let isAlreadyCovered = californiaAreas.contains { area in
                    let distance = CLLocation(latitude: area.center.latitude, longitude: area.center.longitude)
                        .distance(from: CLLocation(latitude: lat, longitude: lon))
                    return distance < 25000
                }

                if !isAlreadyCovered {

                    let areaType: AreaType = determineAreaType(for: coordinate)

                    gridPoints.append(GeographicArea(
                        name: "grid_\(gridIndex)",
                        displayName: "Grid Point \(gridIndex)",
                        center: coordinate,
                        bounds: AreaBounds(
                            northEast: CLLocationCoordinate2D(latitude: lat + 0.25, longitude: lon + 0.25),
                            southWest: CLLocationCoordinate2D(latitude: lat - 0.25, longitude: lon - 0.25)
                        ),
                        population: estimatePopulation(for: coordinate, areaType: areaType),
                        areaType: areaType
                    ))
                    gridIndex += 1
                }

                lon += gridSpacing
            }
            lat += gridSpacing
        }

        return gridPoints
    }

    private static func determineAreaType(for coordinate: CLLocationCoordinate2D) -> AreaType {
        let lat = coordinate.latitude
        let lon = coordinate.longitude

        if (lat > 36.0 && lat < 40.0 && lon > -121.0 && lon < -118.0) ||
           (lat > 40.0 && lat < 42.0 && lon > -122.0 && lon < -121.0) {
            return .wildland
        }

        if lat < 36.0 && lon > -118.0 {
            return .wildland
        }

        if lon < -121.0 || (lat > 34.0 && lat < 37.0 && lon > -119.0 && lon < -117.0) {
            return .wildlandUrbanInterface
        }

        if lat > 35.0 && lat < 40.0 && lon > -122.0 && lon < -119.0 {
            return .region
        }

        return .wildland
    }

    private static func estimatePopulation(for coordinate: CLLocationCoordinate2D, areaType: AreaType) -> Int {
        switch areaType {
        case .wildland:
            return Int.random(in: 0...500)
        case .wildlandUrbanInterface:
            return Int.random(in: 500...5000)
        case .region:
            return Int.random(in: 1000...10000)
        default:
            return Int.random(in: 100...1000)
        }
    }

    static func getAreaContaining(coordinate: CLLocationCoordinate2D) -> GeographicArea? {
        return allAreas.first { area in
            area.bounds.contains(coordinate)
        }
    }

    static func getAreasWithinRadius(center: CLLocationCoordinate2D, radiusKm: Double) -> [GeographicArea] {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)

        return allAreas.filter { area in
            let areaLocation = CLLocation(latitude: area.center.latitude, longitude: area.center.longitude)
            let distance = centerLocation.distance(from: areaLocation) / 1000.0
            return distance <= radiusKm
        }
    }
}
