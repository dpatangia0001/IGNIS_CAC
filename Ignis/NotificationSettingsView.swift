import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @State private var emergencyAlerts = true
    @State private var evacuationAlerts = true
    @State private var fireUpdates = true
    @State private var communityPosts = false
    @State private var weatherAlerts = true
    @State private var airQualityAlerts = true
    @State private var periodicChecks = false
    @Environment(\.dismiss) private var dismiss

    let darkOrange = Color(red: 0.85, green: 0.33, blue: 0.0)
    let darkRed = Color(red: 0.7, green: 0.13, blue: 0.13)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        authorizationSection

                        notificationSection(
                            title: "🚨 Emergency Alerts",
                            description: "Critical alerts for immediate danger",
                            isEnabled: $emergencyAlerts,
                            icon: "exclamationmark.triangle.fill",
                            color: .red
                        )

                        notificationSection(
                            title: "🏃 Evacuation Alerts",
                            description: "Mandatory evacuation orders",
                            isEnabled: $evacuationAlerts,
                            icon: "person.2.fill",
                            color: .orange
                        )

                        notificationSection(
                            title: "🔥 Fire Updates",
                            description: "Containment and fire status updates",
                            isEnabled: $fireUpdates,
                            icon: "flame.fill",
                            color: .orange
                        )

                        notificationSection(
                            title: "🌤️ Weather Alerts",
                            description: "Wind, humidity, and weather conditions",
                            isEnabled: $weatherAlerts,
                            icon: "cloud.sun.fill",
                            color: .blue
                        )

                        notificationSection(
                            title: "😷 Air Quality Alerts",
                            description: "Air quality index and health warnings",
                            isEnabled: $airQualityAlerts,
                            icon: "lungs.fill",
                            color: .purple
                        )

                        notificationSection(
                            title: "📢 Community Posts",
                            description: "Updates from community members",
                            isEnabled: $communityPosts,
                            icon: "person.3.fill",
                            color: .green
                        )

                        notificationSection(
                            title: "⏰ Periodic Checks",
                            description: "Regular fire status reminders",
                            isEnabled: $periodicChecks,
                            icon: "clock.fill",
                            color: .gray
                        )

                        testNotificationsButton

                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(darkOrange)
                }
            }
        }
        .onAppear {
            setupNotificationCategories()
        }
    }

    private var authorizationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: notificationService.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(notificationService.isAuthorized ? .green : .red)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(notificationService.isAuthorized ? "Notifications Enabled" : "Notifications Disabled")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(notificationService.isAuthorized ? "You'll receive important alerts" : "Enable notifications for emergency alerts")
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
                .background(darkOrange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func notificationSection(
        title: String,
        description: String,
        isEnabled: Binding<Bool>,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Toggle("", isOn: isEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: darkOrange))
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var testNotificationsButton: some View {
        VStack(spacing: 16) {
            Text("Test Notifications")
                .font(.headline)
                .foregroundColor(.white)

            Text("Send a test notification to verify your settings")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button("Send Test Alert") {
                sendTestNotification()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(darkOrange)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func setupNotificationCategories() {
        notificationService.setupNotificationCategories()
    }

    private func sendTestNotification() {
        notificationService.scheduleEmergencyAlert(
            title: "🧪 Test Alert",
            body: "This is a test notification to verify your settings are working correctly.",
            fireLocation: "Test Location"
        )
    }
}

#Preview {
    NotificationSettingsView()
}
