import SwiftUI
import MapKit
import Combine
import UIKit

struct WildfireMap: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.25, longitude: -120.0),
            span: MKCoordinateSpan(latitudeDelta: 8.0, longitudeDelta: 8.0)
        )
    )

    @State private var currentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.25, longitude: -120.0),
        span: MKCoordinateSpan(latitudeDelta: 8.0, longitudeDelta: 8.0)
    )

    @State private var selectedIncident: CALFireIncident?

    @StateObject private var dataService = FireDataService.shared
    @StateObject private var locationManager = LocationManager.shared

    var body: some View {
            ZStack {
                        Map(position: $cameraPosition, interactionModes: [.pan, .rotate]) {
                ForEach(dataService.calFireIncidents) { incident in
                    let coord = CLLocationCoordinate2D(latitude: incident.latitude, longitude: incident.longitude)
                    Annotation(incident.name, coordinate: coord) {
                    Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedIncident = incident
                            }
                        }) {
                            ZStack {

                    Circle()
                                    .fill(Color.appSurface)
                                    .frame(width: 44, height: 44)

                Circle()
                                    .fill(Color.appCard)
                                    .frame(width: 40, height: 40)

                Image(systemName: "flame.fill")
                                    .foregroundColor(flameColor(for: incident))
                            .font(.title2)
                                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)

                                Circle()
                                    .stroke(flameColor(for: incident).opacity(0.4), lineWidth: 1)
                                    .frame(width: 44, height: 44)
            }
        }
        .scaleEffect(reduceMotion ? 1.0 : (selectedIncident?.id == incident.id ? 1.1 : 1.0))
        .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7), value: selectedIncident?.id)
        .buttonStyle(PlainButtonStyle())
        .contentShape(Circle())
        .accessibilityLabel("\(incident.name), \(incident.statusText), \(Int(incident.percentContained)) percent contained")
        .accessibilityHint("Opens fire details")
        .accessibilityAddTraits(.isButton)
    }
                }
            }
            .mapControls { MapCompass() }
            .ignoresSafeArea()
            .contentShape(Rectangle())

            Color.black.opacity(0.1)
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack {
            Spacer()
                    .allowsHitTesting(false)

                HStack {
                    Spacer()
                        .allowsHitTesting(false)
                    VStack(spacing: 8) {

                        Button(action: zoomIn) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.appTextPrimary)
                                .frame(width: 44, height: 44)
                                .background(Color(red: 0.08, green: 0.08, blue: 0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                        }

                        Button(action: zoomOut) {
                            Image(systemName: "minus")
                                .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.appTextPrimary)
                                .frame(width: 44, height: 44)
                                .background(Color(red: 0.08, green: 0.08, blue: 0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    }

                        Button(action: recenterToUser) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.appTextPrimary)
                                .frame(width: 44, height: 44)
                                .background(Color(red: 0.08, green: 0.08, blue: 0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                        }
                }
                .padding(.trailing, 16)
                    .padding(.bottom, 140)
                }
                .allowsHitTesting(true)
            }
        }
        .onMapCameraChange(frequency: .continuous) { context in

            currentRegion = context.region
        }
        .sheet(item: $selectedIncident) { incident in
            FireIncidentDetailView(incident: incident)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task { dataService.start() }
    }

    private func flameColor(for incident: CALFireIncident) -> Color {

        if !incident.isActive {
            return .gray
        }

        let acres = incident.acresBurned

        if acres > 10000 {
            return .red
        } else {
            return .orange
        }
    }

    private func zoomIn() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let newSpan = MKCoordinateSpan(
            latitudeDelta: max(currentRegion.span.latitudeDelta * 0.5, 0.01),
            longitudeDelta: max(currentRegion.span.longitudeDelta * 0.5, 0.01)
        )
        currentRegion = MKCoordinateRegion(center: currentRegion.center, span: newSpan)
        cameraPosition = .region(currentRegion)
    }

    private func zoomOut() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let newSpan = MKCoordinateSpan(
            latitudeDelta: min(currentRegion.span.latitudeDelta * 2.0, 180.0),
            longitudeDelta: min(currentRegion.span.longitudeDelta * 2.0, 360.0)
        )
        currentRegion = MKCoordinateRegion(center: currentRegion.center, span: newSpan)
        cameraPosition = .region(currentRegion)
    }

    private func recenterToUser() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if let loc = locationManager.location?.coordinate {
                let region = MKCoordinateRegion(
                    center: loc,
                    span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
                )
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.easeInOut(duration: reduceMotion ? 0 : 0.25)) {
                    currentRegion = region
                    cameraPosition = .region(region)
                }
            } else {
                locationManager.startLocationUpdates()
            }
        case .notDetermined:
            locationManager.requestLocationPermission()
        case .denied, .restricted:

            break
        @unknown default:
            break
        }
    }
}

