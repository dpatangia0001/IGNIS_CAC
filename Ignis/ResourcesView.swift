import SwiftUI
import CoreLocation

struct ResourceItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let category: ResourceCategory
    let url: String?
    let phone: String?
    let distance: String?
    let priority: ResourcePriority
}

enum ResourceCategory: String, CaseIterable {
    case all = "All"
    case shelters = "Shelters"
    case emergency = "Emergency"
    case donations = "Donations"
    case support = "Support"
    case information = "Information"

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .shelters: return "house.fill"
        case .emergency: return "phone.fill"
        case .donations: return "heart.fill"
        case .support: return "person.2.fill"
        case .information: return "info.circle.fill"
        }
    }
}

enum ResourcePriority: Int, CaseIterable {
    case critical = 0
    case high = 1
    case medium = 2
    case low = 3
}

struct Shelter: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let capacity: String
    let status: String
    let coordinates: CLLocationCoordinate2D
}

struct ResourcesView: View {
    @State private var selectedCategory: ResourceCategory = .all
    @State private var searchText = ""
    @State private var showingMap = false
    @State private var selectedShelter: Shelter?
    @StateObject private var shelterService = ShelterService()
    @State private var showingFilters = false

    var resources: [ResourceItem] {
        return [

            ResourceItem(
                title: "Emergency Hotline",
                description: "24/7 emergency assistance and immediate help",
                icon: "phone.fill",
                category: .emergency,
                url: nil,
                phone: "911",
                distance: nil,
                priority: .critical
            ),
            ResourceItem(
                title: "Fire Department",
                description: "Local fire station and emergency response",
                icon: "flame.circle.fill",
                category: .emergency,
                url: nil,
                phone: "1-800-347-7283",
                distance: "0.3 miles",
                priority: .critical
            ),
            ResourceItem(
                title: "Police Department",
                description: "Local law enforcement and emergency services",
                icon: "shield.fill",
                category: .emergency,
                url: nil,
                phone: "1-800-347-7283",
                distance: "0.8 miles",
                priority: .high
            ),

            ResourceItem(
                title: "Emergency Shelters",
                description: "Find nearby evacuation shelters and safe zones",
                icon: "house.fill",
                category: .shelters,
                url: nil,
                phone: nil,
                distance: shelterService.shelters.first?.distance != nil ? String(format: "%.1f miles", shelterService.shelters.first!.distance!) : "Locating...",
                priority: .high
            ),
            ResourceItem(
                title: "Pet-Friendly Shelters",
                description: "Pet-friendly evacuation centers and animal rescue",
                icon: "pawprint.fill",
                category: .shelters,
                url: nil,
                phone: nil,
                distance: shelterService.shelters.first(where: { $0.type == .pets })?.distance != nil ? String(format: "%.1f miles", shelterService.shelters.first(where: { $0.type == .pets })!.distance!) : "Locating...",
                priority: .high
            ),

            ResourceItem(
                title: "Mental Health Support",
                description: "Crisis counseling and mental health services",
                icon: "brain.head.profile",
                category: .support,
                url: "https://www.crisistextline.org",
                phone: "988",
                distance: nil,
                priority: .high
            ),

            ResourceItem(
                title: "Red Cross Donations",
                description: "Support wildfire relief and recovery efforts",
                icon: "heart.fill",
                category: .donations,
                url: "https://www.redcross.org/donate/disaster-relief.html",
                phone: "1-800-RED-CROSS",
                distance: nil,
                priority: .medium
            ),
            ResourceItem(
                title: "Firefighter Support Fund",
                description: "Help firefighters and first responders",
                icon: "flame.fill",
                category: .donations,
                url: "https://www.wildlandfirefighter.org/donate",
                phone: "1-800-347-7283",
                distance: nil,
                priority: .medium
            ),
            ResourceItem(
                title: "Community Relief Fund",
                description: "Local community wildfire recovery assistance",
                icon: "person.3.fill",
                category: .donations,
                url: "https://www.cafirefoundation.org/donate",
                phone: "1-800-565-8736",
                distance: nil,
                priority: .medium
            ),

            ResourceItem(
                title: "Insurance Claims",
                description: "Help with insurance claims and recovery process",
                icon: "doc.text.fill",
                category: .support,
                url: "https://www.insurance.ca.gov",
                phone: "1-800-927-4357",
                distance: nil,
                priority: .medium
            ),
            ResourceItem(
                title: "Legal Assistance",
                description: "Free legal help for disaster victims",
                icon: "building.columns.fill",
                category: .support,
                url: "https://www.lsc.gov",
                phone: "1-800-433-0081",
                distance: nil,
                priority: .medium
            ),

            ResourceItem(
                title: "Air Quality Index",
                description: "Check current air quality conditions",
                icon: "wind",
                category: .information,
                url: "https://www.airnow.gov",
                phone: nil,
                distance: nil,
                priority: .low
            ),
            ResourceItem(
                title: "Weather Updates",
                description: "Real-time weather and fire conditions",
                icon: "cloud.sun.fill",
                category: .information,
                url: "https://www.weather.gov",
                phone: nil,
                distance: nil,
                priority: .low
            ),
            ResourceItem(
                title: "Evacuation Routes",
                description: "Safe evacuation routes and traffic updates",
                icon: "map.fill",
                category: .information,
                url: "https://www.dot.ca.gov",
                phone: nil,
                distance: nil,
                priority: .low
            )
        ]
    }

