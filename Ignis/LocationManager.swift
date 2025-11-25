import Foundation
import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let locationManager = CLLocationManager()
    private var lastLocationUpdate: Date = Date.distantPast
    private let minimumUpdateInterval: TimeInterval = 30.0

    private override init() {
        super.init()
        setupLocationManager()
    }

    deinit {
        stopLocationUpdates()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 500
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.activityType = .other
        authorizationStatus = locationManager.authorizationStatus

        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startLocationUpdates()
        }
    }

    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access is required to show nearby fires. Please enable in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }

    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }

        let timeSinceLastUpdate = Date().timeIntervalSince(lastLocationUpdate)
        guard timeSinceLastUpdate >= minimumUpdateInterval else {
            return
        }

        isLoading = true
        locationManager.startUpdatingLocation()
    }

    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLoading = false
    }

    func distanceToIncident(lat: Double, lon: Double) -> CLLocationDistance? {
        guard let userLocation = location else { return nil }
        let fireCLLocation = CLLocation(latitude: lat, longitude: lon)
        return userLocation.distance(from: fireCLLocation)
    }

    func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            let kilometers = distance / 1000
            return String(format: "%.1fkm", kilometers)
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let timeSinceLastUpdate = Date().timeIntervalSince(lastLocationUpdate)
        guard timeSinceLastUpdate >= minimumUpdateInterval else {
            return
        }

        guard location.horizontalAccuracy <= 1000 else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.location = location
            self.lastLocationUpdate = Date()
            self.isLoading = false
            self.errorMessage = nil

            if location.horizontalAccuracy <= 100 {
                self.stopLocationUpdates()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isLoading = false

            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.errorMessage = "Location access denied. Please enable in Settings."
                case .locationUnknown:
                    self.errorMessage = "Unable to determine location. Please try again."
                case .network:
                    self.errorMessage = "Network error. Please check your connection."
                default:
                    self.errorMessage = "Location error: \(error.localizedDescription)"
                }
            } else {
                self.errorMessage = "Location error: \(error.localizedDescription)"
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.authorizationStatus = status

            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startLocationUpdates()
            case .denied, .restricted:
                self.errorMessage = "Location access denied. Please enable in Settings to see nearby fires."
                self.stopLocationUpdates()
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }

    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
        }
    }

    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
        }
    }
}

struct LocationPermissionView: View {
    @ObservedObject var locationManager: LocationManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Location Access Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("To show you nearby wildfires and provide accurate alerts, we need access to your location.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Enable Location Access") {
                locationManager.requestLocationPermission()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color(red: 0.9, green: 0.3, blue: 0.1), Color(red: 0.7, green: 0.1, blue: 0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let errorMessage = locationManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.02, blue: 0.01),
                    Color(red: 0.1, green: 0.05, blue: 0.02)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    LocationPermissionView(locationManager: LocationManager.shared)
}
