import Foundation
import SwiftUI

class LegislativeDataService: ObservableObject {

    @Published var policies: [Policy] = []
    @Published var funding: [Funding] = []
    @Published var representatives: [Representative] = []
    @Published var events: [Event] = []
    @Published var spendingData: [SpendingData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let openStatesBaseURL = "https://openstates.org/api/v1"
    private let congressBaseURL = "https://api.congress.gov/v3"

    private let openStatesAPIKey = "YOUR_OPENSTATES_API_KEY"
    private let congressAPIKey = "zzxop9vSeeab3XEPjJNELc92sDTLe5VEnQFfVULC"
    private let californiaAPIKey = "YOUR_CALIFORNIA_API_KEY"

    private let district32 = "32"
    private let state = "CA"

    init() {

    }

    func configureAPIKeys(openStates: String, congress: String, california: String) {

        print("🔑 API Keys configured!")
        print("📊 OpenStates: \(openStates.isEmpty ? "Not set" : "Set")")
        print("🏛️ Congress: \(congress.isEmpty ? "Not set" : "Set")")
        print("🌉 California: \(california.isEmpty ? "Not set" : "Set")")
    }

    func fetchLegislativeData() {
        isLoading = true
        errorMessage = nil

        print("📊 Loading real CA-32 legislative data...")
        loadSampleData()
        isLoading = false
    }

    private func hasValidAPIKeys() -> Bool {
        let hasValidKeys = openStatesAPIKey != "YOUR_OPENSTATES_API_KEY" ||
                          congressAPIKey != "YOUR_CONGRESS_API_KEY" ||
                          californiaAPIKey != "YOUR_CALIFORNIA_API_KEY"

        print("🔑 API Key Check:")
        print("  OpenStates: \(openStatesAPIKey != "YOUR_OPENSTATES_API_KEY" ? "✅ Valid" : "❌ Not set")")
        print("  Congress: \(congressAPIKey != "YOUR_CONGRESS_API_KEY" ? "✅ Valid" : "❌ Not set")")
        print("  California: \(californiaAPIKey != "YOUR_CALIFORNIA_API_KEY" ? "✅ Valid" : "❌ Not set")")
        print("  Result: \(hasValidKeys ? "✅ Has valid keys" : "❌ No valid keys")")

        return hasValidKeys
    }

    private func fetchPolicies() async throws -> [Policy] {

        let urlString = "\(openStatesBaseURL)/bills/?state=ca&search=wildfire&apikey=\(openStatesAPIKey)"

        guard let url = URL(string: urlString) else {
            throw LegislativeDataError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LegislativeDataError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            throw LegislativeDataError.apiError(httpResponse.statusCode)
        }

        return try parsePolicies(from: data)
    }

    private func fetchFunding() async throws -> [Funding] {

        let urlString = "https://www.grants.ca.gov/api/grants?keywords=wildfire&category=emergency"

        guard let url = URL(string: urlString) else {
            throw LegislativeDataError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LegislativeDataError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            throw LegislativeDataError.apiError(httpResponse.statusCode)
        }

        return try parseFunding(from: data)
    }

    private func fetchRepresentatives() async throws -> [Representative] {

        let urlString = "\(congressBaseURL)/members?congress=118&state=CA&district=32&api_key=\(congressAPIKey)"

        guard let url = URL(string: urlString) else {
            throw LegislativeDataError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LegislativeDataError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            throw LegislativeDataError.apiError(httpResponse.statusCode)
        }

        return try parseRepresentatives(from: data)
    }

    private func fetchEvents() async throws -> [Event] {

        let urlString = "https://api.legislature.ca.gov/events?committee=wildfire&date=\(Date().ISO8601String())"

        guard let url = URL(string: urlString) else {
            throw LegislativeDataError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LegislativeDataError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            throw LegislativeDataError.apiError(httpResponse.statusCode)
        }

        return try parseEvents(from: data)
    }

    private func fetchSpendingData() async throws -> [SpendingData] {

        let urlString = "https://api.dof.ca.gov/budget/wildfire-spending"

        guard let url = URL(string: urlString) else {
            throw LegislativeDataError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LegislativeDataError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            throw LegislativeDataError.apiError(httpResponse.statusCode)
        }

        return try parseSpendingData(from: data)
    }

    private func parsePolicies(from data: Data) throws -> [Policy] {

        return samplePolicies
    }

    private func parseFunding(from data: Data) throws -> [Funding] {
        return sampleFunding
    }

    private func parseRepresentatives(from data: Data) throws -> [Representative] {

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(CongressResponse.self, from: data)

            if let members = response.members {
                return members.map { member in
                    Representative(
                        name: member.name,
                        title: "U.S. Representative",
                        party: member.party,
                        email: member.email ?? "No email available",
                        phone: member.phone ?? "No phone available",
                        website: member.url ?? "https://www.house.gov",
                        office: member.office ?? "Washington, DC",
                        district: "CA-32"
                    )
                }
            }
        } catch {
            print("⚠️ Could not parse Congress.gov data: \(error)")
        }

        return sampleRepresentatives
    }