    var shelters: [Shelter] {
        return shelterService.shelters.map { emergencyShelter in
            Shelter(
                name: emergencyShelter.name,
                address: emergencyShelter.address,
                capacity: emergencyShelter.capacity,
                status: emergencyShelter.status.rawValue,
                coordinates: emergencyShelter.coordinates
            )
        }
    }

    var filteredResources: [ResourceItem] {
        let filtered = resources.filter { resource in
            let matchesSearch = searchText.isEmpty ||
                resource.title.localizedCaseInsensitiveContains(searchText) ||
                resource.description.localizedCaseInsensitiveContains(searchText)

            let matchesCategory = selectedCategory == .all || resource.category == selectedCategory

            return matchesSearch && matchesCategory
        }

        return filtered.sorted { lhs, rhs in
            if lhs.priority.rawValue != rhs.priority.rawValue {
                return lhs.priority.rawValue < rhs.priority.rawValue
            }
            return lhs.title < rhs.title
        }
    }

    var body: some View {
        NavigationView {
            ZStack {

                Color.appGradientBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    headerView

                    searchAndFilterView

                    ScrollView {
                        LazyVStack(spacing: 12) {

                            emergencyActionsView

                            resourcesSection

                            if !shelters.isEmpty {
                                sheltersSection
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedShelter) { shelter in
            ShelterDetailView(shelter: shelter)
        }
        .onAppear {

            let sample = CLLocation(latitude: 34.0522, longitude: -118.2437)
            shelterService.fetchNearbyShelters(userLocation: sample)
        }
    }

    private var headerView: some View {
        HStack {
            Text("Resources")
                .font(.appTitle)
                .foregroundColor(.wsOrange)

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.appGradientPrimary)
                    .frame(width: 40, height: 40)

                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var searchAndFilterView: some View {
        VStack(spacing: 16) {

            HStack {
                Spacer()

                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appTextSecondary)

                    TextField("Search resources...", text: $searchText)
                        .font(.appCaption)
                        .foregroundColor(.appTextPrimary)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button(action: {
                            withAnimation(.appEaseOut) {
                                searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: 280, maxHeight: 36)
                .background(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.appBorder.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(18)

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ResourceCategory.allCases, id: \.self) { category in
                        CategoryPill(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.appSpring) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 8)
    }

    private var emergencyActionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appError)

                Text("Emergency Actions")
                    .font(.appCaption)
                    .foregroundColor(.appTextPrimary)

                Spacer()
            }

            HStack(spacing: 8) {
                MiniEmergencyButton(
                    title: "911",
                    subtitle: "Emergency",
                    icon: "phone.fill",
                    color: .appError
                ) {
                    if let url = URL(string: "tel:911") {
                        UIApplication.shared.open(url)
                    }
                }

                MiniEmergencyButton(
                    title: "988",
                    subtitle: "Crisis Line",
                    icon: "brain.head.profile",
                    color: .appInfo
                ) {
                    if let url = URL(string: "tel:988") {
                        UIApplication.shared.open(url)
                    }
                }

                MiniEmergencyButton(
                    title: "Fire Dept",
                    subtitle: "Local",
                    icon: "flame.circle.fill",
                    color: .appWarning
                ) {
                    if let url = URL(string: "tel:1-800-347-7283") {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .padding(12)
        .appCardStyle()
    }

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Resources")
                    .font(.appHeadline)
                    .foregroundColor(.appTextPrimary)

                Spacer()

                if selectedCategory != .all {
                    Button(action: {
                        withAnimation(.appSpring) {
                            selectedCategory = .all
                        }
                    }) {
                        Text("Show All")
                            .font(.appCaption)
                            .foregroundColor(.appPrimary)
                    }
                }
            }

            if filteredResources.isEmpty {
                ResourceEmptyStateView(
                    icon: "magnifyingglass",
                    title: "No resources found",
                    message: searchText.isEmpty ? "Try selecting a different category" : "Try adjusting your search terms"
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(filteredResources.prefix(6)) { resource in
                        MiniResourceCard(resource: resource)
                    }
                }

                if filteredResources.count > 6 {
                    Button(action: {

                    }) {
                        HStack {
                            Text("View \(filteredResources.count - 6) more resources")
                                .font(.appCaption)
                                .foregroundColor(.appPrimary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.appSmall)
                                .foregroundColor(.appPrimary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.appSurface)
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private var sheltersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "house.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appInfo)

                Text("Nearby Shelters")
                    .font(.appSubheadline)
                    .foregroundColor(.appTextPrimary)

                Spacer()

                if let lastUpdated = shelterService.lastUpdated {
                    Text("Updated \(timeAgoString(from: lastUpdated))")
                        .font(.appSmall)
                        .foregroundColor(.appTextTertiary)
                }
            }

            if shelterService.isLoading {
                LoadingView(message: "Finding shelters...")
            } else if shelters.isEmpty {
                CompactEmptyStateView(
                    icon: "location.slash",
                    title: "No shelters found"
                )
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(shelters.prefix(3)) { shelter in
                        MiniShelterCard(shelter: shelter) {
                            selectedShelter = shelter
                        }
                    }

                    if shelters.count > 3 {
                        Button(action: {

                        }) {
                            HStack {
                                Text("View \(shelters.count - 3) more shelters")
                                    .font(.appCaption)
                                    .foregroundColor(.appPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.appSmall)
                                    .foregroundColor(.appPrimary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.appSurface)
                            .cornerRadius(8)
                        }
                    }
                }
            }

            if let errorMessage = shelterService.errorMessage {
                ErrorView(message: errorMessage)
            }
        }
        .padding(16)
        .appCardStyle()
    }

    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct CompactStatView: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .center, spacing: 1) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
    }
}

struct CategoryPill: View {
    let category: ResourceCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .medium))

                Text(category.rawValue)
                    .font(.appCaption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.appPrimary : Color.appButtonSecondary)
            )
            .foregroundColor(isSelected ? .white : .appTextSecondary)
            .shadow(color: isSelected ? Color.appPrimary.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MiniEmergencyButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 24, height: 24)

                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(spacing: 1) {
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.appTextPrimary)

                    Text(subtitle)
                        .font(.system(size: 9))
                        .foregroundColor(.appTextSecondary)
                }
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.appSurface)
            .cornerRadius(8)
            .shadow(color: color.opacity(0.1), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MiniResourceCard: View {
    let resource: ResourceItem

    private var priorityColor: Color {
        switch resource.priority {
        case .critical: return .appError
        case .high: return .appWarning
        case .medium: return .appInfo
        case .low: return .appTextSecondary
        }
    }

    var body: some View {
        Button(action: {
            if let url = resource.url, let urlObj = URL(string: url) {
                UIApplication.shared.open(urlObj)
            } else if let phone = resource.phone, let url = URL(string: "tel:\(phone)") {
                UIApplication.shared.open(url)
            }
        }) {
            VStack(alignment: .leading, spacing: 6) {

                HStack {
                    ZStack {
                        Circle()
                            .fill(priorityColor.opacity(0.2))
                            .frame(width: 22, height: 22)

                        Image(systemName: resource.icon)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(priorityColor)
                    }

                    Spacer()

                    if let distance = resource.distance {
                        Text(distance)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.appTextTertiary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.appBorder)
                            .cornerRadius(3)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(resource.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)

                    Text(resource.description)
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer()

                HStack(spacing: 4) {
                    if resource.phone != nil {
                        MiniActionTag(text: "Call", icon: "phone.fill")
                    }
                    if resource.url != nil {
                        MiniActionTag(text: "Visit", icon: "safari.fill")
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8))
                        .foregroundColor(.appPrimary)
                }
            }
            .padding(12)
            .frame(height: 110)
            .appCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MiniActionTag: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 7, weight: .medium))

            Text(text)
                .font(.system(size: 8, weight: .medium))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(Color.appPrimary.opacity(0.1))
        .foregroundColor(.appPrimary)
        .cornerRadius(4)
    }
}

struct MiniShelterCard: View {
    let shelter: Shelter
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.appInfo.opacity(0.2))
                        .frame(width: 24, height: 24)

                    Image(systemName: "house.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.appInfo)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(shelter.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)

                    Text(shelter.address)
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        MiniStatusBadge(text: shelter.status, color: .appSuccess)
                        MiniStatusBadge(text: shelter.capacity, color: .appInfo)

                        Spacer()
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 8))
                    .foregroundColor(.appTextTertiary)
            }
            .padding(8)
            .background(Color.appSurface)
            .cornerRadius(8)
            .shadow(color: Color.appPrimary.opacity(0.02), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MiniStatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .medium))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