struct FireIncidentDetailView: View {
    let incident: CALFireIncident
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var evacuationSummary: String? = nil
    @State private var isLoadingEvac: Bool = false
    @State private var evacInfo: EvacuationInfo? = nil
    @State private var details: CalFireIncidentDetail? = nil
    @State private var isLoadingDetails: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {

                Color.appGradientBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        headerSection

                        statusSection

                        metricsSection

                        locationSection

                        additionalInfoSection

                        evacuationSection

                        if let d = details, let items = d.roadClosures, !items.isEmpty {
                            roadClosuresSection(items: items)
                        }

                        if let d = details, let shelters = d.sheltersStructured, !shelters.isEmpty {
                            evacuationSheltersSection(shelters: shelters)
                        }

                        if let d = details, let teps = d.tepsStructured, !teps.isEmpty {
                            temporaryEvacuationPointsSection(teps: teps)
                        }

                        if let d = details, let resources = d.resourcesMetrics, !resources.isEmpty {
                            resourcesAssignedSection(resources: resources)
                        }

                        detailSections

                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Fire Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    dismiss()
                                }
                    .foregroundColor(.appPrimary)
                }
            }
        }
    }

    private var evacuationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Circle().fill(Color.red).frame(width: 10, height: 10)
                Text("Evacuation Order - Level 3 - Go")
                    .font(.headline.weight(.semibold))
                        .foregroundColor(.appTextPrimary)
                    Spacer()
            }
            .opacity((evacInfo?.orders.isEmpty ?? true) ? 0.4 : 1)

            if let orders = evacInfo?.orders, !orders.isEmpty {
                ForEach(orders.keys.sorted(), id: \.self) { county in
                    let zones = orders[county] ?? []
                    EvacCard(title: county, color: Color.red.opacity(0.12), dot: .red, lines: "Zones: \(zones.joined(separator: ", "))")
                }
            } else {

                EvacCard(
                    title: "No evacuation order in place",
                    color: Color.red.opacity(0.06),
                    dot: .gray,
                    lines: "Please stay on standby for any upcoming alerts."
                )
            }

            HStack(spacing: 10) {
                Circle().fill(Color.yellow).frame(width: 10, height: 10)
                Text("Evacuation Warning - Level 2 - Set")
                    .font(.headline.weight(.semibold))
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                    }
            .padding(.top, 6)
            .opacity((evacInfo?.warnings.isEmpty ?? true) ? 0.4 : 1)

            if let warnings = evacInfo?.warnings, !warnings.isEmpty {
                ForEach(warnings.keys.sorted(), id: \.self) { county in
                    let zones = warnings[county] ?? []
                    EvacCard(title: county, color: Color.yellow.opacity(0.12), dot: .yellow, lines: "Zones: \(zones.joined(separator: ", "))")
                }
            }

            if (evacInfo?.orders.isEmpty ?? true) && (evacInfo?.warnings.isEmpty ?? true) {
                Button(action: { if let url = URL(string: incident.url) { openURL(url) } }) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.appPrimary)
                        Text("View current evacuation orders and warnings")
                            .foregroundColor(.appPrimary)
                            .font(.subheadline.bold())
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.appPrimary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appButtonSecondary)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appPrimary.opacity(0.3), lineWidth: 1))
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appPrimary.opacity(0.3), lineWidth: 1))
        )
        .task { await loadEvacuationInfoIfNeeded() }
    }

    private var detailSections: some View {
        VStack(spacing: 16) {
            Group {
                if isLoadingDetails {
                    ProgressView("Loading incident details...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.appTextPrimary)
                        .padding()
                } else {
                    if let d = details {

                        EmptyView().transaction { $0.disablesAnimations = true }
                        if let items = d.animalEvacuationShelters, !items.isEmpty { bulletCard(title: "Animal Evacuation Shelters", items: items, icon: "pawprint.fill") }
                        if let metrics = d.damageMetrics, !metrics.isEmpty { metricsCard(title: "Damage Assessment", metrics: metrics, icon: "building.2.crop.circle") }
                    } else {
                        Button(action: { if let url = URL(string: incident.url) { openURL(url) } }) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill").foregroundColor(.appPrimary)
                                Text("View full incident details on CAL FIRE")
                                    .foregroundColor(.appPrimary)
                                    .font(.subheadline.bold())
                                Spacer()
                                Image(systemName: "arrow.up.right").foregroundColor(.appPrimary)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appButtonSecondary)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appPrimary.opacity(0.3), lineWidth: 1))
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appPrimary.opacity(0.3), lineWidth: 1))
        )
        .task { await loadDetailsIfNeeded() }
    }

    private func roadClosuresSection(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 10) {
                Image(systemName: "road.lanes")
                    .foregroundColor(.appPrimary)
                    .font(.title2)
                Text("Road Closures")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(Array(items.prefix(6)), id: \.self) { roadClosure in
                    roadClosureCard(roadClosure: roadClosure)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private func roadClosureCard(roadClosure: String) -> some View {
        HStack(alignment: .top, spacing: 12) {

            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.title3)
                .frame(width: 24, height: 24)

            Text(roadClosure)
                .font(.subheadline)
                .foregroundColor(.appTextPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func resourcesAssignedSection(resources: [ResourceMetric]) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 10) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundColor(.appPrimary)
                    .font(.title2)
                Text("Resources Assigned")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(resources.enumerated()), id: \.element) { index, resource in
                    resourceMetricTile(resource: resource)
                        .gridCellColumns(resources.count % 2 == 1 && index == resources.count - 1 ? 2 : 1)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private func resourceMetricTile(resource: ResourceMetric) -> some View {
        VStack(spacing: 8) {
            Text(resource.value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.appTextPrimary)
                .monospacedDigit()

            Text(resource.label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(minHeight: 80)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appPrimary.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func bulletCard(title: String, items: [String], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.appPrimary)
                    .font(.title2)
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(items.prefix(8)), id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)

                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(.appTextPrimary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private func shelterCard(title: String, shelters: [ShelterInfo], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.appPrimary)
                    .font(.title2)
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(shelters.prefix(3)), id: \.self) { shelter in
                    VStack(alignment: .leading, spacing: 8) {

                        Text(shelter.name)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.appTextPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if let address = shelter.address {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.appTextSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        if let note = shelter.note {
                            Text(note)
                                .font(.footnote)
                                .foregroundColor(.appPrimary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appCard.opacity(0.3))
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private func tepCard(title: String, teps: [TEPInfo], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.appPrimary)
                    .font(.title2)
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(teps.prefix(3)), id: \.self) { tep in
                    VStack(alignment: .leading, spacing: 8) {

                        Text(tep.name)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.appTextPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if let address = tep.address {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.appTextSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        if let hours = tep.hours {
                            Text(hours)
                                .font(.footnote.weight(.medium))
                                .foregroundColor(.appPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appCard.opacity(0.3))
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private func metricsCard(title: String, metrics: [ResourceMetric], icon: String) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        let cappedMetrics = Array(metrics.prefix(8))

        return VStack(alignment: .leading, spacing: 16) {

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.appPrimary)
                    .font(.title2)
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }

            if title.contains("Damage") {
                Text("Confirmed Damage to Property, Injuries, and Fatalities.")
                    .font(.subheadline)
                    .foregroundColor(.appTextTertiary)
                    .padding(.bottom, 8)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(cappedMetrics.enumerated()), id: \.offset) { pair in
                    let metric = pair.element
                    VStack(spacing: 6) {
                        Text(metric.value)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.appTextPrimary)
                            .monospacedDigit()

                        Text(metric.label)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(minHeight: 80)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appPrimary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .gridCellColumns(cappedMetrics.count % 2 == 1 && pair.offset == cappedMetrics.count - 1 ? 2 : 1)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private func loadDetailsIfNeeded() async {
        guard details == nil, !isLoadingDetails, !incident.url.isEmpty else { return }
        isLoadingDetails = true
        defer { isLoadingDetails = false }
        if let d = await CalFireDetailService.shared.details(for: incident.url) {
            await MainActor.run { self.details = d }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {

        ZStack {
                                Circle()
                    .fill(Color.appSurface)
                    .frame(width: 80, height: 80)

                                        Circle()
                    .fill(Color.appCard)
                    .frame(width: 70, height: 70)

                Image(systemName: "flame.fill")
                    .foregroundColor(flameColorForDetail(incident))
                    .font(.system(size: 32))
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
            }

            Text(incident.name)
                            .font(.title2)
                .fontWeight(.bold)
                            .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var statusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: incident.isActive ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(incident.isActive ? .red : .green)
                    .font(.title3)

                Text(incident.statusText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(incident.isActive ? .red : .green)

                Spacer()
                            }

            VStack(alignment: .leading, spacing: 8) {
                            HStack {
                    Text("Containment")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                                Spacer()
                    Text("\(Int(incident.percentContained))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appPrimary)
                }

                ProgressView(value: incident.percentContained / 100.0)
                    .tint(.appPrimary)
                    .scaleEffect(y: 2)
            }
        }
        .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                    )
            )
    }

    private var metricsSection: some View {
                        VStack(spacing: 16) {
            HStack {
                Text("Fire Metrics")
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }

            HStack(spacing: 16) {

                FireMetricCard(
                    icon: "flame.fill",
                    title: "Acres Burned",
                    value: formatAcres(incident.acresBurned),
                    color: .red
                )

                FireMetricCard(
                    icon: "thermometer.high",
                    title: "Intensity",
                    value: intensityText(incident.intensityLevel),
                    color: intensityColor(incident.intensityLevel)
                )
            }
        }
    }

    private var locationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Location")
                                    .font(.headline)
                                    .foregroundColor(.appTextPrimary)
                Spacer()
                            }

                VStack(spacing: 12) {
                InfoRow(icon: "location.fill", title: "County", value: incident.county)
                InfoRow(icon: "mappin.and.ellipse", title: "Location", value: incident.location)
                InfoRow(icon: "globe", title: "Coordinates", value: "\(String(format: "%.4f", incident.latitude)), \(String(format: "%.4f", incident.longitude))")
            }
            .padding(16)
                            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCard)
                                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
    }

    private var additionalInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Additional Information")
                                        .font(.headline)
                                        .foregroundColor(.appTextPrimary)
            Spacer()
                                }

                VStack(spacing: 12) {
                InfoRow(icon: "calendar", title: "Started", value: formatDate(incident.startedDate))

                if !incident.url.isEmpty {
            HStack {
                        Image(systemName: "link")
                            .foregroundColor(.appPrimary)
                            .frame(width: 20)

                        Text("More Info")
                            .foregroundColor(.appTextSecondary)
                            .font(.subheadline)

                Spacer()

                        Link("View Details", destination: URL(string: incident.url) ?? URL(string: "https://fire.ca.gov")!)
                            .foregroundColor(.appPrimary)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(16)
                            .background(
                                    RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCard)
                .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }

    private func flameColorForDetail(_ incident: CALFireIncident) -> Color {
        if !incident.isActive {
            return .gray
        }
        return incident.acresBurned > 10000 ? .red : .orange
    }

    private func formatAcres(_ acres: Double) -> String {
        if acres >= 1000 {
            return String(format: "%.1fK", acres / 1000)
        } else {
            return String(format: "%.0f", acres)
        }
    }

    private func intensityText(_ level: Int) -> String {
        switch level {
        case 0: return "Low"
        case 1: return "Medium"
        case 2: return "High"
        case 3: return "Extreme"
        default: return "Unknown"
        }
    }

    private func intensityColor(_ level: Int) -> Color {
        switch level {
        case 0: return .green
        case 1: return .yellow
        case 2: return .orange
        case 3: return .red
        default: return .gray
        }
    }

    private func formatDate(_ dateString: String) -> String {
        if dateString.isEmpty {
            return "Unknown"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        if let date = formatter.date(from: String(dateString.prefix(10))) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }

        return dateString
    }

    private func extractZones(afterAny headers: [String], in html: String) -> [String: [String]] {

        var candidateRanges: [Range<String.Index>] = []
        for h in headers {
            var searchStart = html.startIndex
            while let r = html.range(of: h, options: [.caseInsensitive], range: searchStart..<html.endIndex) {
                candidateRanges.append(r)
                searchStart = r.upperBound
            }
        }
        if candidateRanges.isEmpty { return [:] }

        let zonePattern = "[A-Z]{2,4}-\\d{1,4}[A-Z]?"
        let zoneRegex = try? NSRegularExpression(pattern: zonePattern)
        let countyRegex = try? NSRegularExpression(pattern: "[A-Z][A-Za-z\\- ]+ County")

        var chosenText: String? = nil
        for r in candidateRanges.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            let window = String(html[r.upperBound...].prefix(4000))
            let text = window
                .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "&nbsp;", with: " ")
            let hasZones = (zoneRegex?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil)
            let hasCounty = (countyRegex?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil)
            if hasZones || hasCounty { chosenText = text; break }
        }
        guard let text = chosenText else { return [:] }

        var result: [String: [String]] = [:]
        let countyMatches = countyRegex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        for m in countyMatches {
            guard let cr = Range(m.range, in: text) else { continue }
            let countyName = String(text[cr])
            let tail = String(text[cr.upperBound...].prefix(800))
            let matches = zoneRegex?.matches(in: tail, range: NSRange(tail.startIndex..., in: tail)) ?? []
            let zones = matches.compactMap { Range($0.range, in: tail).map { String(tail[$0]) } }
            if !zones.isEmpty { result[countyName] = Array(Set(zones)).sorted() }
        }

        if result.isEmpty {
            let matches = zoneRegex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
            let zones = matches.compactMap { Range($0.range, in: text).map { String(text[$0]) } }
            if !zones.isEmpty { result["Affected Areas"] = Array(Set(zones)).sorted() }
        }
        return result
    }

    private func loadEvacuationInfoIfNeeded() async {
        guard evacuationSummary == nil else { return }
        guard let pageURL = URL(string: incident.url) else { return }
        isLoadingEvac = true
        defer { isLoadingEvac = false }
        do {
            let (data, _) = try await URLSession.shared.data(from: pageURL)
            if let html = String(data: data, encoding: .utf8) {

                let orders = extractZones(afterAny: [
                    "Evacuation Orders",
                    "Evacuation Order",
                    "Level 3",
                    "Level 3 - Go"
                ], in: html)
                let warnings = extractZones(afterAny: [
                    "Evacuation Warnings",
                    "Evacuation Warning",
                    "Level 2",
                    "Level 2 - Set"
                ], in: html)
                self.evacInfo = EvacuationInfo(orders: orders, warnings: warnings)

                evacuationSummary = orders.isEmpty && warnings.isEmpty ? nil : "parsed"
            }
        } catch {

        }
    }

    private func evacuationSheltersSection(shelters: [ShelterInfo]) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 10) {
                Image(systemName: "house.fill")
                    .foregroundColor(.appPrimary)
                    .font(.title2)
                Text("Evacuation Shelters")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(Array(shelters.prefix(4)), id: \.self) { shelter in
                    evacuationShelterCard(shelter: shelter)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private func evacuationShelterCard(shelter: ShelterInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "house.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 6) {

                    Text(shelter.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let address = shelter.address {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func temporaryEvacuationPointsSection(teps: [TEPInfo]) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 10) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.appPrimary)
                    .font(.title2)
                Text("Temporary Evacuation Points")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(Array(teps.prefix(4)), id: \.self) { tep in
                    individualTEPCard(tep: tep)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }

    private func individualTEPCard(tep: TEPInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.2.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 6) {

                    Text(tep.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let address = tep.address {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()

                HStack(spacing: 12) {

                    Button(action: {
                        openInMaps(address: tep.address ?? tep.name)
                    }) {
                        Image(systemName: "map.fill")
                            .foregroundColor(.appPrimary)
                            .font(.title3)
                            .frame(width: 24, height: 24)
                    }

                    Button(action: {
                        openDirections(address: tep.address ?? tep.name)
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.appPrimary)
                            .font(.title3)
                            .frame(width: 24, height: 24)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func openInMaps(address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(encodedAddress)") {
            openURL(url)
        }
    }

    private func openDirections(address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?daddr=\(encodedAddress)&dirflg=d") {
            openURL(url)
        }
    }
}

private struct EvacuationInfo {
    let orders: [String: [String]]
    let warnings: [String: [String]]
}

private struct EvacCard: View {
    let title: String
    let color: Color
    let dot: Color
    let lines: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("- \(title) -")
                .font(.headline.weight(.semibold))
                                        .foregroundColor(.appTextPrimary)

            HStack(alignment: .top, spacing: 8) {
                Circle().fill(dot).frame(width: 8, height: 8).padding(.top, 6)
                Text(lines)
                    .foregroundColor(.appTextPrimary)
                                        .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                .fill(color)
        )
    }
}
struct FireMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                                        .foregroundColor(.appTextPrimary)

            Text(title)
                                .font(.caption)
                .foregroundColor(.appTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.appPrimary)
                .frame(width: 20)

            Text(title)
                .foregroundColor(.appTextSecondary)
                .font(.subheadline)

            Spacer()

            Text(value)
                .foregroundColor(.appTextPrimary)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WildfireMapPreview()
}

private struct WildfireMapPreview: View {
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.25, longitude: -120.0),
            span: MKCoordinateSpan(latitudeDelta: 6.0, longitudeDelta: 6.0)
        )
    )

    private let sample: [CALFireIncident] = [
        CALFireIncident(
            name: "Dangerous Fire",
            acresBurned: 15000,
            percentContained: 25,
            isActive: true,
            startedDate: "2025-08-01",
            county: "Mariposa",
            location: "Near Something Rd",
            latitude: 37.7749,
            longitude: -122.4194,
            url: "https://example.com"
        ),
        CALFireIncident(
            name: "Medium Fire",
            acresBurned: 3000,
            percentContained: 50,
            isActive: true,
            startedDate: "2025-08-02",
            county: "Los Angeles",
            location: "Near Sample Town",
            latitude: 34.0522,
            longitude: -118.2437,
            url: "https://example.com"
        ),
        CALFireIncident(
            name: "Small Fire",
            acresBurned: 500,
            percentContained: 80,
            isActive: true,
            startedDate: "2025-08-03",
            county: "Fresno",
            location: "Near Sample Village",
            latitude: 36.7783,
            longitude: -119.4179,
            url: "https://example.com"
        ),
        CALFireIncident(
            name: "Contained Fire",
            acresBurned: 80,
            percentContained: 100,
            isActive: false,
            startedDate: "2025-08-02",
            county: "Sacramento",
            location: "Near Sample Creek",
            latitude: 38.5816,
            longitude: -121.4944,
            url: "https://example.com"
        )
    ]

    private func flameColorForPreview(for incident: CALFireIncident) -> Color {

        if !incident.isActive {
            return .gray
        }

        let acres = incident.acresBurned

        if acres > 10000 {
            return .red
        } else {
            return .orange
        }
    }

    var body: some View {
        Map(position: $cameraPosition, interactionModes: [.pan]) {
            ForEach(sample) { i in
                let coord = CLLocationCoordinate2D(latitude: i.latitude, longitude: i.longitude)
                Annotation(i.name, coordinate: coord) {
                    Button(action: {

                    }) {
                        ZStack {

                            Circle()
                                .fill(Color.appSurface)
                                .frame(width: 36, height: 36)

                            Circle()
                                .fill(Color.appCard)
                                .frame(width: 32, height: 32)

                            Image(systemName: "flame.fill")
                                .foregroundColor(flameColorForPreview(for: i))
                                .font(.title2)
                                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .ignoresSafeArea()
    }
}
