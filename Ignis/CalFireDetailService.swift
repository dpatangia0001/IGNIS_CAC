import Foundation

struct CalFireIncidentDetail: Codable {
    var roadClosures: [String]?
    var evacuationShelters: [String]?
    var animalEvacuationShelters: [String]?
    var temporaryEvacuationPoints: [String]?
    var resourcesAssigned: [String]?
    var damageAssessment: [String]?

    var resourcesMetrics: [ResourceMetric]?
    var damageMetrics: [ResourceMetric]?
    var sheltersStructured: [ShelterInfo]?
    var tepsStructured: [TEPInfo]?
    var lastUpdated: Date
}

struct ResourceMetric: Codable, Hashable {
    let value: String
    let label: String
}

struct ShelterInfo: Codable, Hashable {
    let name: String
    let address: String?
    let note: String?
}

struct TEPInfo: Codable, Hashable {
    let name: String
    let address: String?
    let hours: String?
}

final class CalFireDetailService: ObservableObject {
    static let shared = CalFireDetailService()

    @Published private(set) var cache: [String: CalFireIncidentDetail] = [:]
    @Published private(set) var isRefreshing: Bool = false

    private var timer: Timer?
    private let refreshInterval: TimeInterval = 3 * 60 * 60

    private init() {
        startPeriodicRefresh()
    }

