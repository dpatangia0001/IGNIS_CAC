import SwiftUI
import CoreLocation

struct CALFireIncident: Identifiable, Codable, Hashable {
    var id = UUID()
    let name: String
    let acresBurned: Double
    let percentContained: Double
    let isActive: Bool
    let startedDate: String
    let county: String
    let location: String
    let latitude: Double
    let longitude: Double
    let url: String

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var intensityLevel: Int {
        if acresBurned > 10000 { return 3 }
        else if acresBurned > 1000 { return 2 }
        else if acresBurned > 100 { return 1 }
        else { return 0 }
    }

    var statusColor: String {
        if isActive {
            return "wsRed"
        } else {
            return "wsOrange"
        }
    }

    var statusText: String {
        if isActive {
            return "ACTIVE"
        } else {
            return "CONTAINED"
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CALFireIncident, rhs: CALFireIncident) -> Bool {
        return lhs.id == rhs.id
    }
}

let calFireIncidents: [CALFireIncident] = [
    CALFireIncident(
        name: "Green Fire",
        acresBurned: 19022.0,
        percentContained: 96.0,
        isActive: true,
        startedDate: "2025-07-01",
        county: "Shasta",
        location: "North of the Pit River, Shasta",
        latitude: 40.834939,
        longitude: -122.094146,
        url: "https://www.fire.ca.gov/incidents/2025/7/1/green-fire/"
    ),
    CALFireIncident(
        name: "Marble Complex Fire",
        acresBurned: 747.0,
        percentContained: 90.0,
        isActive: true,
        startedDate: "2025-07-03",
        county: "Siskiyou",
        location: "Marble Mountain Wilderness",
        latitude: 41.52404,
        longitude: -123.13222,
        url: "https://www.fire.ca.gov/incidents/2025/7/3/marble-complex-fire/"
    ),
    CALFireIncident(
        name: "Orleans Complex ",
        acresBurned: 21489.0,
        percentContained: 80.0,
        isActive: true,
        startedDate: "2025-07-09",
        county: "Del Norte, Siskiyou",
        location: "10 miles East of Orleans ",
        latitude: 41.32555556,
        longitude: -123.41777778,
        url: "https://www.fire.ca.gov/incidents/2025/7/9/orleans-complex/"
    ),
    CALFireIncident(
        name: "Medicine Fire",
        acresBurned: 263.0,
        percentContained: 85.0,
        isActive: true,
        startedDate: "2025-07-27",
        county: "Mendocino",
        location: "Rifle Range Road north of Refuse Road, Covelo, Mendocino County, CA.  ",
        latitude: 39.831628,
        longitude: -123.267618,
        url: "https://www.fire.ca.gov/incidents/2025/7/27/medicine-fire/"
    ),
    CALFireIncident(
        name: "Lassen Fire",
        acresBurned: 51.0,
        percentContained: 85.0,
        isActive: true,
        startedDate: "2025-08-01",
        county: "Tehama",
        location: "Tehama Vina Road & Champlin Slough, Los Molinos",
        latitude: 40.028565,
        longitude: -122.086035,
        url: "https://www.fire.ca.gov/incidents/2025/8/1/lassen-fire/"
    ),
    CALFireIncident(
        name: "Howards Fire",
        acresBurned: 100.0,
        percentContained: 45.0,
        isActive: true,
        startedDate: "2025-07-31",
        county: "Modoc",
        location: "Highway 139 and Loveness Road, Ambrose",
        latitude: 41.48008,
        longitude: -120.957447,
        url: "https://www.fire.ca.gov/incidents/2025/7/31/howards-fire/"
    ),
    CALFireIncident(
        name: "1-4 Fire",
        acresBurned: 259.6,
        percentContained: 25.0,
        isActive: true,
        startedDate: "2025-07-31",
        county: "Lassen",
        location: "Paiute Lane and Peak Road, Susanville",
        latitude: 40.445172,
        longitude: -120.656672,
        url: "https://www.fire.ca.gov/incidents/2025/7/31/1-4-fire/"
    ),
    CALFireIncident(
        name: "4-8 Fire",
        acresBurned: 25.0,
        percentContained: 0.0,
        isActive: true,
        startedDate: "2025-08-01",
        county: "Modoc",
        location: "Kearny Road & Carson Road, California Pines",
        latitude: 41.319441,
        longitude: -120.747715,
        url: "https://www.fire.ca.gov/incidents/2025/8/1/4-8-fire/"
    ),
    CALFireIncident(
        name: "Gifford Fire ",
        acresBurned: 30519.0,
        percentContained: 5.0,
        isActive: true,
        startedDate: "2025-08-01",
        county: "San Luis Obispo, Santa Barbara",
        location: "Highway 166 Northeast of Santa Maria",
        latitude: 35.102947,
        longitude: -120.116814,
        url: "https://www.fire.ca.gov/incidents/2025/8/1/gifford-fire/"
    ),
    CALFireIncident(
        name: "Donovan Fire",
        acresBurned: 30.0,
        percentContained: 0.0,
        isActive: true,
        startedDate: "2025-08-02",
        county: "San Luis Obispo",
        location: "La Panza Road & Little Farm Road, Creston",
        latitude: 35.527328,
        longitude: -120.508946,
        url: "https://www.fire.ca.gov/incidents/2025/8/2/donovan-fire/"
    ),
    CALFireIncident(
        name: "Fremont Fire",
        acresBurned: 26.3,
        percentContained: 0.0,
        isActive: true,
        startedDate: "2025-08-02",
        county: "San Bernardino",
        location: "Near Fremontia Road and Mesquite Road",
        latitude: 34.429401,
        longitude: -117.653566,
        url: "https://www.fire.ca.gov/incidents/2025/8/2/fremont-fire/"
    ),
    CALFireIncident(
        name: "Radar Fire ",
        acresBurned: 15.0,
        percentContained: 0.0,
        isActive: true,
        startedDate: "2025-08-02",
        county: "Modoc",
        location: "Southwest of Lone Pine Lake",
        latitude: 41.7203467,
        longitude: -121.1305479,
        url: "https://www.fire.ca.gov/incidents/2025/8/2/radar-fire/"
    ),
    CALFireIncident(
        name: "Oak Fire",
        acresBurned: 45.9,
        percentContained: 0.0,
        isActive: true,
        startedDate: "2025-08-02",
        county: "Riverside",
        location: "Unknown / TBD",
        latitude: 34.003628,
        longitude: -117.162599,
        url: "https://www.fire.ca.gov/incidents/2025/8/2/oak-fire/"
    ),
    CALFireIncident(
        name: "Willow Fire",
        acresBurned: 31.5,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-19",
        county: "Madera",
        location: "At Road 600 and Road 603, Willow Creek",
        latitude: 37.118,
        longitude: -119.932289,
        url: "https://www.fire.ca.gov/incidents/2025/7/19/willow-fire/"
    ),
    CALFireIncident(
        name: "Pala Fire",
        acresBurned: 7.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-19",
        county: "San Diego",
        location: "Highway 76 and Couser Canyon Road, Pala Mesa",
        latitude: 33.342918,
        longitude: -117.114678,
        url: "https://www.fire.ca.gov/incidents/2025/7/19/pala-fire/"
    ),
    CALFireIncident(
        name: "Coulter Fire",
        acresBurned: 24.9,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-19",
        county: "El Dorado",
        location: "4200 block of Coulter Lane in Latrobe, El Dorado County",
        latitude: 38.55184,
        longitude: -121.004153,
        url: "https://www.fire.ca.gov/incidents/2025/7/19/coulter-fire/"
    ),
    CALFireIncident(
        name: "Jury Fire",
        acresBurned: 53.7,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-19",
        county: "Tuolumne",
        location: "At Jury Ranch Road and Outback Drive, Sonora",
        latitude: 37.916947,
        longitude: -120.356289,
        url: "https://www.fire.ca.gov/incidents/2025/7/19/jury-fire/"
    ),
    CALFireIncident(
        name: "Trap Fire",
        acresBurned: 38.3,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-20",
        county: "Mariposa",
        location: "Bear Trap Road, East of Mykleoaks Road, Mariposa",
        latitude: 37.514275,
        longitude: -120.012292,
        url: "https://www.fire.ca.gov/incidents/2025/7/20/trap-fire/"
    ),
    CALFireIncident(
        name: "Alta Fire",
        acresBurned: 17.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-20",
        county: "Butte",
        location: "Alta Airosa Drive, east of Oroville",
        latitude: 39.422347,
        longitude: -121.470538,
        url: "https://www.fire.ca.gov/incidents/2025/7/20/alta-fire/"
    ),
    CALFireIncident(
        name: "Wolfsen Fire",
        acresBurned: 1.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-21",
        county: "Merced",
        location: "Wolfsen Road and Hereford Road, Los Banos",
        latitude: 37.211668,
        longitude: -120.788745,
        url: "https://www.fire.ca.gov/incidents/2025/7/21/wolfsen-fire/"
    ),
    CALFireIncident(
        name: "Frontage Fire",
        acresBurned: 50.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-20",
        county: "San Bernardino",
        location: " E Street and Frontage Road ",
        latitude: 34.548782,
        longitude: -117.296674,
        url: "https://www.fire.ca.gov/incidents/2025/7/20/frontage-fire/"
    ),
    CALFireIncident(
        name: "Stokes Fire ",
        acresBurned: 10.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-22",
        county: "Tulare",
        location: "Orosi, North of Avenue 392",
        latitude: 36.518055,
        longitude: -119.196666,
        url: "https://www.fire.ca.gov/incidents/2025/7/22/stokes-fire/"
    ),
    CALFireIncident(
        name: "Orange Fire",
        acresBurned: 13.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-22",
        county: "Stanislaus",
        location: "Orange Blossom Road and Highway 108, Knights Ferry",
        latitude: 37.789557,
        longitude: -120.744427,
        url: "https://www.fire.ca.gov/incidents/2025/7/22/orange-fire/"
    ),
    CALFireIncident(
        name: "Euclid Fire",
        acresBurned: 120.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-23",
        county: "San Bernardino",
        location: "Highway 71 and Euclid Road, Chino Hills",
        latitude: 33.922339,
        longitude: -117.64923,
        url: "https://www.fire.ca.gov/incidents/2025/7/23/euclid-fire/"
    ),
    CALFireIncident(
        name: "Mitchell Fire",
        acresBurned: 51.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-23",
        county: "Riverside",
        location: "Bautista Road and Glasgow Road, Anza",
        latitude: 33.563156,
        longitude: -116.695847,
        url: "https://www.fire.ca.gov/incidents/2025/7/23/mitchell-fire/"
    ),
    CALFireIncident(
        name: "Posta Fire",
        acresBurned: 23.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-24",
        county: "San Diego",
        location: "La Posta Road, North of the Community of Campo",
        latitude: 32.667663,
        longitude: -116.430132,
        url: "https://www.fire.ca.gov/incidents/2025/7/24/posta-fire/"
    ),
    CALFireIncident(
        name: "4-1 Fire",
        acresBurned: 20.7,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-24",
        county: "Modoc",
        location: "Highway 139 north of Highway 299, Canby",
        latitude: 41.459967,
        longitude: -120.924262,
        url: "https://www.fire.ca.gov/incidents/2025/7/24/4-1-fire/"
    ),
    CALFireIncident(
        name: "Sliger Fire",
        acresBurned: 14.4,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-24",
        county: "El Dorado",
        location: "Sliger Mine Road and Hilda Way, near Middle Fork American River",
        latitude: 38.943781,
        longitude: -120.926046,
        url: "https://www.fire.ca.gov/incidents/2025/7/24/sliger-fire/"
    ),
    CALFireIncident(
        name: "Shady Fire",
        acresBurned: 52.4,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-25",
        county: "Riverside",
        location: "Avenue 54 and Shady Lane, Coachella ",
        latitude: 33.656632,
        longitude: -116.172565,
        url: "https://www.fire.ca.gov/incidents/2025/7/25/shady-fire/"
    ),
    CALFireIncident(
        name: "Mammoth Fire ",
        acresBurned: 2533.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-25",
        county: "Modoc",
        location: "West of the Dry Lake Fire Station and Highway 139, Tionesta",
        latitude: 41.684141,
        longitude: -121.323879,
        url: "https://www.fire.ca.gov/incidents/2025/7/25/mammoth-fire/"
    ),
    CALFireIncident(
        name: "3-5 Fire",
        acresBurned: 42.5,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-25",
        county: "Lassen",
        location: "Little Valley Road, South of Pit River Canyon Road, Little Valley",
        latitude: 40.9814,
        longitude: -121.280552,
        url: "https://www.fire.ca.gov/incidents/2025/7/25/3-5-fire/"
    ),
    CALFireIncident(
        name: "Green Fire-RRU",
        acresBurned: 21.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-25",
        county: "Riverside",
        location: "Palisades Drive and Green River Road, Corona",
        latitude: 33.882719,
        longitude: -117.641517,
        url: "https://www.fire.ca.gov/incidents/2025/7/25/green-fire-rru/"
    ),
    CALFireIncident(
        name: "Boneyard Fire",
        acresBurned: 227.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-26",
        county: "Tuolumne",
        location: "Priest Coulterville Road, North of Jackass Creek Road, Greeley Hill",
        latitude: 37.773371,
        longitude: -120.214807,
        url: "https://www.fire.ca.gov/incidents/2025/7/26/boneyard-fire/"
    ),
    CALFireIncident(
        name: "W-2 Fire",
        acresBurned: 24.7,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-25",
        county: "Modoc",
        location: "East of Payne Reservoir southeast of Alturas, Modoc County",
        latitude: 41.392519,
        longitude: -120.43839,
        url: "https://www.fire.ca.gov/incidents/2025/7/25/w-2-fire/"
    ),
    CALFireIncident(
        name: "Pearl Fire",
        acresBurned: 39.7,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-25",
        county: "Kern",
        location: "Highway 178 and Elizabeth Norris Road, Lake Isabella",
        latitude: 35.6182,
        longitude: -118.48813,
        url: "https://www.fire.ca.gov/incidents/2025/7/25/pearl-fire/"
    ),
    CALFireIncident(
        name: "Hoffman Fire",
        acresBurned: 10.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-26",
        county: "Kern",
        location: "Highway 14 and Jawbone Canyon Road, Mojave",
        latitude: 35.300512,
        longitude: -118.000889,
        url: "https://www.fire.ca.gov/incidents/2025/7/26/hoffman-fire/"
    ),
    CALFireIncident(
        name: "19 Fire",
        acresBurned: 16.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-29",
        county: "Madera",
        location: "Golden State Boulevard and Road 19,  North of Fairmead  ",
        latitude: 37.07642,
        longitude: -120.202377,
        url: "https://www.fire.ca.gov/incidents/2025/7/29/19-fire/"
    ),
    CALFireIncident(
        name: "Rd 15  Madera_acres Fire",
        acresBurned: 30.0,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-30",
        county: "Madera",
        location: "Road 15, Madera",
        latitude: 36.995304,
        longitude: -120.274202,
        url: "https://www.fire.ca.gov/incidents/2025/7/30/rd-15-madera_acres-fire/"
    ),
    CALFireIncident(
        name: "Orion Fire",
        acresBurned: 24.7,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-07-31",
        county: "Santa Barbara",
        location: "Rancho Road & Orion Road, Vandenberg",
        latitude: 34.80493,
        longitude: -120.53608,
        url: "https://www.fire.ca.gov/incidents/2025/7/31/orion-fire/"
    ),
    CALFireIncident(
        name: "Bernardo Fire",
        acresBurned: 12.7,
        percentContained: 100.0,
        isActive: false,
        startedDate: "2025-08-01",
        county: "San Diego",
        location: "Camino Del Norte & Bernardo Center Drive ",
        latitude: 33.0088892,
        longitude: -117.0978951,
        url: "https://www.fire.ca.gov/incidents/2025/8/1/bernardo-fire/"
    ),
]

let fireStats = FireStatistics(
    totalActiveFires: 13,
    totalAcresBurning: 72592.8,
    largestActiveFire: "Gifford Fire ",
    lastUpdated: "2025-08-02 18:56:49"
)

struct FireStatistics {
    let totalActiveFires: Int
    let totalAcresBurning: Double
    let largestActiveFire: String
    let lastUpdated: String
}
struct DynamicFireMarker: View {
    let fire: CALFireIncident
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {

                if fire.acresBurned > 10000 {
                    Circle()
                        .fill(getFireColor().opacity(0.4))
                        .frame(width: getMarkerSize() + 20, height: getMarkerSize() + 20)
                        .blur(radius: 8)
                }

                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [getFireColor(), getFireColor().opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: getMarkerSize(), height: getMarkerSize())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .shadow(color: .black.opacity(0.3), radius: 1)
                    )
                    .shadow(color: getFireColor().opacity(0.6), radius: 6, x: 0, y: 3)

