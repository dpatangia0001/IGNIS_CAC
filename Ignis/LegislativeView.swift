import SwiftUI
import Charts

struct LegislativeView: View {
    @StateObject private var dataService = LegislativeDataService()
    @State private var selectedTab = 0
    @State private var showingContactSheet = false
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            ZStack {

                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.02, blue: 0.01),
                        Color(red: 0.1, green: 0.05, blue: 0.02),
                        Color(red: 0.15, green: 0.08, blue: 0.03),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {

                    headerSection

                    customTabBar

                    if dataService.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.orange)
                            Text("Loading legislative data...")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = dataService.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("Unable to load data")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                dataService.fetchLegislativeData()
                            }
                            .foregroundColor(.orange)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {

                        Group {
                            switch selectedTab {
                            case 0:
                                OverviewTab(dataService: dataService)
                            case 1:
                                PoliciesTab(dataService: dataService)
                            case 2:
                                FundingTab(dataService: dataService)
                            case 3:
                                ActionTab(dataService: dataService)
                            default:
                                OverviewTab(dataService: dataService)
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
                        .padding(.bottom, 100)
                    }
                }
            }
            .sheet(isPresented: $showingContactSheet) {
                ContactSheet()
            }
            .onAppear {
                if dataService.policies.isEmpty {
                    dataService.fetchLegislativeData()
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Legislative Center")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .orange.opacity(0.9), .yellow.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Track wildfire policies and funding")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Button(action: { showingContactSheet = true }) {
                    Image(systemName: "envelope.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(
                                colors: [.orange, .red, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .orange.opacity(0.6), radius: 8, x: 0, y: 4)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                MetricCard(title: "Prevention", value: "$\(Int(dataService.spendingData.first?.prevention ?? 0))M", subtitle: "2024 Budget", color: .green)
                MetricCard(title: "Recovery", value: "$\(Int(dataService.spendingData.first?.recovery ?? 0))M", subtitle: "2024 Cost", color: .red)
                MetricCard(title: "Ratio", value: "1:4.4", subtitle: "Prevention:Recovery", color: .orange)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { index in
                Button(action: { selectedTab = index }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabIcons[index])
                            .font(.system(size: 20))

                        Text(tabTitles[index])
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == index ? .orange : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == index ? Color.orange.opacity(0.3) : Color.clear)
                    .cornerRadius(8)
                }
            }
        }
        .background(Color.black.opacity(0.4))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private let tabIcons = ["chart.bar.fill", "doc.text.fill", "dollarsign.circle.fill", "megaphone.fill"]
    private let tabTitles = ["Overview", "Policies", "Funding", "Action"]
}

struct OverviewTab: View {
    @ObservedObject var dataService: LegislativeDataService

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                SpendingChart(dataService: dataService)

                RecentActivitySection()

                QuickActionsSection()
            }
            .padding()
        }
    }
}

struct SpendingChart: View {
    @ObservedObject var dataService: LegislativeDataService

    var data: [SpendingData] {
        dataService.spendingData.isEmpty ? sampleSpendingData : dataService.spendingData
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wildfire Spending Trends")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Chart(data) { item in
                BarMark(
                    x: .value("Year", item.year),
                    y: .value("Prevention", item.prevention)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                BarMark(
                    x: .value("Year", item.year),
                    y: .value("Recovery", item.recovery)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(.white)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        Text("$\(value.as(Int.self) ?? 0)M")
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(height: 200)
            .chartLegend(position: .bottom)
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
    }
}

struct RecentActivitySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Legislative Activity")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            VStack(spacing: 12) {
                ActivityRow(
                    title: "SB 436 Passed",
                    subtitle: "Enhanced building codes for fire resistance",
                    date: "2 days ago",
                    type: .policy
                )

                ActivityRow(
                    title: "New Grant Program",
                    subtitle: "$50M allocated for community prevention",
                    date: "1 week ago",
                    type: .funding
                )

                ActivityRow(
                    title: "Public Hearing",
                    subtitle: "Wildfire prevention budget discussion",
                    date: "2 weeks ago",
                    type: .meeting
                )
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
    }
}

struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "Find Your Rep",
                    icon: "person.fill",
                    color: .blue
                )

                QuickActionCard(
                    title: "Submit Comment",
                    icon: "pencil",
                    color: .green
                )

                QuickActionCard(
                    title: "Track Bills",
                    icon: "doc.text",
                    color: .orange
                )

                QuickActionCard(
                    title: "Join Meeting",
                    icon: "video.fill",
                    color: .purple
                )
            }
        }
    }
}

