import SwiftUI

struct HomePageView: View {

    @StateObject private var fireDataService = FireDataService.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var newsService = FireNewsService.shared
    @State private var showSideMenu: Bool = false
    @State private var showConfetti = false
    @State private var navigateToTab: Int? = nil
    @State private var hasAppeared = false
    @State private var animateHeader = false
    @State private var animateCards = false
    @State private var selectedCard: String? = nil
    @State private var titleGlow = false
    @State private var titleRotation = false

    @State private var activeFiresCount: Int = 0
    @State private var evacuationAlerts: Int = 0
    @State private var lastUpdated = "2 min ago"

    private var latestNewsFromService: [FireNews] { Array(newsService.items.prefix(3)) }

    private var fireRiskLevel: String {
        let activeFires = fireDataService.calFireIncidents.filter { $0.isActive }
        let totalAcres = activeFires.reduce(0) { $0 + $1.acresBurned }

        if totalAcres > 50000 || activeFires.count > 15 {
            return "Critical"
        } else if totalAcres > 20000 || activeFires.count > 10 {
            return "High"
        } else if totalAcres > 5000 || activeFires.count > 5 {
            return "Average"
        } else {
            return "Low"
        }
    }

    var body: some View {
        ZStack {

            Color.appGradientBackground
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 32) {
                    headerSection
                    combinedActionsSection
                    latestNewsSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                showConfetti = true
                fireDataService.start()
                newsService.startPeriodicUpdates()

                updateDynamicData()

                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    animateHeader = true
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                    animateCards = true
                }

                withAnimation(.easeInOut(duration: 2.0)) {
                    titleGlow = true
                }
                withAnimation(.easeInOut(duration: 3.0)) {
                    titleRotation = true
                }
            }
        }
        .onChange(of: fireDataService.calFireIncidents) { _, _ in

            updateDynamicData()
        }
        .onChange(of: navigateToTab) { _, newTab in
            if let tab = newTab {
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToTab"),
                    object: nil,
                    userInfo: ["tabIndex": tab]
                )
                navigateToTab = nil
            }
        }
    }

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {

                    ZStack {

                        Text("Ignis")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.appPrimary.opacity(0.3),
                                        Color.appSecondary.opacity(0.2)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .blur(radius: titleGlow ? 8 : 4)
                            .scaleEffect(titleGlow ? 1.1 : 1.0)

                        Text("Ignis")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.appGradientPrimary)
                            .shadow(color: Color.appPrimary.opacity(0.6), radius: titleGlow ? 12 : 6)

                        ForEach(0..<6, id: \.self) { index in
                            Circle()
                                .fill(Color.appGradientPrimary)
                                .frame(width: 4, height: 4)
                                .offset(
                                    x: CGFloat(cos(Double(index) * .pi / 3)) * (titleGlow ? 35 : 25),
                                    y: CGFloat(sin(Double(index) * .pi / 3)) * (titleGlow ? 35 : 25)
                                )
                                .opacity(titleGlow ? 0.0 : 0.4)
                                .scaleEffect(titleGlow ? 0.0 : 0.8)
                        }
                    }
                    .scaleEffect(animateHeader ? 1.0 : 0.8)
                    .opacity(animateHeader ? 1.0 : 0.0)
                    .rotation3DEffect(
                        .degrees(titleRotation ? 2 : -2),
                        axis: (x: 0, y: 1, z: 0)
                    )

                    Text("Wildfire Safety")
                        .font(.appSubheadline)
                        .foregroundColor(.appTextSecondary)
                        .opacity(animateHeader ? 1.0 : 0.0)
                        .offset(x: animateHeader ? 0 : -20)
                }
                Spacer()

                Button(action: {
                    locationManager.requestLocationPermission()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.appGradientPrimary)
                            .frame(width: 50, height: 50)
                            .shadow(color: Color.appPrimary.opacity(0.4), radius: 8, x: 0, y: 4)

                        Image(systemName: locationManager.authorizationStatus == .authorizedWhenInUse ? "location.fill" : "location")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(animateHeader ? 1.0 : 0.8)
                .opacity(animateHeader ? 1.0 : 0.0)
            }

            HStack(spacing: 12) {
                StatusIndicator(title: "Fire Risk", value: fireRiskLevel, color: riskColor, icon: "flame.fill")
                StatusIndicator(title: "Active Fires", value: "\(activeFiresCount)", color: .appPrimary, icon: "fire.fill")
                StatusIndicator(title: "Alerts", value: "\(evacuationAlerts)", color: .appWarning, icon: "exclamationmark.triangle.fill")
                Spacer()
                Text("Updated \(lastUpdated)")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.appTextTertiary)
            }
            .padding(16)
            .appCardStyle()
            .offset(y: animateHeader ? 0 : 20)
            .opacity(animateHeader ? 1.0 : 0.0)
        }
    }

    var combinedActionsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Quick Actions & Features")
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)
                .opacity(animateCards ? 1.0 : 0.0)
                .offset(y: animateCards ? 0 : 20)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                CircularActionButton(
                    title: "Emergency",
                    icon: "phone.fill",
                    action: { callEmergency() }
                )
                .offset(x: animateCards ? 0 : -30)
                .opacity(animateCards ? 1.0 : 0.0)

                CircularActionButton(
                    title: "Fire Map",
                    icon: "map.fill",
                    action: { navigateToTab = 4 }
                )
                .offset(x: animateCards ? 0 : 30)
                .opacity(animateCards ? 1.0 : 0.0)

                CircularActionButton(
                    title: "Risk",
                    icon: "flame.fill",
                    action: { navigateToTab = 8 }
                )
                .offset(x: animateCards ? 0 : -30)
                .opacity(animateCards ? 1.0 : 0.0)

                CircularActionButton(
                    title: "Support",
                    icon: "heart.fill",
                    action: { navigateToTab = 1 }
                )
                .offset(x: animateCards ? 0 : 30)
                .opacity(animateCards ? 1.0 : 0.0)

                CircularActionButton(
                    title: "Chat",
                    icon: "message.fill",
                    action: { navigateToTab = 0 }
                )
                .offset(x: animateCards ? 0 : -30)
                .opacity(animateCards ? 1.0 : 0.0)

                CircularActionButton(
                    title: "Learn",
                    icon: "book.fill",
                    action: { navigateToTab = 3 }
                )
                .offset(x: animateCards ? 0 : 30)
                .opacity(animateCards ? 1.0 : 0.0)

                CircularActionButton(
                    title: "Community",
                    icon: "person.3.fill",
                    action: { navigateToTab = 5 }
                )
                .offset(x: animateCards ? 0 : -30)
                .opacity(animateCards ? 1.0 : 0.0)

                CircularActionButton(
                    title: "Resources",
                    icon: "gift.fill",
                    action: { navigateToTab = 6 }
                )
                .offset(x: animateCards ? 0 : 30)
                .opacity(animateCards ? 1.0 : 0.0)
            }
        }
    }

    var latestNewsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Latest News")
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)
                .opacity(animateCards ? 1.0 : 0.0)
                .offset(y: animateCards ? 0 : 20)

            if latestNewsFromService.isEmpty {

                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.appGradientPrimary)
                            .frame(width: 40, height: 40)

                        Image(systemName: "newspaper")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    Text("No recent news")
                        .font(.appSubheadline)
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                }
                .padding(20)
                .appCardStyle()
                .opacity(animateCards ? 1.0 : 0.0)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(latestNewsFromService.enumerated()), id: \.element.id) { index, item in
                        SimpleNewsCard(item: item)
                            .offset(x: animateCards ? 0 : (index % 2 == 0 ? -30 : 30))
                            .opacity(animateCards ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.8).delay(Double(index) * 0.1), value: animateCards)
                    }
                }
            }
        }
    }

    private func callEmergency() {
        if let url = URL(string: "tel:911") {
            UIApplication.shared.open(url)
        }
    }

    private func updateDynamicData() {

        activeFiresCount = fireDataService.calFireIncidents.filter { $0.isActive }.count

        evacuationAlerts = fireDataService.calFireIncidents.filter { $0.isActive && $0.acresBurned > 1000 }.count

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        lastUpdated = formatter.localizedString(for: Date(), relativeTo: Date())
    }

    private var riskColor: Color {
        switch fireRiskLevel {
        case "Critical": return .appError
        case "High": return .appPrimary
        case "Moderate": return .appWarning
        default: return .appSuccess
        }
    }
}

struct StatusIndicator: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundColor(.appTextTertiary)
                Text(value)
                    .font(.system(size: 11, weight: .semibold, design: .default))
                    .foregroundColor(.appTextPrimary)
            }
        }
    }
}

struct CircularActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            action()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.appGradientPrimary)
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.appPrimary.opacity(0.4), radius: 8, x: 0, y: 4)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(.appCaption)
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

struct SimpleNewsCard: View {
    let item: FireNews
    @Environment(\.openURL) private var openURL
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            if let url = item.url { openURL(url) }
        }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.appSubheadline)
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(item.date)
                        .font(.appCaption)
                        .foregroundColor(.appTextSecondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
            }
            .padding(20)
            .appCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
    }
}