                Image(systemName: "flame.fill")
                    .font(.system(size: getIconSize(), weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func getMarkerSize() -> CGFloat {
        if fire.acresBurned > 10000 { return 36 }
        else if fire.acresBurned > 1000 { return 30 }
        else if fire.acresBurned > 100 { return 26 }
        else { return 22 }
    }

    private func getIconSize() -> CGFloat {
        if fire.acresBurned > 10000 { return 16 }
        else if fire.acresBurned > 1000 { return 14 }
        else if fire.acresBurned > 100 { return 12 }
        else { return 10 }
    }

    private func getFireColor() -> Color {
        if !fire.isActive { return .gray }
        if fire.percentContained < 30 { return .red }
        else if fire.percentContained < 70 { return .orange }
        else { return .yellow }
    }
}
struct FireDetailCard: View {
    let fire: CALFireIncident
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {

            VStack(spacing: 8) {
                HStack {
                    Text(fire.name)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundColor(.wsOrange)
                }

                Text("\(Int(fire.acresBurned)) acres")
                    .font(.headline)
                    .foregroundColor(.wsYellow)
            }
            .padding()
            .background(Color.wsDark.opacity(0.8))

            ScrollView {
                VStack(spacing: 16) {

                    HStack {
                        Circle()
                            .fill(fire.isActive ? Color.wsRed : Color.wsOrange)
                            .frame(width: 12, height: 12)
                        Text(fire.isActive ? "Active Fire" : "Contained")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        DetailItem(title: "Containment", value: "\(Int(fire.percentContained))%", icon: "percent")
                        DetailItem(title: "Started", value: fire.startedDate, icon: "calendar")
                        DetailItem(title: "County", value: fire.county, icon: "mappin.and.ellipse")
                        DetailItem(title: "Location", value: fire.location, icon: "location.fill")
                    }
                    .padding(.horizontal)

                    if !fire.url.isEmpty {
                        Button("View on CAL FIRE Website") {
                            if let url = URL(string: fire.url) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundColor(.wsOrange)
                        .padding()
                        .background(Color.wsOrange.opacity(0.2))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .background(Color.wsDark)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 10)
    }
}
struct DetailItem: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.wsOrange)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.wsDark.opacity(0.6))
        .cornerRadius(8)
    }
}