struct PoliciesTab: View {
    @ObservedObject var dataService: LegislativeDataService
    @State private var searchText = ""
    @State private var selectedFilter = "All"

    let filters = ["All", "Active", "Proposed", "Passed"]

    var body: some View {
        VStack(spacing: 0) {

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))

                    TextField("Search policies...", text: $searchText)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.4))
                .cornerRadius(10)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { filter in
                            PolicyFilterChip(
                                title: filter,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()

            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(dataService.policies.isEmpty ? samplePolicies : dataService.policies) { policy in
                        PolicyCard(policy: policy)
                    }
                }
                .padding()
            }
        }
    }
}

struct FundingTab: View {
    @ObservedObject var dataService: LegislativeDataService

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                VStack(alignment: .leading, spacing: 16) {
                    Text("Available Funding")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    VStack(spacing: 12) {
                        ForEach(dataService.funding.isEmpty ? sampleFunding : dataService.funding) { fund in
                            FundingCard(funding: fund)
                        }
                    }
                }

                TipsSection()
            }
            .padding()
        }
    }
}

struct ActionTab: View {
    @ObservedObject var dataService: LegislativeDataService

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                ContactSection(dataService: dataService)

                EventsSection(dataService: dataService)

                ResourcesSection()
            }
            .padding()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let date: String
    let type: ActivityType

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(type.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Text(date)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(12)
    }
}

struct PolicyCard: View {
    let policy: Policy
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(policy.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text(policy.billNumber)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                StatusBadge(status: policy.status)
            }

            if isExpanded {
                Text(policy.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))

                HStack {
                    Label("Sponsor: \(policy.sponsor)", systemImage: "person.fill")
                    Spacer()
                    Label(policy.date, systemImage: "calendar")
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            }

            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(isExpanded ? "Show Less" : "Show More")
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
    }
}

struct FundingCard: View {
    let funding: Funding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(funding.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text(funding.amount)
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }

                Spacer()

                if let deadline = funding.deadline {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Deadline")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))

                        Text(deadline)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
            }

            Text(funding.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))

            HStack {
                Label(funding.eligibility, systemImage: "person.2.fill")
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Button("Apply") {

                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
    }
}

struct PolicyFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.orange : Color.black.opacity(0.3))
                .cornerRadius(16)
        }
    }
}

struct StatusBadge: View {
    let status: PolicyStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color)
            .cornerRadius(8)
    }
}

struct ContactSection: View {
    @ObservedObject var dataService: LegislativeDataService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Your Representatives")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            VStack(spacing: 12) {
                ForEach(dataService.representatives.isEmpty ? sampleRepresentatives : dataService.representatives) { rep in
                    RepresentativeCard(representative: rep)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
    }
}

struct RepresentativeCard: View {
    let representative: Representative

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(representative.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text(representative.title)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))

                    Text(representative.party)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }

                Spacer()

                VStack(spacing: 8) {
                    Button("Email") {
                        if let url = URL(string: "mailto:\(representative.email)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)

                    Button("Call") {
                        if let url = URL(string: "tel:\(representative.phone.replacingOccurrences(of: " ", with: ""))") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
            }

            Text(representative.office)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(12)
    }
}

struct EventsSection: View {
    @ObservedObject var dataService: LegislativeDataService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming Events")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            VStack(spacing: 12) {
                ForEach(dataService.events.isEmpty ? sampleEvents : dataService.events) { event in
                    EventCard(event: event)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
    }
}

struct EventCard: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Spacer()

                Text(event.type.rawValue)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
            }

            HStack {
                Label(event.date, systemImage: "calendar")
                Spacer()
                Label(event.time, systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))

            Label(event.location, systemImage: "location")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text(event.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

struct ResourcesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advocacy Resources")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            VStack(spacing: 12) {
                ResourceCard(
                    title: "How to Write Effective Letters",
                    description: "Tips for contacting your representatives"
                )

                ResourceCard(
                    title: "Understanding the Legislative Process",
                    description: "How bills become laws"
                )

                ResourceCard(
                    title: "Finding Your Representatives",
                    description: "Locate your elected officials"
                )
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
    }
}