    func startPeriodicRefresh() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { await self?.refreshAll() }
        }
    }

    func stopPeriodicRefresh() {
        timer?.invalidate()
        timer = nil
    }

    func details(for urlString: String) async -> CalFireIncidentDetail? {

        if let d = cache[urlString], Date().timeIntervalSince(d.lastUpdated) < refreshInterval {
            return d
        }
        return await fetchAndCache(urlString: urlString)
    }

    @discardableResult
    private func fetchAndCache(urlString: String) async -> CalFireIncidentDetail? {
        guard let url = URL(string: urlString) else { return nil }
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            let detail = parseDetailHTML(html)
            await MainActor.run { self.cache[urlString] = detail }
            return detail
        } catch {
            return nil
        }
    }

    private func refreshAll() async {
        guard !cache.isEmpty else { return }
        await MainActor.run { isRefreshing = true }
        defer { Task { @MainActor in self.isRefreshing = false } }
        for key in cache.keys { _ = await fetchAndCache(urlString: key) }
    }

    private func parseDetailHTML(_ html: String) -> CalFireIncidentDetail {
        let cleaned = html
            .replacingOccurrences(of: "<[^>]+>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
        let normalized = cleaned
            .replacingOccurrences(of: "\n+", with: "\n", options: .regularExpression)
        func section(_ titles: [String]) -> String? {

            let allTitles = [
                "Road Closures", "Evacuation Shelters", "Animal Evacuation Shelters",
                "Temporary Evacuation Points", "Resources Assigned", "Damage Assessment",
                "Evacuation Orders", "Evacuation Warnings",

                "Quick Links", "About Us", "Current Incidents", "Incidents", "Defensible Space",
                "Resources", "Statistics", "Subscribe to Newsletter", "Contact", "Social Media",
                "Map Legend", "Legend", "Situation Summary", "Incident Update", "News Update"
            ]

            var startIdx: String.Index? = nil
            for t in titles {
                if let r = normalized.range(of: t, options: [.caseInsensitive]) { startIdx = r.upperBound; break }
            }
            guard let start = startIdx else { return nil }

            var end = normalized.endIndex
            for t in allTitles {
                if let r = normalized.range(of: t, options: [.caseInsensitive], range: start..<normalized.endIndex) {
                    end = min(end, r.lowerBound)
                }
            }
            let slice = normalized[start..<end]
            let trimmed = slice.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        func items(from text: String?) -> [String]? {
            guard let text = text else { return nil }
            let separators: CharacterSet = CharacterSet(charactersIn: "\n•-;•\u{2022}")
            var parts: [String] = []
            text.components(separatedBy: separators).forEach { raw in
                let s = raw.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if s.count > 2 { parts.append(s) }
            }

            var seen = Set<String>()
            let unique = parts.filter { if seen.contains($0.lowercased()) { return false } else { seen.insert($0.lowercased()); return true } }
            return unique.isEmpty ? nil : unique
        }

        enum Section { case road, shelters, animal, tep, resources, damage }
        func filterItems(_ items: [String]?, for section: Section) -> [String]? {
            guard var items = items else { return nil }

            let blacklistSubstrings = ["gaq", "analytics", "function", "push(", "UA-", "script", "cookie", "privacy", "subscribe", "newsletter", "Quick Links", "About Us", "Map Legend", "Legend", "Icon", "Description", "Lightning Activity"]
            items.removeAll { s in
                let lower = s.lowercased()
                if s.count < 3 { return true }
                if Int(s) != nil { return true }
                if blacklistSubstrings.contains(where: { lower.contains($0.lowercased()) }) { return true }
                return false
            }

            switch section {
            case .road:
                items = items.filter { s in
                    let l = s.lowercased()
                    return l.contains("road") || l.contains("rd") || l.contains("hwy") || l.contains("highway") || l.contains("sr-") || l.contains("closure") || l.contains("open") || l.contains("closed") || l.contains("lane")
                }
            case .shelters:
                items = items.filter { s in
                    let l = s.lowercased(); return l.contains("shelter") || l.contains("evacuation center") || l.contains("community center") || l.contains("address") || l.contains("drive") || l.contains("ave") || l.contains("st ") || l.contains("street")
                }
            case .animal:
                items = items.filter { s in
                    let l = s.lowercased(); return l.contains("animal") || l.contains("pet") || l.contains("livestock") || l.contains("equestrian") || l.contains("county animal services")
                }
            case .tep:
                items = items.filter { s in
                    let l = s.lowercased(); return l.contains("temporary evacuation point") || l.contains("tep") || l.contains("parking lot") || l.contains("high school") || l.contains("store") || l.contains("address")
                }
            case .resources:
                items = items.filter { s in
                    let l = s.lowercased();
                    let keywords = ["engines", "crews", "personnel", "helicopter", "helicopters", "aircraft", "dozers", "water tender", "strike team", "hand crew", "resources assigned", "overhead"]
                    return keywords.contains(where: { l.contains($0) }) || l.range(of: "\\d+", options: .regularExpression) != nil
                }
            case .damage:
                items = items.filter { s in
                    let l = s.lowercased();
                    if l.hasPrefix("evacuation order:") || l.hasPrefix("evacuation warning:") || l.hasPrefix("red flag warning:") { return false }
                    let keywords = ["structure", "structures", "damaged", "destroyed", "injur", "fatalit", "impact", "assessment", "damage", "residential", "commercial"]
                    return keywords.contains(where: { l.contains($0) })
                }
            }

            items = items.map { String($0.prefix(220)) }

            return compact(items: items, for: section)
        }

        func compact(items: [String], for section: Section) -> [String]? {
            var out: [String] = []
            let numberRegex = try? NSRegularExpression(pattern: "\\d{1,4}")
            func firstNumber(_ s: String) -> String? {
                guard let r = numberRegex?.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)), let rr = Range(r.range, in: s) else { return nil }
                return String(s[rr])
            }
            switch section {
            case .resources:
                let mapping: [(key: String, label: String)] = [
                    ("engines", "Engines"), ("hand crew", "Hand Crews"), ("crews", "Crews"),
                    ("personnel", "Personnel"), ("helicopter", "Helicopters"), ("helicopters", "Helicopters"),
                    ("aircraft", "Aircraft"), ("dozer", "Dozers"), ("water tender", "Water Tenders"),
                    ("strike team", "Strike Teams"), ("overhead", "Overhead")
                ]
                var best: [String: String] = [:]
                for line in items {
                    let lower = line.lowercased()
                    for (key, label) in mapping where lower.contains(key) {
                        if let n = firstNumber(line) { best[label] = n }
                    }
                }
                out = mapping.compactMap { entry in
                    if let n = best[entry.label] { return "\(entry.label): \(n)" }
                    return nil
                }
            case .damage:
                let mapping: [(keyword: String, label: String)] = [
                    ("destroyed", "Structures Destroyed"), ("damaged", "Structures Damaged"),
                    ("injur", "Injuries"), ("fatal", "Fatalities")
                ]
                var best: [String: String] = [:]
                for line in items {
                    let lower = line.lowercased()
                    for (k, label) in mapping where lower.contains(k) {
                        if let n = firstNumber(line) { best[label] = n }
                    }
                }
                out = mapping.compactMap { if let n = best[$0.label] { return "\($0.label): \(n)" } else { return nil } }
            case .road:

                for line in items {
                    let l = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    let lower = l.lowercased()

                    if (lower.contains("highway") || lower.contains("road") || lower.contains("street") ||
                        lower.contains("avenue") || lower.contains("boulevard") || lower.contains("lane") ||
                        lower.contains("drive") || lower.contains("pozo") || lower.contains("lopez") ||
                        lower.contains("huasna") || lower.contains("sr-") || lower.contains("hwy")) &&
                       (lower.contains("closed") || lower.contains("restricted") || lower.contains("residents") ||
                        lower.contains("essential traffic")) &&
                       l.count > 20 && l.count < 200 {
                        out.append(l)
                    }
                }
            case .shelters:
                let nameRegex = try? NSRegularExpression(pattern: "([A-Z][A-Za-z0-9&' .-]+(?:Shelter|Center|Community Center|High School|Middle School|College|Fairgrounds|Park|Church))", options: [])
                for line in items {
                    if let m = nameRegex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)), let r = Range(m.range, in: line) {
                        out.append(String(line[r]))
                    }
                }
            case .animal:
                let nameRegex = try? NSRegularExpression(pattern: "([A-Z][A-Za-z0-9&' .-]+(?:Animal|Humane|Equestrian|Fairgrounds|Shelter|Services))", options: [])
                for line in items {
                    if let m = nameRegex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)), let r = Range(m.range, in: line) {
                        out.append(String(line[r]))
                    }
                }
            case .tep:
                let nameRegex = try? NSRegularExpression(pattern: "([A-Z][A-Za-z0-9&' .-]+(?:Temporary Evacuation Point|High School|Community Center|Store|Market|Fairgrounds|Parking Lot))", options: [])
                for line in items {
                    if let m = nameRegex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)), let r = Range(m.range, in: line) {
                        out.append(String(line[r]))
                    }
                }
            }

            var seen = Set<String>()
            let compacted = out.filter { if seen.contains($0.lowercased()) { return false } else { seen.insert($0.lowercased()); return true } }
            return compacted.isEmpty ? nil : Array(compacted.prefix(10))
        }

        func parseResources(from text: String?) -> [ResourceMetric]? {
            guard let text = text else { return nil }
            let lines = text.components(separatedBy: CharacterSet.newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            var metrics: [ResourceMetric] = []
            var i = 0

            while i < lines.count {
                let line = lines[i]

                if let number = Int(line.replacingOccurrences(of: ",", with: "")) {

                    if i + 1 < lines.count {
                        let label = lines[i + 1]

                        if !["assigned", "resources", "total", "other"].contains(label.lowercased()) {
                            metrics.append(ResourceMetric(value: line, label: label))
                        }
                        i += 2
                    } else {
                        i += 1
                    }
                } else {
                    i += 1
                }
            }

            return metrics.isEmpty ? nil : metrics
        }

        func parseDamage(from text: String?) -> [ResourceMetric]? {
            guard let text = text else { return nil }
            let lines = text.components(separatedBy: CharacterSet.newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            var metrics: [ResourceMetric] = []
            var i = 0

            while i < lines.count {
                let line = lines[i]

                if let number = Int(line.replacingOccurrences(of: ",", with: "")) {

                    if i + 1 < lines.count {
                        let label = lines[i + 1]
                        metrics.append(ResourceMetric(value: line, label: label))
                        i += 2
                    } else {
                        i += 1
                    }
                } else {
                    i += 1
                }
            }

            return metrics.isEmpty ? nil : metrics
        }

        func parseShelters(from text: String?) -> [ShelterInfo]? {
            guard let text = text else { return nil }
            let lines = text.components(separatedBy: CharacterSet.newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            var shelters: [ShelterInfo] = []
            var currentName: String? = nil
            var currentAddress: String? = nil
            var currentNote: String? = nil

            for line in lines {
                let lower = line.lowercased()

                if lower.contains("evacuation shelter") && !lower.contains("school") && !lower.contains("center") {
                    continue
                }
                if lower.contains("evacuation") && lower.contains("shelter") && line.count < 40 {
                    continue
                }

                if (lower.contains("for sheltering assistance") || lower.contains("please call")) &&
                   (lower.contains("red cross") || lower.contains("assistance")) &&
                   line.count < 150 {
                    currentNote = line
                    continue
                }

                if line.range(of: "\\d+", options: .regularExpression) != nil &&
                   (lower.contains(" rd.") || lower.contains(" rd,") || lower.contains(" road") ||
                    lower.contains(" st.") || lower.contains(" st,") || lower.contains(" street") ||
                    lower.contains(" ave.") || lower.contains(" ave,") || lower.contains(" avenue") ||
                    lower.contains(" dr.") || lower.contains(" dr,") || lower.contains(" drive") ||
                    lower.contains(" way") || lower.contains(" blvd")) {
                    currentAddress = line
                    continue
                }

                if ((lower.contains("school") && !lower.contains("district") && !lower.contains("office") && !lower.contains("road")) ||
                    (lower.contains("center") && !lower.contains("information") && !lower.contains("resource") && !lower.contains("community information")) ||
                    lower.contains("hall")) &&
                   line.count > 15 && line.count < 80 &&
                   !lower.contains("hours") && !lower.contains("operation") && !lower.contains("monday") {

                    if let name = currentName {
                        shelters.append(ShelterInfo(name: name, address: currentAddress, note: currentNote))
                    }
                    currentName = line
                    currentAddress = nil
                    currentNote = nil
                }
            }

            if let name = currentName {
                shelters.append(ShelterInfo(name: name, address: currentAddress, note: currentNote))
            }

            return shelters.isEmpty ? nil : shelters
        }

        func parseTEPs(from text: String?) -> [TEPInfo]? {
            guard let text = text else { return nil }
            let lines = text.components(separatedBy: CharacterSet.newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            var teps: [TEPInfo] = []
            var currentName: String? = nil
            var currentAddress: String? = nil
            var currentHours: String? = nil

            for line in lines {
                let lower = line.lowercased()

                if lower.contains("temporary evacuation point") && !lower.contains("school") && !lower.contains("center") {
                    continue
                }

                if lower.contains("hours of operation") {
                    currentHours = line
                    continue
                }

                if line.contains(",") && (line.contains("CA") || line.range(of: "\\d{5}", options: .regularExpression) != nil) {
                    if currentAddress == nil {
                        currentAddress = line
                    } else {
                        currentAddress = [currentAddress!, line].joined(separator: "\n")
                    }
                    continue
                }

                if line.range(of: "\\d+", options: .regularExpression) != nil &&
                   (lower.contains(" rd") || lower.contains(" road") || lower.contains(" st") ||
                    lower.contains(" ave") || lower.contains(" dr") || lower.contains(" way") || lower.contains("highway")) {
                    currentAddress = line
                    continue
                }

                if (lower.contains("school") || lower.contains("center")) &&
                   !lower.contains("district") && !lower.contains("office") {

                    if let name = currentName {
                        teps.append(TEPInfo(name: name, address: currentAddress, hours: currentHours))
                    }

                    let cleanedName = line
                        .replacingOccurrences(of: " and Community Information Center", with: "", options: .caseInsensitive)
                        .replacingOccurrences(of: " & Community Information Center", with: "", options: .caseInsensitive)
                        .replacingOccurrences(of: " and Community Information & Resource Center", with: "", options: .caseInsensitive)
                        .replacingOccurrences(of: " & Community Information & Resource Center", with: "", options: .caseInsensitive)
                        .replacingOccurrences(of: " and Community Information", with: "", options: .caseInsensitive)
                        .replacingOccurrences(of: " & Community Information", with: "", options: .caseInsensitive)
                        .replacingOccurrences(of: "&amp;", with: "&")
                        .replacingOccurrences(of: "&nbsp;", with: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if cleanedName.count < 3 ||
                       cleanedName.lowercased().contains("community information") ||
                       cleanedName.lowercased().contains("resource center") {
                        continue
                    }

                    currentName = cleanedName
                    currentAddress = nil
                    currentHours = nil
                }
            }

            if let name = currentName {
                teps.append(TEPInfo(name: name, address: currentAddress, hours: currentHours))
            }

            return teps.isEmpty ? nil : teps
        }

        let resourcesMetrics = parseResources(from: section(["Resources Assigned", "Resources"]))
        let damageMetrics = parseDamage(from: section(["Damage Assessment", "Damage"]))
        let sheltersStructured = parseShelters(from: section(["Evacuation Shelter", "Evacuation Shelters"]))
        let tepsStructured = parseTEPs(from: section(["Temporary Evacuation Point", "Temporary Evacuation Points"]))

        let detail = CalFireIncidentDetail(
            roadClosures: filterItems(items(from: section(["Road Closures"])), for: .road),
            evacuationShelters: filterItems(items(from: section(["Evacuation Shelters", "Shelters"])), for: .shelters),
            animalEvacuationShelters: filterItems(items(from: section(["Animal Evacuation Shelters", "Animal Shelters"])), for: .animal),
            temporaryEvacuationPoints: filterItems(items(from: section(["Temporary Evacuation Points", "TEP", "Temporary Evacuation Point"])), for: .tep),
            resourcesAssigned: filterItems(items(from: section(["Resources Assigned", "Resources"])) , for: .resources),
            damageAssessment: filterItems(items(from: section(["Damage Assessment", "Damage"])) , for: .damage),
            resourcesMetrics: resourcesMetrics,
            damageMetrics: damageMetrics,
            sheltersStructured: sheltersStructured,
            tepsStructured: tepsStructured,
            lastUpdated: Date()
        )
        return detail
    }
}
