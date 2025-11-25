import Foundation
import Combine

enum NewsSeverity {
    case low, medium, high
}

struct FireNews: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let date: String
    let severity: NewsSeverity
    let url: URL?

    var parsedDate: Date {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"

        let composed = date + " " + String(Calendar.current.component(.year, from: Date()))
        fmt.dateFormat = "MMM d yyyy"
        return fmt.date(from: composed) ?? Date.distantPast
    }
}

final class FireNewsService: ObservableObject {
    static let shared = FireNewsService()

    @Published var items: [FireNews] = []
    @Published var lastUpdated: Date?
    @Published var isLoading = false

    private var timer: Timer?
    private let refreshInterval: TimeInterval = 24 * 60 * 60
    private var isStarted = false

    private let sources: [URL] = [
        URL(string: "https://news.google.com/rss/search?q=california%20wildfire&hl=en-US&gl=US&ceid=US:en")!,
        URL(string: "https://news.google.com/rss/search?q=cal%20fire%20incident&hl=en-US&gl=US&ceid=US:en")!,
        URL(string: "https://news.google.com/rss/search?q=evacuation%20wildfire&hl=en-US&gl=US&ceid=US:en")!
    ]

    private init() {

    }

    func startPeriodicUpdates() {
        guard !isStarted else { return }
        isStarted = true

        fetchLatest()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.fetchLatest()
        }
    }

    func stop() {
        isStarted = false
        timer?.invalidate();
        timer = nil
    }

    func fetchLatest() {
        isLoading = true
        Task { @MainActor in
            let results = await withTaskGroup(of: [FireNews].self) { group -> [[FireNews]] in
                for url in sources { group.addTask { await self.fetchRSS(url: url) } }
                var collected: [[FireNews]] = []
                for await arr in group { collected.append(arr) }
                return collected
            }
            var flattened = results.flatMap { $0 }
                .sorted { $0.parsedDate > $1.parsedDate }
            if flattened.isEmpty {

                flattened = await self.fetchRSS(url: URL(string: "https://news.google.com/rss/search?q=wildfire&hl=en-US&gl=US&ceid=US:en")!)
            }
            self.items = Array(flattened.prefix(3))
            self.lastUpdated = Date()
            self.isLoading = false
        }
    }

    private func fetchRSS(url: URL) async -> [FireNews] {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let xml = String(data: data, encoding: .utf8) else { return [] }
            return parseRSS(xml: xml, source: url)
        } catch {
            return []
        }
    }

    private func parseRSS(xml: String, source: URL) -> [FireNews] {
        var items: [FireNews] = []

        let itemRegex = try? NSRegularExpression(pattern: "<item[\\n\\s\\S]*?</item>", options: [.caseInsensitive])
        let range = NSRange(xml.startIndex..<xml.endIndex, in: xml)
        itemRegex?.enumerateMatches(in: xml, options: [], range: range) { match, _, _ in
            guard let match = match, let r = Range(match.range, in: xml) else { return }
            let itemXML = String(xml[r])
            let title = self.firstMatch(in: itemXML, pattern: "<title>([\\n\\s\\S]*?)</title>")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let linkStr = self.firstMatch(in: itemXML, pattern: "<link>([\\n\\s\\S]*?)</link>")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let desc = self.firstMatch(in: itemXML, pattern: "<description>([\\n\\s\\S]*?)</description>")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let pubDate = self.firstMatch(in: itemXML, pattern: "<pubDate>([\\n\\s\\S]*?)</pubDate>")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !title.isEmpty else { return }

            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            guard let parsedDate = dateFormatter.date(from: pubDate) else { return }

            let calendar = Calendar.current
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            guard parsedDate >= sevenDaysAgo else { return }

            let cleanTitle = decodeHTMLEntities(stripHTML(title))
            let cleanDesc = decodeHTMLEntities(stripHTML(desc))

            guard !cleanTitle.isEmpty else { return }

            let finalDesc = cleanDesc
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&#39;", with: "'")
                .replacingOccurrences(of: "&apos;", with: "'")
                .replacingOccurrences(of: "&mdash;", with: "—")
                .replacingOccurrences(of: "&ndash;", with: "–")
                .replacingOccurrences(of: "&hellip;", with: "...")

                .replacingOccurrences(of: "<[^>]*>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "href=", with: "")
                .replacingOccurrences(of: "target=", with: "")
                .replacingOccurrences(of: "https?://[^\\s]+", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let url = URL(string: linkStr)
            let news = FireNews(
                title: cleanTitle,
                summary: "",
                date: shortDate(pubDate),
                severity: inferSeverity(title: cleanTitle, description: cleanTitle),
                url: url
            )
            items.append(news)
        }
        return items
    }

    private func firstMatch(in text: String, pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let m = regex?.firstMatch(in: text, options: [], range: range), m.numberOfRanges > 1,
              let r = Range(m.range(at: 1), in: text) else { return nil }
        return String(text[r])
    }

    private func decodeHTMLEntities(_ s: String) -> String {
        var str = s.replacingOccurrences(of: "&amp;", with: "&")
        str = str.replacingOccurrences(of: "&nbsp;", with: " ")
        str = str.replacingOccurrences(of: "&lt;", with: "<")
        str = str.replacingOccurrences(of: "&gt;", with: ">")
        str = str.replacingOccurrences(of: "&quot;", with: "\"")
        str = str.replacingOccurrences(of: "&#39;", with: "'")
        str = str.replacingOccurrences(of: "&apos;", with: "'")
        str = str.replacingOccurrences(of: "&mdash;", with: "—")
        str = str.replacingOccurrences(of: "&ndash;", with: "–")
        str = str.replacingOccurrences(of: "&hellip;", with: "...")
        return str
    }

    private func stripHTML(_ s: String) -> String {
        var str = s

        str = str.replacingOccurrences(of: "<[^>]*>", with: "", options: .regularExpression)

        str = str.replacingOccurrences(of: "&[a-zA-Z0-9#]+;", with: "", options: .regularExpression)

        str = str.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        str = str.trimmingCharacters(in: .whitespacesAndNewlines)

        return str
    }

    private func shortDate(_ pubDate: String) -> String {

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        let d = fmt.date(from: pubDate) ?? Date()
        let out = DateFormatter()
        out.dateFormat = "MMM d"
        return out.string(from: d)
    }

    private func inferSeverity(title: String, description: String) -> NewsSeverity {
        let text = (title + " " + description).lowercased()
        if text.contains("evacuation") || text.contains("red flag") || text.contains("warning") { return .high }
        if text.contains("containment") || text.contains("update") { return .medium }
        return .low
    }
}

final class FireDataService: ObservableObject {
    static let shared = FireDataService()

    @Published private(set) var calFireIncidents: [CALFireIncident] = []
    @Published private(set) var nasaFireStatistics: NASAFireStatistics? = nil
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil

    private let calFireService = CalFireService()
    private let nasaFirmsService = NASAFIRMSService()
    private let calFireDetailService = CalFireDetailService.shared
    private var cancellables: Set<AnyCancellable> = []
    private var isInitialized = false

    private init() {
        setupBindings()
    }

    private func setupBindings() {

        calFireService.$incidents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] incidents in
                self?.calFireIncidents = incidents
            }
            .store(in: &cancellables)

        nasaFirmsService.$statistics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] statistics in
                self?.nasaFireStatistics = statistics
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(calFireService.$isLoading, nasaFirmsService.$isLoading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] calFireLoading, nasaLoading in
                self?.isLoading = calFireLoading || nasaLoading
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(calFireService.$errorMessage, nasaFirmsService.$errorMessage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] calFireError, nasaError in
                if let calError = calFireError, let nasaError = nasaError {
                    self?.errorMessage = "Cal Fire: \(calError); NASA: \(nasaError)"
                } else {
                    self?.errorMessage = calFireError ?? nasaError
                }
            }
            .store(in: &cancellables)
    }

    func start() {
        guard !isInitialized else { return }
        isInitialized = true

        DispatchQueue.main.async { [weak self] in
            self?.calFireService.startPeriodicUpdates()
            self?.nasaFirmsService.startPeriodicUpdates()
            self?.calFireDetailService.startPeriodicRefresh()
        }
    }

    func refreshNow() {
        guard isInitialized else { return }

        calFireService.fetchCalFireData()
        nasaFirmsService.fetchFireData()
        Task { await calFireDetailService.startPeriodicRefresh() }
    }

    func stop() {
        isInitialized = false
        calFireService.stopPeriodicUpdates()

    }
}