struct ResourceEmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.appTextTertiary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.appHeadline)
                    .foregroundColor(.appTextPrimary)

                Text(message)
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct CompactEmptyStateView: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.appTextTertiary)

            Text(title)
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)

            Spacer()
        }
        .padding(.vertical, 12)
    }
}

struct LoadingView: View {
    let message: String

    var body: some View {
        HStack(spacing: 16) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(.appPrimary)

            Text(message)
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)

            Spacer()
        }
        .padding(.vertical, 20)
    }
}

struct ErrorView: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.appCaption)
                .foregroundColor(.appWarning)

            Text(message)
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)

            Spacer()
        }
        .padding(16)
        .background(Color.appWarning.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ShelterDetailView: View {
    let shelter: Shelter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.appInfo.opacity(0.2))
                                    .frame(width: 60, height: 60)

                                Image(systemName: "house.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.appInfo)
                            }

                            Spacer()

                            Button("Done") {
                                dismiss()
                            }
                            .font(.appCaption)
                            .foregroundColor(.appPrimary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(shelter.name)
                                .font(.appTitle)
                                .foregroundColor(.appTextPrimary)

                            Text(shelter.address)
                                .font(.appBody)
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                    .padding(20)
                    .appCardStyle()

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Shelter Information")
                            .font(.appHeadline)
                            .foregroundColor(.appTextPrimary)

                        VStack(spacing: 12) {
                            ResourceInfoRow(
                                icon: "checkmark.circle.fill",
                                title: "Status",
                                value: shelter.status,
                                color: .appSuccess
                            )

                            ResourceInfoRow(
                                icon: "person.2.fill",
                                title: "Capacity",
                                value: shelter.capacity,
                                color: .appInfo
                            )
                        }
                    }
                    .padding(20)
                    .appCardStyle()

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.appHeadline)
                            .foregroundColor(.appTextPrimary)

                        VStack(spacing: 12) {
                            ActionButton(
                                title: "Call Emergency Services",
                                subtitle: "Dial 911 for immediate assistance",
                                icon: "phone.fill",
                                color: .appError
                            ) {
                                if let url = URL(string: "tel:911") {
                                    UIApplication.shared.open(url)
                                }
                            }

                            ActionButton(
                                title: "Get Directions",
                                subtitle: "Open in Maps app",
                                icon: "map.fill",
                                color: .appInfo
                            ) {
                                let coordinate = shelter.coordinates
                                let url = URL(string: "http://maps.apple.com/?daddr=\(coordinate.latitude),\(coordinate.longitude)")
                                if let url = url {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .appCardStyle()

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(Color.appGradientBackground.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

struct ResourceInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)

                Text(value)
                    .font(.appBody)
                    .fontWeight(.medium)
                    .foregroundColor(.appTextPrimary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.appSubheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appTextPrimary)

                    Text(subtitle)
                        .font(.appCaption)
                        .foregroundColor(.appTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.appCaption)
                    .foregroundColor(.appTextTertiary)
            }
            .padding(16)
            .background(Color.appSurface)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ResourcesView()
}
