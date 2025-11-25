import SwiftUI

extension Notification.Name {
    static let enterIgnis = Notification.Name("enterIgnis")
}

struct LandingPageView: View {

    @State private var hoveredCard: StatCardType? = nil
    @State private var ashParticles: [AshParticle] = []
    @State private var burningAshParticles: [BurningAshParticle] = []
    @State private var hoveredPanel: Int? = nil
    @State private var isButtonHovered = false
    @State private var buttonGlowIntensity: Double = 0.0

    let onStartNow: () -> Void

    @StateObject private var fireDataService = FireDataService.shared

    var body: some View {
        ZStack {

            fireAshBackground

            ScrollView {
                VStack(spacing: 40) {

                    imagePanelsSection

                    titleAndCTASection

                    statisticsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            generateAshParticles()
            generateBurningAshParticles()
            animateButtonGlow()
            fireDataService.start()
        }
    }

    private var fireAshBackground: some View {
        ZStack {

            Color.appBackground
                .ignoresSafeArea()

            ForEach(ashParticles) { particle in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .animation(
                        Animation.linear(duration: particle.duration)
                            .repeatForever(autoreverses: false),
                        value: particle.position
                    )
            }

            ForEach(burningAshParticles) { particle in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.6),
                                Color.red.opacity(0.4),
                                Color.gray.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .animation(
                        Animation.easeOut(duration: particle.duration)
                            .repeatForever(autoreverses: false),
                        value: particle.position
                    )
            }

            RadialGradient(
                colors: [
                    Color.orange.opacity(0.15),
                    Color.red.opacity(0.08),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }

    private var imagePanelsSection: some View {
        HStack(spacing: 10) {
            ForEach(0..<3) { index in
                imagePanel(for: index)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 160)
        .padding(.horizontal, 20)
    }

    private func imagePanel(for index: Int) -> some View {
        Group {
            if index == 0 {

                Image("fire_panel")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 115, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if index == 1 {

                Image("emergency_panel")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 132, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {

                Image("evacuation_panel")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 115, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .shadow(color: .appPrimary.opacity(0.4), radius: 15, x: 0, y: 8)
    }

    private var titleAndCTASection: some View {
        VStack(spacing: 24) {

            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ZStack {

                        Image(systemName: "flame.fill")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .appPrimary.opacity(0.6), radius: 10, x: 0, y: 5)

                        ForEach(0..<8) { i in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.orange.opacity(0.8),
                                            Color.red.opacity(0.6),
                                            Color.gray.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: CGFloat.random(in: 2...4))
                                .offset(
                                    x: CGFloat.random(in: -15...15),
                                    y: CGFloat.random(in: -25 ... -15)
                                )
                                .opacity(Double.random(in: 0.3...0.7))
                                .animation(
                                    Animation.easeOut(duration: Double.random(in: 1...2))
                                        .repeatForever(autoreverses: false),
                                    value: i
                                )
                        }
                    }

                    Text("IGNIS")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(
                                                    LinearGradient(
                            colors: [.appTextPrimary, .appPrimary, .appSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        )
                }

                Text("Protecting lives from wildfire threats - in real time")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .italic()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appTextSecondary, .appPrimary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .shadow(color: .appPrimary.opacity(0.6), radius: 15, x: 0, y: 8)

            Button(action: { onStartNow() }) {
                Text("START NOW")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(width: 200, height: 50)
                    .background(
                        LinearGradient(
                            colors: isButtonHovered ? [
                                Color.appPrimary,
                                Color.appSecondary,
                                Color.appAccent
                            ] : [
                                Color.appPrimary.opacity(0.9),
                                Color.appSecondary.opacity(0.8),
                                Color.appAccent.opacity(0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(
                        color: isButtonHovered ? .appPrimary.opacity(0.6) : .appPrimary.opacity(0.5 + buttonGlowIntensity * 0.3),
                        radius: isButtonHovered ? 15 : 12 + buttonGlowIntensity * 8,
                        x: 0,
                        y: isButtonHovered ? 8 : 6 + buttonGlowIntensity * 4
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.appPrimary.opacity(0.6 + buttonGlowIntensity * 0.4), .appSecondary.opacity(0.4 + buttonGlowIntensity * 0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1 + buttonGlowIntensity * 2
                            )
                    )
                    .scaleEffect(isButtonHovered ? 1.05 : 1.0 + buttonGlowIntensity * 0.05)
                    .animation(.easeInOut(duration: 0.2), value: isButtonHovered)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: buttonGlowIntensity)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                isButtonHovered = hovering
            }
        }
    }

    private var statisticsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            StatCard(
                type: .assistedSurvivors,
                value: fireDataService.nasaFireStatistics?.activeFiresLast24Hours ?? 0,
                icon: "flame.fill",
                iconColor: .orange,
                label: "Active fires (24h)",
                isHovered: false,
                isLoading: fireDataService.isLoading || fireDataService.nasaFireStatistics == nil
            ) {

            } onHoverExit: {

            }

            StatCard(
                type: .injuriesPrevented,
                value: fireDataService.nasaFireStatistics?.totalFirePoints ?? 0,
                icon: "location.fill",
                iconColor: .blue,
                label: "Fire detections",
                isHovered: false,
                isLoading: fireDataService.isLoading || fireDataService.nasaFireStatistics == nil
            ) {

            } onHoverExit: {

            }

            StatCard(
                type: .routesProvided,
                value: fireDataService.nasaFireStatistics?.highConfidenceFiresLast24Hours ?? 0,
                icon: "exclamationmark.triangle.fill",
                iconColor: .red,
                label: "High confidence fires",
                isHovered: false,
                isLoading: fireDataService.isLoading || fireDataService.nasaFireStatistics == nil
            ) {

            } onHoverExit: {

            }

            StatCard(
                type: .homesProtected,
                value: Int(fireDataService.nasaFireStatistics?.totalFireRadiativePower ?? 0),
                icon: "bolt.fill",
                iconColor: .yellow,
                label: "Total fire power (MW)",
                isHovered: false,
                isLoading: fireDataService.isLoading || fireDataService.nasaFireStatistics == nil
            ) {

            } onHoverExit: {

            }
        }
        .padding(.horizontal, 40)
    }

    private func imageIcon(for index: Int) -> String {
        switch index {
        case 0: return "flame.circle.fill"
        case 1: return "shield.lefthalf.filled"
        case 2: return "figure.wave"
        default: return "photo"
        }
    }

    private func imageIconColor(for index: Int) -> LinearGradient {
        switch index {
        case 0: return LinearGradient(colors: [.orange, .red, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1: return LinearGradient(colors: [.blue, .cyan, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2: return LinearGradient(colors: [.green, .mint, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return LinearGradient(colors: [.gray, .white], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func imageTitle(for index: Int) -> String {
        switch index {
        case 0: return "Active Fire"
        case 1: return "Emergency Response"
        case 2: return "Safe Evacuation"
        default: return "Scene"
        }
    }

    private func imageSubtitle(for index: Int) -> String {
        switch index {
        case 0: return "Live fire map &\nalert system"
        case 1: return "Professional teams\nresponding to emergencies"
        case 2: return "Guided evacuation\nroutes to safety"
        default: return "Scene description"
        }
    }

    private func generateAshParticles() {
        ashParticles = (0..<50).map { _ in
            AshParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: UIScreen.main.bounds.height + 50
                ),
                size: CGFloat.random(in: 2...8),
                opacity: Double.random(in: 0.1...0.4),
                duration: Double.random(in: 8...15)
            )
        }

        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            for i in ashParticles.indices {
                ashParticles[i].position.y = -50
            }
        }
    }

    private func generateBurningAshParticles() {
        burningAshParticles = (0..<30).map { _ in
            BurningAshParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: UIScreen.main.bounds.height + 20
                ),
                size: CGFloat.random(in: 1...4),
                opacity: Double.random(in: 0.2...0.6),
                duration: Double.random(in: 3...8)
            )
        }

        withAnimation(.easeOut(duration: 6).repeatForever(autoreverses: false)) {
            for i in burningAshParticles.indices {
                burningAshParticles[i].position.y = -20
            }
        }
    }

    private func refreshFireData() {

    }

    private func animateButtonGlow() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            buttonGlowIntensity = 1.0
        }
    }

    private func enterIgnis() {

        NotificationCenter.default.post(name: .enterIgnis, object: nil)
    }

}

struct AshParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let opacity: Double
    let duration: Double
}

struct BurningAshParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let opacity: Double
    let duration: Double
}

enum StatCardType {
    case assistedSurvivors
    case injuriesPrevented
    case routesProvided
    case homesProtected
}

struct StatCard: View {
    let type: StatCardType
    let value: Int
    let icon: String
    let iconColor: Color
    let label: String
    let isHovered: Bool
    let isLoading: Bool
    let onHover: () -> Void
    let onHoverExit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [iconColor, iconColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: iconColor.opacity(0.5), radius: 4, x: 0, y: 2)

            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.appTextPrimary))
                        .scaleEffect(1.2)
                } else {
                    Text("\(value)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appTextPrimary)
                }
            }
            .frame(height: 40)

            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    Color.appCard
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isHovered ?
                            LinearGradient(
                                colors: [.appPrimary, .appSecondary, iconColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [.clear, .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isHovered ? 2 : 0
                        )
                )
        )
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .shadow(
            color: isHovered ? iconColor.opacity(0.4) : Color.black.opacity(0.8),
            radius: isHovered ? 12 : 15,
            x: 0,
            y: isHovered ? 6 : 8
        )
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            if hovering {
                onHover()
            } else {
                onHoverExit()
            }
        }
    }
}

#Preview {
    LandingPageView(onStartNow: {})
}
