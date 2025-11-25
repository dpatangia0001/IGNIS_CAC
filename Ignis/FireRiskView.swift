import SwiftUI
import CoreLocation

struct FireRiskView: View {
    var body: some View {
        ZStack {

            Color.black
                .ignoresSafeArea(.all)

            AreaFireRiskMapView()
        }
    }
}

struct PersonalFireRiskView: View {
    @StateObject private var riskService = EnhancedFireRiskService.shared
    @StateObject private var locationManager = LocationManager.shared
    @State private var selectedFactor: RiskFactor?
    @State private var showingDetails = false

    var body: some View {
        NavigationView {
            ZStack {

                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.02, blue: 0.01),
                        Color(red: 0.1, green: 0.05, blue: 0.02)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let prediction = riskService.currentPrediction {
                            riskCard(prediction: prediction)
                            factorsSection(prediction: prediction)
                            recommendationsSection(prediction: prediction)
                        } else if riskService.isLoading {
                            loadingView
                        } else {
                            noDataView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Personal Fire Risk")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshRiskData()
            }
            .onAppear {
                Task {
                    await refreshRiskData()
                }
            }
        }
    }

    private func riskCard(prediction: AreaFireRiskPrediction) -> some View {
        VStack(spacing: 16) {

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Risk Level")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 12) {

                        ZStack {
                            Circle()
                                .fill(getRiskColor(for: prediction.riskLevel))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(color: getRiskColor(for: prediction.riskLevel).opacity(0.5), radius: 10)

                            Text("\(prediction.riskPercentage)%")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(prediction.riskLevel.rawValue.uppercased())
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            Text(prediction.riskLevel.description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Spacer()
                    }
                }

                Spacer()
            }

            HStack {
                Text("Confidence: \(Int(prediction.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Text("Updated: \(formatLastUpdated(prediction.lastUpdated))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.wsDark.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(getRiskColor(for: prediction.riskLevel).opacity(0.5), lineWidth: 2)
                )
        )
    }

    private func factorsSection(prediction: AreaFireRiskPrediction) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Factors")
                .font(.title2.bold())
                .foregroundColor(.white)

            LazyVStack(spacing: 12) {
                ForEach(prediction.factors) { factor in
                    RiskFactorCard(factor: factor) {
                        selectedFactor = factor
                        showingDetails = true
                    }
                }
            }
        }
    }

    private func recommendationsSection(prediction: AreaFireRiskPrediction) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.title2.bold())
                .foregroundColor(.white)

            VStack(spacing: 8) {
                ForEach(prediction.evacuationRoutes, id: \.self) { route in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: getRecommendationIcon(for: prediction.riskLevel))
                            .foregroundColor(getRiskColor(for: prediction.riskLevel))
                            .font(.caption)
                            .frame(width: 16)

                        Text(route)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wsDark.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(getRiskColor(for: prediction.riskLevel).opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.wsOrange)

            Text("Analyzing fire risk...")
                .font(.headline)
                .foregroundColor(.white)

            Text("This may take a moment")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.wsDark.opacity(0.8))
        )
    }

    private var noDataView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.wsOrange)

            Text("Unable to assess fire risk")
                .font(.headline)
                .foregroundColor(.white)

            if let error = riskService.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            } else {
                Text("Location or fire data not available")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            Button("Try Again") {
                Task {
                    await refreshRiskData()
                }
            }
            .foregroundColor(.wsOrange)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wsOrange.opacity(0.2))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.wsDark.opacity(0.8))
        )
    }

    private func refreshRiskData() async {
        _ = await riskService.predictFireRiskForCurrentLocation()
    }

    private func getRiskColor(for riskLevel: FireRiskLevel) -> Color {
        switch riskLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .extreme: return .red
        }
    }

    private func getRecommendationIcon(for riskLevel: FireRiskLevel) -> String {
        switch riskLevel {
        case .low: return "checkmark.circle"
        case .moderate: return "exclamationmark.triangle"
        case .high: return "exclamationmark.triangle.fill"
        case .extreme: return "flame.fill"
        }
    }

    private func formatLastUpdated(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RiskFactorCard: View {
    let factor: RiskFactor
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {

                Circle()
                    .fill(getImpactColor())
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(factor.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Text(factor.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Text("\(Int(factor.impact * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(getImpactColor())

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wsDark.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(getImpactColor().opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func getImpactColor() -> Color {
        if factor.impact > 0.5 {
            return .red
        } else if factor.impact > 0.2 {
            return .orange
        } else if factor.impact > -0.2 {
            return .yellow
        } else {
            return .green
        }
    }
}

struct RiskFactorDetailView: View {
    let factor: RiskFactor
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.02, blue: 0.01),
                        Color(red: 0.1, green: 0.05, blue: 0.02)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        VStack(spacing: 12) {
                            Text(factor.name)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text(factor.description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.wsDark.opacity(0.8))
                        )

                        VStack(alignment: .leading, spacing: 16) {
                            Text("Impact Analysis")
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack {
                                Text("Impact Level:")
                                    .foregroundColor(.white.opacity(0.8))

                                Spacer()

                                Text("\(Int(factor.impact * 100))%")
                                    .font(.headline.bold())
                                    .foregroundColor(getImpactColor())
                            }

                            HStack {
                                Text("Weight:")
                                    .foregroundColor(.white.opacity(0.8))

                                Spacer()

                                Text("\(Int(factor.weight * 100))%")
                                    .font(.headline.bold())
                                    .foregroundColor(.wsOrange)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.wsDark.opacity(0.6))
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Risk Factor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.wsOrange)
                }
            }
        }
    }

    private func getImpactColor() -> Color {
        if factor.impact > 0.5 {
            return .red
        } else if factor.impact > 0.2 {
            return .orange
        } else if factor.impact > -0.2 {
            return .yellow
        } else {
            return .green
        }
    }
}

#Preview {
    FireRiskView()
}
