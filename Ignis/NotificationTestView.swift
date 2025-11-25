import SwiftUI

struct NotificationTestView: View {
    @StateObject private var notificationService = NotificationService.shared
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        statusSection

                        testEmergencySection

                        testEvacuationSection

                        testWeatherSection

                        testCommunitySection

                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Notification Test")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Test Result", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var statusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: notificationService.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(notificationService.isAuthorized ? .green : .red)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(notificationService.isAuthorized ? "Notifications Enabled" : "Notifications Disabled")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(notificationService.isAuthorized ? "You'll receive test alerts" : "Enable notifications to test")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            if !notificationService.isAuthorized {
                Button("Enable Notifications") {
                    Task {
                        await notificationService.requestAuthorization()
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var testEmergencySection: some View {
        VStack(spacing: 12) {
            Text("🚨 Test Emergency Alerts")
                .font(.headline)
                .foregroundColor(.white)

            Button("Send Critical Alert") {
                notificationService.scheduleEmergencyAlert(
                    title: "🚨 CRITICAL FIRE ALERT",
                    body: "Fast-moving wildfire approaching residential areas. Immediate evacuation required.",
                    fireLocation: "North County, CA"
                )
                alertMessage = "Critical emergency alert sent!"
                showAlert = true
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)

            Button("Send Moderate Alert") {
                notificationService.scheduleEmergencyAlert(
                    title: "🔥 Fire Update",
                    body: "Fire containment at 45%. Conditions improving but stay alert.",
                    fireLocation: "South County, CA"
                )
                alertMessage = "Moderate fire alert sent!"
                showAlert = true
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var testEvacuationSection: some View {
        VStack(spacing: 12) {
            Text("🏃 Test Evacuation Alerts")
                .font(.headline)
                .foregroundColor(.white)

            Button("Send Mandatory Evacuation") {
                notificationService.scheduleEvacuationAlert(
                    zone: "North County Zone A",
                    urgency: "mandatory"
                )
                alertMessage = "Mandatory evacuation alert sent!"
                showAlert = true
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)

            Button("Send Voluntary Evacuation") {
                notificationService.scheduleEvacuationAlert(
                    zone: "South County Zone B",
                    urgency: "voluntary"
                )
                alertMessage = "Voluntary evacuation alert sent!"
                showAlert = true
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var testWeatherSection: some View {
        VStack(spacing: 12) {
            Text("🌤️ Test Weather Alerts")
                .font(.headline)
                .foregroundColor(.white)

            Button("Send Wind Alert") {
                notificationService.scheduleWeatherAlert(
                    alertType: "wind",
                    description: "High winds detected: 25-35 mph gusts. Fire danger elevated."
                )
                alertMessage = "Wind alert sent!"
                showAlert = true
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            Button("Send Air Quality Alert") {
                notificationService.scheduleAirQualityAlert(aqi: 150)
                alertMessage = "Air quality alert sent!"
                showAlert = true
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var testCommunitySection: some View {
        VStack(spacing: 12) {
            Text("📢 Test Community Posts")
                .font(.headline)
                .foregroundColor(.white)

            Button("Send Emergency Post") {
                notificationService.scheduleCommunityPost(
                    postType: "Help Needed",
                    author: "Emergency Coordinator",
                    content: "🚨 EMERGENCY: Need immediate assistance with evacuation coordination."
                )
                alertMessage = "Emergency community post notification sent!"
                showAlert = true
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)

            Button("Send Help Offer") {
                notificationService.scheduleCommunityPost(
                    postType: "Offering Help",
                    author: "Local Volunteer",
                    content: "💚 OFFERING HELP: I have a van and can help transport people and pets."
                )
                alertMessage = "Help offer notification sent!"
                showAlert = true
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    NotificationTestView()
}