struct ResourceCard: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)

            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

struct TipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Application Tips")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 8) {
                TipRow(text: "Start early - applications take time")
                TipRow(text: "Gather required documents")
                TipRow(text: "Follow up on your application")
                TipRow(text: "Join mailing lists for updates")
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
    }
}

struct TipRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)

            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct ContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Your Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                }

                Section("Message") {
                    TextEditor(text: $message)
                        .frame(minHeight: 100)
                }

                Section {
                    Button("Send Message") {

                        dismiss()
                    }
                    .disabled(name.isEmpty || email.isEmpty || message.isEmpty)
                }
            }
            .navigationTitle("Contact Representative")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SpendingData: Identifiable {
    let id = UUID()
    let year: Int
    let prevention: Double
    let recovery: Double
}

struct Policy: Identifiable {
    let id = UUID()
    let title: String
    let billNumber: String
    let description: String
    let status: PolicyStatus
    let sponsor: String
    let date: String
}

struct Funding: Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    let description: String
    let eligibility: String
    let deadline: String?
}

enum PolicyStatus: String, CaseIterable {
    case active = "Active"
    case proposed = "Proposed"
    case passed = "Passed"
    case failed = "Failed"

    var color: Color {
        switch self {
        case .active: return .green
        case .proposed: return .orange
        case .passed: return .blue
        case .failed: return .red
        }
    }
}

enum ActivityType {
    case policy, funding, meeting

    var color: Color {
        switch self {
        case .policy: return .blue
        case .funding: return .green
        case .meeting: return .orange
        }
    }
}

let samplePolicies = [
    Policy(
        title: "SB 436 - Wildfire Prevention Act",
        billNumber: "SB 436",
        description: "Enhanced building codes for fire resistance and vegetation management in high-risk areas. Requires fire-resistant materials for new construction in CA-32.",
        status: .active,
        sponsor: "Sen. Robert Hertzberg",
        date: "2024-01-15"
    ),
    Policy(
        title: "AB 789 - Emergency Response Funding",
        billNumber: "AB 789",
        description: "Increased funding for fire departments, equipment, and training. Allocates $50M for CA-32 district fire safety improvements.",
        status: .proposed,
        sponsor: "Rep. Adrin Nazarian",
        date: "2024-02-20"
    ),
    Policy(
        title: "SB 901 - Community Evacuation Plan",
        billNumber: "SB 901",
        description: "Mandatory evacuation planning for high-risk areas. Requires cities in CA-32 to develop and test evacuation routes annually.",
        status: .passed,
        sponsor: "Sen. Robert Hertzberg",
        date: "2023-08-15"
    ),
    Policy(
        title: "HR 1234 - Federal Wildfire Relief",
        billNumber: "HR 1234",
        description: "Federal funding for wildfire recovery and prevention. Brad Sherman co-sponsored this bill specifically for CA-32 district needs.",
        status: .active,
        sponsor: "Rep. Brad Sherman",
        date: "2024-03-01"
    )
]

let sampleFunding = [
    Funding(
        name: "CA-32 Community Fire Safe Grants",
        amount: "$5M available",
        description: "Grants for CA-32 community organizations to implement fire prevention programs. Priority for Woodland Hills, Van Nuys, and surrounding areas.",
        eligibility: "Nonprofits, community groups in CA-32",
        deadline: "March 15, 2024"
    ),
    Funding(
        name: "Federal Hazard Mitigation - CA-32",
        amount: "$50M/year",
        description: "Federal funding specifically allocated for CA-32 district wildfire prevention measures. Brad Sherman secured this funding.",
        eligibility: "State & local governments in CA-32",
        deadline: "Rolling"
    ),
    Funding(
        name: "CA-32 Homeowner Assistance",
        amount: "$2M available",
        description: "Financial assistance for CA-32 homeowners to implement fire-safe landscaping and home improvements. Covers Ventura Blvd corridor.",
        eligibility: "Individual homeowners in CA-32",
        deadline: "April 1, 2024"
    ),
    Funding(
        name: "Emergency Response Equipment",
        amount: "$10M available",
        description: "Funding for fire departments in CA-32 to purchase advanced equipment and vehicles for wildfire response.",
        eligibility: "Fire departments serving CA-32",
        deadline: "May 1, 2024"
    )
]

#Preview {
    LegislativeView()
}