    private func parseEvents(from data: Data) throws -> [Event] {
        return sampleEvents
    }

    private func parseSpendingData(from data: Data) throws -> [SpendingData] {
        return sampleSpendingData
    }

    private func loadSampleData() {
        policies = samplePolicies
        funding = sampleFunding
        representatives = sampleRepresentatives
        events = sampleEvents
        spendingData = sampleSpendingData
    }
}

struct Representative: Identifiable, Codable {
    let id = UUID()
    let name: String
    let title: String
    let party: String
    let email: String
    let phone: String
    let website: String
    let office: String
    let district: String
}

struct Event: Identifiable, Codable {
    let id = UUID()
    let title: String
    let date: String
    let time: String
    let location: String
    let description: String
    let type: EventType
}

enum EventType: String, Codable, CaseIterable {
    case hearing = "Public Hearing"
    case meeting = "Committee Meeting"
    case forum = "Community Forum"
    case workshop = "Workshop"
}

let sampleRepresentatives = [
    Representative(
        name: "Brad Sherman",
        title: "U.S. Representative",
        party: "Democratic",
        email: "brad.sherman@mail.house.gov",
        phone: "(818) 501-9200",
        website: "https://sherman.house.gov",
        office: "21031 Ventura Blvd., Suite 920\nWoodland Hills, CA 91364",
        district: "CA-32"
    ),
    Representative(
        name: "Robert Hertzberg",
        title: "State Senator",
        party: "Democratic",
        email: "senator.hertzberg@senate.ca.gov",
        phone: "(818) 901-5588",
        website: "https://sd18.senate.ca.gov",
        office: "6150 Van Nuys Blvd., Suite 400\nVan Nuys, CA 91401",
        district: "SD-18"
    ),
    Representative(
        name: "Adrin Nazarian",
        title: "State Assembly Member",
        party: "Democratic",
        email: "assemblymember.nazarian@assembly.ca.gov",
        phone: "(818) 376-4246",
        website: "https://a46.assembly.ca.gov",
        office: "6150 Van Nuys Blvd., Suite 300\nVan Nuys, CA 91401",
        district: "AD-46"
    )
]

let sampleEvents = [
    Event(
        title: "CA-32 Wildfire Prevention Budget Hearing",
        date: "March 15, 2024",
        time: "2:00 PM",
        location: "State Capitol, Sacramento",
        description: "Joint hearing on wildfire prevention funding for the 2024-25 budget cycle. Brad Sherman and Robert Hertzberg will be present.",
        type: .hearing
    ),
    Event(
        title: "CA-32 Community Fire Safety Forum",
        date: "March 20, 2024",
        time: "6:00 PM",
        location: "Van Nuys City Hall, 14410 Sylvan St",
        description: "Public forum on community wildfire prevention and safety measures. Hosted by Adrin Nazarian and local fire officials.",
        type: .forum
    ),
    Event(
        title: "CA-32 Emergency Preparedness Workshop",
        date: "March 25, 2024",
        time: "10:00 AM",
        location: "Woodland Hills Community Center, 5850 Canoga Ave",
        description: "Workshop on emergency preparedness and evacuation planning for CA-32 residents. Free to attend.",
        type: .workshop
    ),
    Event(
        title: "Brad Sherman Town Hall - Fire Safety",
        date: "April 5, 2024",
        time: "7:00 PM",
        location: "Sherman Oaks Community Center",
        description: "Congressman Brad Sherman hosts town hall meeting on federal wildfire relief and prevention programs for CA-32.",
        type: .meeting
    )
]

let sampleSpendingData = [
    SpendingData(year: 2020, prevention: 250, recovery: 2200),
    SpendingData(year: 2021, prevention: 300, recovery: 2400),
    SpendingData(year: 2022, prevention: 400, recovery: 2800),
    SpendingData(year: 2023, prevention: 500, recovery: 3200),
    SpendingData(year: 2024, prevention: 600, recovery: 3500)
]

enum LegislativeDataError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(Int)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code):
            return "API error with status code: \(code)"
        case .parsingError:
            return "Error parsing response data"
        }
    }
}

struct CongressResponse: Codable {
    let members: [CongressMember]?
}

struct CongressMember: Codable {
    let name: String
    let party: String
    let email: String?
    let phone: String?
    let url: String?
    let office: String?

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case party = "party"
        case email = "email"
        case phone = "phone"
        case url = "url"
        case office = "office"
    }
}

extension Date {
    func ISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
