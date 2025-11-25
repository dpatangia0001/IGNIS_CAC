import Foundation

struct CalFireIncidentResponse: Codable {
    let incidents: [CalFireIncidentData]
}
struct CalFireIncidentData: Codable {
    let id: String
    let name: String
    let county: String
    let acres: String
    let containment: String
    let started: String
    let location: String
    let isActive: Bool
    let latitude: Double?
    let longitude: Double?
    let url: String
    let lastUpdate: String

    enum CodingKeys: String, CodingKey {
        case id, name, county, acres, containment, started, location, url
        case isActive = "is_active"
        case latitude = "lat"
        case longitude = "lng"
        case lastUpdate = "last_update"
    }
}

class CalFireService: ObservableObject {
    @Published var incidents: [CALFireIncident] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?

    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 3 * 60 * 60

    private let calFireOfficialAPI = "https://incidents.fire.ca.gov/umbraco/api/IncidentApi/GeoJsonList?inactive=true"
    private let calFireIncidentsURL = "https://www.fire.ca.gov/incidents"
    private let calFireRSSURL = "https://www.fire.ca.gov/rss/rss.xml"

    init() {
        startPeriodicUpdates()
    }

    deinit {
        updateTimer?.invalidate()
    }

    func startPeriodicUpdates() {
        fetchCalFireData()

        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            self.fetchCalFireData()
        }
    }

    func stopPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    func fetchCalFireData() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetchedIncidents = try await fetchFromMultipleSources()
                await MainActor.run {
                    self.incidents = fetchedIncidents
                    self.isLoading = false
                    self.lastUpdated = Date()
                    print("✅ Cal Fire data updated: \(fetchedIncidents.count) incidents")
                    if fetchedIncidents.isEmpty {
                        print("⚠️ No incidents found - this might be why no fires are showing")
                    } else {
                        print("🔥 Sample incidents: \(fetchedIncidents.prefix(3).map { $0.name })")
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false

                    if self.incidents.isEmpty {
                        print("📝 Using static Cal Fire data as fallback")
                        self.incidents = calFireIncidents
                    }
                    print("❌ Cal Fire fetch error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func fetchFromMultipleSources() async throws -> [CALFireIncident] {

        async let officialResult = fetchFromOfficialCalFireAPI()
        async let rssResult = fetchFromRSSFeed()

        let allResults = try await [
            officialResult,
            rssResult
        ].flatMap { $0 }

        let mergedIncidents = mergeAndDeduplicateIncidents(from: allResults)
        return mergedIncidents.sorted { $0.acresBurned > $1.acresBurned }
    }

    private func fetchFromOfficialCalFireAPI() async throws -> [CALFireIncident] {
        guard let url = URL(string: calFireOfficialAPI) else {
            throw CalFireError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        do {
            print("🌐 Requesting Cal Fire API: \(calFireOfficialAPI)")
            let (data, response) = try await URLSession.shared.data(for: request)

            print("📊 API Response - Status: \((response as? HTTPURLResponse)?.statusCode ?? 0), Data size: \(data.count) bytes")

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Official Cal Fire API returned non-200 status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return []
            }

            if let responseString = String(data: data, encoding: .utf8) {
                let preview = String(responseString.prefix(500))
                print("📝 API Response preview: \(preview)")
            }

            let incidents = try parseOfficialCalFireResponse(data)
            print("🔥 Parsed \(incidents.count) incidents from Official Cal Fire API")
            return incidents

        } catch {
            print("⚠️ Official Cal Fire API error: \(error.localizedDescription)")
            return []
        }
    }

    private func parseOfficialCalFireResponse(_ data: Data) throws -> [CALFireIncident] {

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = json["features"] as? [[String: Any]] else {
            throw CalFireError.parsingError
        }

        var incidents: [CALFireIncident] = []
        var filteredOut = 0

        for feature in features {
            guard let props = feature["properties"] as? [String: Any],
                  let geometry = feature["geometry"] as? [String: Any] else { continue }
            if let incident = parseOfficialCalFireFeature(properties: props, geometry: geometry) {

                if let startStr = props["Started"] as? String ?? props["StartedDateOnly"] as? String,
                   let startDate = parseDateFlexible(startStr) {
                    let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                    let isActive = props["IsActive"] as? Bool ?? true

                    if !isActive && startDate < cutoff {
                        filteredOut += 1
                        continue
                    }
                }
                incidents.append(incident)
            }
        }
        print("✅ Parsed \(incidents.count) incidents (filtered out: \(filteredOut))")
        return incidents
    }

    private func parseOfficialCalFireFeature(properties: [String: Any], geometry: [String: Any]) -> CALFireIncident? {

        guard let name = properties["Name"] as? String else {
            print("⚠️ Feature missing 'Name' property. Available properties: \(properties.keys.sorted())")
            return nil
        }

        let started = properties["Started"] as? String ?? properties["StartedDateOnly"] as? String ?? ""

        let acresBurned = properties["AcresBurned"] as? Double ?? 0.0
        let percentContained = properties["PercentContained"] as? Double ?? 0.0
        let isActive = properties["IsActive"] as? Bool ?? true
        let county = properties["County"] as? String ?? "California"
        let location = properties["Location"] as? String ?? county
        let url = properties["Url"] as? String ?? ""

        var latitude = 0.0
        var longitude = 0.0

        if let coordinates = geometry["coordinates"] as? [Double], coordinates.count >= 2 {
            longitude = coordinates[0]
            latitude = coordinates[1]
        }

        return CALFireIncident(
            name: name,
            acresBurned: acresBurned,
            percentContained: percentContained,
            isActive: isActive,
            startedDate: started,
            county: county,
            location: location,
            latitude: latitude,
            longitude: longitude,
            url: url
        )
    }

    private func parseArcGISCalFireFeature(attributes: [String: Any], feature: [String: Any]) -> CALFireIncident? {

        guard let name = attributes["FIRE_NAME"] as? String, !name.isEmpty else {
            print("⚠️ Feature missing 'FIRE_NAME'. Available attributes: \(attributes.keys.sorted())")
            return nil
        }

        let acresBurned = (attributes["GIS_ACRES"] as? Double) ?? (attributes["REPORT_AC"] as? Double) ?? 0.0
        let year = attributes["YEAR_"] as? String ?? ""
        let alarmDate = attributes["ALARM_DATE"] as? String ?? ""
        let contDate = attributes["CONT_DATE"] as? String ?? ""

        let isActive = contDate.isEmpty || contDate == "null"
        let percentContained = isActive ? 0.0 : 100.0

        var latitude = 0.0
        var longitude = 0.0

        if let geometry = feature["geometry"] as? [String: Any],
           let rings = geometry["rings"] as? [[[Double]]],
           let firstRing = rings.first,
           let firstPoint = firstRing.first,
           firstPoint.count >= 2 {

            longitude = firstPoint[0]
            latitude = firstPoint[1]

            if let spatialRef = geometry["spatialReference"] as? [String: Any],
               let wkid = spatialRef["wkid"] as? Int,
               wkid == 102100 || wkid == 3857 {

                let (lat, lon) = webMercatorToLatLon(x: longitude, y: latitude)
                latitude = lat
                longitude = lon
            }
        }

        let url = "https://www.fire.ca.gov/incidents/\(year)/\(name.lowercased().replacingOccurrences(of: " ", with: "-"))-fire/"

        let currentYear = Calendar.current.component(.year, from: Date())
        if let fireYear = Int(year), fireYear < currentYear - 1 {
            return nil
        }

        print("🔥 Parsed fire: \(name) - \(acresBurned) acres, Active: \(isActive)")

        return CALFireIncident(
            name: name,
            acresBurned: acresBurned,
            percentContained: percentContained,
            isActive: isActive,
            startedDate: alarmDate,
            county: "California",
            location: "California",
            latitude: latitude,
            longitude: longitude,
            url: url
        )
    }

    private func webMercatorToLatLon(x: Double, y: Double) -> (latitude: Double, longitude: Double) {
        let earthRadius = 6378137.0
        let lon = x / earthRadius * 180.0 / Double.pi
        let lat = atan(sinh(y / earthRadius)) * 180.0 / Double.pi
        return (latitude: lat, longitude: lon)
    }

    private func parseGISFeature(attributes: [String: Any], geometry: [String: Any]) -> CALFireIncident? {

        let name = attributes["FIRE_NAME"] as? String ?? "Unknown Fire"
        let acresStr = attributes["ACRES"] as? String ?? attributes["ACRES_BURNED"] as? String ?? "0"
        let containmentStr = attributes["CONTAINMENT"] as? String ?? attributes["PERCENT_CONTAINED"] as? String ?? "0"
        let county = attributes["COUNTY"] as? String ?? "Unknown"
        let started = attributes["START_DATE"] as? String ?? attributes["DATE_STARTED"] as? String ?? ""
        let location = attributes["LOCATION"] as? String ?? county
        let isActive = attributes["STATUS"] as? String != "Contained"
        let url = attributes["URL"] as? String ?? ""

        var latitude = 0.0
        var longitude = 0.0

        if let x = geometry["x"] as? Double, let y = geometry["y"] as? Double {
            longitude = x
            latitude = y
        } else if let rings = geometry["rings"] as? [[[Double]]],
                  let firstRing = rings.first,
                  let firstPoint = firstRing.first {
            longitude = firstPoint[0]
            latitude = firstPoint[1]
        }

        return CALFireIncident(
            name: name,
            acresBurned: parseAcres(acresStr),
            percentContained: parseContainment(containmentStr),
            isActive: isActive,
            startedDate: started,
            county: county,
            location: location,
            latitude: latitude,
            longitude: longitude,
            url: url.isEmpty ? "https://www.fire.ca.gov/incidents" : url
        )
    }

    private func fetchFromCurrentIncidentsPage() async throws -> [CALFireIncident] {
        guard let url = URL(string: calFireIncidentsURL) else {
            throw CalFireError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,**;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            guard let html = String(data: data, encoding: .utf8) else {
                return []
            }

            let incidents = parseCurrentIncidentsHTML(html)
            print("🌐 Fetched \(incidents.count) incidents from Cal Fire current incidents page")
            return incidents

        } catch {
            print("⚠️ Cal Fire current incidents error: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchFromRSSFeed() async throws -> [CALFireIncident] {
        guard let url = URL(string: calFireRSSURL) else {
            throw CalFireError.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let incidents = parseCalFireRSS(data)
            print("📰 Fetched \(incidents.count) incidents from Cal Fire RSS")
            return incidents

        } catch {
            print("⚠️ Cal Fire RSS error: \(error.localizedDescription)")
            return []
        }
    }

    private func parseCalFireAPIResponse(_ data: Data) throws -> [CALFireIncident] {

        do {
            let response = try JSONDecoder().decode(CalFireIncidentResponse.self, from: data)
            return response.incidents.compactMap { convertToCALFireIncident($0) }
        } catch {

            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return jsonArray.compactMap { parseIncidentFromJSON($0) }
            }
            throw error
        }
    }

    private func parseCalFireHTML(_ html: String) -> [CALFireIncident] {
        var incidents: [CALFireIncident] = []

        let incidentPattern = #"<div[^>]*class=\"[^\"]*incident[^\"]*\"[^>]*>(.*?)</div>"#
        let regex = try? NSRegularExpression(pattern: incidentPattern, options: [.caseInsensitive, .dotMatchesLineSeparators])

        let range = NSRange(location: 0, length: html.utf16.count)
        regex?.enumerateMatches(in: html, options: [], range: range) { match, _, _ in
            guard let match = match,
                  let range = Range(match.range, in: html) else { return }

            let incidentHTML = String(html[range])
            if let incident = parseIncidentHTML(incidentHTML) {
                incidents.append(incident)
            }
        }

        return incidents
    }

    private func parseIncidentHTML(_ html: String) -> CALFireIncident? {

        let name = extractValue(from: html, pattern: #"data-name=\"([^\"]+)\""#) ?? "Unknown Fire"
        let acresStr = extractValue(from: html, pattern: #"data-acres=\"([^\"]+)\""#) ?? "0"
        let containmentStr = extractValue(from: html, pattern: #"data-containment=\"([^\"]+)\""#) ?? "0"
        let county = extractValue(from: html, pattern: #"data-county=\"([^\"]+)\""#) ?? "Unknown"
        let started = extractValue(from: html, pattern: #"data-started=\"([^\"]+)\""#) ?? ""
        let latStr = extractValue(from: html, pattern: #"data-lat=\"([^\"]+)\""#)
        let lngStr = extractValue(from: html, pattern: #"data-lng=\"([^\"]+)\""#)
        let urlPath = extractValue(from: html, pattern: #"href=\"(/incidents/[^\"]+)\""#)

        let acres = parseAcres(acresStr)
        let containment = parseContainment(containmentStr)
        let latitude = latStr.flatMap { Double($0) } ?? 0.0
        let longitude = lngStr.flatMap { Double($0) } ?? 0.0
        let url = urlPath.map { "https://www.fire.ca.gov\($0)" } ?? ""

        return CALFireIncident(
            name: name,
            acresBurned: acres,
            percentContained: containment,
            isActive: containment < 100,
            startedDate: started,
            county: county,
            location: county,
            latitude: latitude,
            longitude: longitude,
            url: url
        )
    }

    private func parseCalFireRSS(_ data: Data) -> [CALFireIncident] {
        guard let rssString = String(data: data, encoding: .utf8) else { return [] }

        var incidents: [CALFireIncident] = []

        let itemPattern = #"<item>(.*?)</item>"#
        let regex = try? NSRegularExpression(pattern: itemPattern, options: [.caseInsensitive, .dotMatchesLineSeparators])

        let range = NSRange(location: 0, length: rssString.utf16.count)
        regex?.enumerateMatches(in: rssString, options: [], range: range) { match, _, _ in
            guard let match = match,
                  let range = Range(match.range, in: rssString) else { return }

            let itemXML = String(rssString[range])
            if let incident = parseRSSItem(itemXML) {
                incidents.append(incident)
            }
        }

        return incidents
    }

    private func parseRSSItem(_ xml: String) -> CALFireIncident? {
        let title = extractValue(from: xml, pattern: #"<title>(.*?)</title>"#) ?? "Unknown Fire"
        let link = extractValue(from: xml, pattern: #"<link>(.*?)</link>"#) ?? ""
        let description = extractValue(from: xml, pattern: #"<description>(.*?)</description>"#) ?? ""

        let name = extractFireName(from: title)
        let acres = extractAcresFromDescription(description)
        let containment = extractContainmentFromDescription(description)

        return CALFireIncident(
            name: name,
            acresBurned: acres,
            percentContained: containment,
            isActive: containment < 100,
            startedDate: "",
            county: "California",
            location: "California",
            latitude: 0.0,
            longitude: 0.0,
            url: link
        )
    }

    private func convertToCALFireIncident(_ data: CalFireIncidentData) -> CALFireIncident? {
        let acres = parseAcres(data.acres)
        let containment = parseContainment(data.containment)

        return CALFireIncident(
            name: data.name,
            acresBurned: acres,
            percentContained: containment,
            isActive: data.isActive,
            startedDate: data.started,
            county: data.county,
            location: data.location,
            latitude: data.latitude ?? 0.0,
            longitude: data.longitude ?? 0.0,
            url: data.url.isEmpty ? "" : data.url
        )
    }

    private func parseIncidentFromJSON(_ json: [String: Any]) -> CALFireIncident? {
        guard let name = json["name"] as? String else { return nil }

        let acresStr = json["acres"] as? String ?? "0"
        let containmentStr = json["containment"] as? String ?? "0"
        let county = json["county"] as? String ?? "Unknown"
        let started = json["started"] as? String ?? ""
        let location = json["location"] as? String ?? county
        let latitude = json["latitude"] as? Double ?? 0.0
        let longitude = json["longitude"] as? Double ?? 0.0
        let url = json["url"] as? String ?? ""
        let isActive = json["is_active"] as? Bool ?? true

        return CALFireIncident(
            name: name,
            acresBurned: parseAcres(acresStr),
            percentContained: parseContainment(containmentStr),
            isActive: isActive,
            startedDate: started,
            county: county,
            location: location,
            latitude: latitude,
            longitude: longitude,
            url: url
        )
    }

    private func extractValue(from text: String, pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let range = NSRange(location: 0, length: text.utf16.count)

        if let match = regex?.firstMatch(in: text, options: [], range: range),
           let valueRange = Range(match.range(at: 1), in: text) {
            return String(text[valueRange])
        }
        return nil
    }

    private func parseAcres(_ acresStr: String) -> Double {
        let cleanStr = acresStr.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " acres", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleanStr) ?? 0.0
    }

    private func parseContainment(_ containmentStr: String) -> Double {
        let cleanStr = containmentStr.replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleanStr) ?? 0.0
    }

    private func extractFireName(from title: String) -> String {

        if let range = title.range(of: " Fire") {
            let endIndex = title.index(range.upperBound, offsetBy: 0)
            return String(title[..<endIndex])
        }
        return title.components(separatedBy: " - ").first ?? title
    }

    private func extractAcresFromDescription(_ description: String) -> Double {
        let pattern = #"(\d+,?\d*)\s*acres?"#
        if let match = extractValue(from: description, pattern: pattern) {
            return parseAcres(match)
        }
        return 0.0
    }

    private func extractContainmentFromDescription(_ description: String) -> Double {
        let pattern = #"(\d+)%\s*contain"#
        if let match = extractValue(from: description, pattern: pattern) {
            return Double(match) ?? 0.0
        }
        return 0.0
    }

    private func parseCurrentIncidentsHTML(_ html: String) -> [CALFireIncident] {
        var incidents: [CALFireIncident] = []

        let linkPattern = #"<a[^>]*href=\"(/incidents/[^\"]+)\"[^>]*>([^<]+)</a>"#
        let regex = try? NSRegularExpression(pattern: linkPattern, options: [.caseInsensitive])

        let range = NSRange(location: 0, length: html.utf16.count)
        regex?.enumerateMatches(in: html, options: [], range: range) { match, _, _ in
            guard let match = match,
                  let urlRange = Range(match.range(at: 1), in: html),
                  let nameRange = Range(match.range(at: 2), in: html) else { return }

            let incidentURL = "https://www.fire.ca.gov" + String(html[urlRange])
            let incidentName = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)

            let incident = CALFireIncident(
                name: incidentName,
                acresBurned: 0.0,
                percentContained: 0.0,
                isActive: true,
                startedDate: "",
                county: "California",
                location: "California",
                latitude: 0.0,
                longitude: 0.0,
                url: incidentURL
            )

            incidents.append(incident)
        }

        return incidents
    }

    private func mergeAndDeduplicateIncidents(from incidents: [CALFireIncident]) -> [CALFireIncident] {
        var incidentMap: [String: CALFireIncident] = [:]

        for incident in incidents {
            let normalizedName = incident.name.lowercased()
                .replacingOccurrences(of: " fire", with: "")
                .replacingOccurrences(of: " complex", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let existing = incidentMap[normalizedName] {

                let merged = CALFireIncident(
                    name: existing.name.isEmpty ? incident.name : existing.name,
                    acresBurned: max(existing.acresBurned, incident.acresBurned),
                    percentContained: max(existing.percentContained, incident.percentContained),
                    isActive: existing.isActive || incident.isActive,
                    startedDate: existing.startedDate.isEmpty ? incident.startedDate : existing.startedDate,
                    county: existing.county.isEmpty ? incident.county : existing.county,
                    location: existing.location.isEmpty ? incident.location : existing.location,
                    latitude: existing.latitude == 0.0 ? incident.latitude : existing.latitude,
                    longitude: existing.longitude == 0.0 ? incident.longitude : existing.longitude,
                    url: existing.url.isEmpty ? incident.url : existing.url
                )
                incidentMap[normalizedName] = merged
            } else {
                incidentMap[normalizedName] = incident
            }
        }

        return Array(incidentMap.values)
    }

    private func isFireWithinLast14Days(startDate: String) -> Bool {

        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

        var fireStartDate = dateFormatter.date(from: startDate)

        if fireStartDate == nil {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            fireStartDate = dateFormatter.date(from: startDate)
        }

        guard let startDate = fireStartDate else {

            return true
        }

        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return startDate >= fourteenDaysAgo
    }

    private func removeDuplicates(from incidents: [CALFireIncident]) -> [CALFireIncident] {
        var uniqueIncidents: [CALFireIncident] = []
        var seenNames: Set<String> = []

        for incident in incidents {
            let normalizedName = incident.name.lowercased().trimmingCharacters(in: .whitespaces)
            if !seenNames.contains(normalizedName) {
                seenNames.insert(normalizedName)
                uniqueIncidents.append(incident)
            }
        }

        return uniqueIncidents
    }
}

enum CalFireError: Error, LocalizedError {
    case invalidURL
    case noData
    case parsingError
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Cal Fire URL"
        case .noData:
            return "No Cal Fire data available"
        case .parsingError:
            return "Failed to parse Cal Fire data"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

extension URLSession {
    func data(from url: URL) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: url) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: CalFireError.noData)
                }
            }
            task.resume()
        }
    }
}

private func parseDateFlexible(_ raw: String) -> Date? {
    if raw.isEmpty { return nil }

    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = iso.date(from: raw) { return d }
    iso.formatOptions = [.withInternetDateTime]
    if let d = iso.date(from: raw) { return d }

    let df = DateFormatter()
    df.calendar = Calendar(identifier: .gregorian)
    df.locale = Locale(identifier: "en_US_POSIX")
    df.dateFormat = "yyyy-MM-dd"
    if let d = df.date(from: raw) { return d }
    return nil
}
