import Foundation
import UserNotifications
import SwiftUI

class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound, .criticalAlert]
            )

            DispatchQueue.main.async {
                self.isAuthorized = granted
                self.checkAuthorizationStatus()
            }

            if granted {
                await registerForRemoteNotifications()
            }
        } catch {
            print("Error requesting notification authorization: \(error)")
        }
    }

    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func scheduleEmergencyAlert(title: String, body: String, fireLocation: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .defaultCritical
        content.categoryIdentifier = "EMERGENCY_ALERT"
        content.userInfo = ["fireLocation": fireLocation]

        content.interruptionLevel = .critical

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "emergency_alert_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling emergency notification: \(error)")
            }
        }
    }

    func scheduleEvacuationAlert(zone: String, urgency: String) {
        let content = UNMutableNotificationContent()
        content.title = "🚨 EVACUATION ALERT"
        content.body = "Mandatory evacuation for \(zone). \(urgency) - Leave immediately!"
        content.sound = .defaultCritical
        content.categoryIdentifier = "EVACUATION_ALERT"
        content.userInfo = ["zone": zone, "urgency": urgency]
        content.interruptionLevel = .critical

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "evacuation_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleFireUpdate(containment: Int, location: String) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Fire Update"
        content.body = "Containment at \(containment)% in \(location). Stay alert!"
        content.sound = .default
        content.categoryIdentifier = "FIRE_UPDATE"
        content.userInfo = ["containment": containment, "location": location]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "fire_update_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleCommunityPost(postType: String, author: String, content: String) {
        let content = UNMutableNotificationContent()
        content.title = "📢 Community Update"
        content.body = "\(author): \(content)"
        content.sound = .default
        content.categoryIdentifier = "COMMUNITY_POST"
        content.userInfo = ["postType": postType, "author": author]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "community_post_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleWeatherAlert(alertType: String, description: String) {
        let content = UNMutableNotificationContent()
        content.title = "🌤️ Weather Alert"
        content.body = "\(alertType): \(description)"
        content.sound = .default
        content.categoryIdentifier = "WEATHER_ALERT"
        content.userInfo = ["alertType": alertType, "description": description]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "weather_alert_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func schedulePeriodicFireCheck() {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Fire Status Check"
        content.body = "Tap to check current fire conditions in your area"
        content.sound = .default
        content.categoryIdentifier = "PERIODIC_CHECK"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4 * 60 * 60, repeats: true)
        let request = UNNotificationRequest(identifier: "periodic_fire_check", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleAirQualityAlert(aqi: Int) {
        let content = UNMutableNotificationContent()
        content.title = "😷 Air Quality Alert"
        content.body = "Air Quality Index: \(aqi). Consider wearing a mask outdoors."
        content.sound = .default
        content.categoryIdentifier = "AIR_QUALITY"
        content.userInfo = ["aqi": aqi]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "air_quality_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func setupNotificationCategories() {
        let emergencyCategory = UNNotificationCategory(
            identifier: "EMERGENCY_ALERT",
            actions: [
                UNNotificationAction(identifier: "VIEW_MAP", title: "View Map", options: .foreground),
                UNNotificationAction(identifier: "CALL_911", title: "Call 911", options: .foreground)
            ],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let evacuationCategory = UNNotificationCategory(
            identifier: "EVACUATION_ALERT",
            actions: [
                UNNotificationAction(identifier: "VIEW_ROUTES", title: "Evacuation Routes", options: .foreground),
                UNNotificationAction(identifier: "SHELTER_INFO", title: "Shelter Info", options: .foreground)
            ],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let communityCategory = UNNotificationCategory(
            identifier: "COMMUNITY_POST",
            actions: [
                UNNotificationAction(identifier: "VIEW_POST", title: "View Post", options: .foreground),
                UNNotificationAction(identifier: "REPLY", title: "Reply", options: .foreground)
            ],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            emergencyCategory,
            evacuationCategory,
            communityCategory
        ])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "VIEW_MAP":

            NotificationCenter.default.post(name: .navigateToMap, object: nil)
        case "CALL_911":

            if let url = URL(string: "tel:911") {
                UIApplication.shared.open(url)
            }
        case "VIEW_ROUTES":

            NotificationCenter.default.post(name: .navigateToEvacuation, object: nil)
        case "SHELTER_INFO":

            NotificationCenter.default.post(name: .navigateToShelters, object: nil)
        case "VIEW_POST":

            NotificationCenter.default.post(name: .navigateToCommunity, object: nil)
        case "REPLY":

            NotificationCenter.default.post(name: .navigateToCommunity, object: userInfo)
        default:
            break
        }

        completionHandler()
    }
}

extension Notification.Name {
    static let navigateToMap = Notification.Name("navigateToMap")
    static let navigateToEvacuation = Notification.Name("navigateToEvacuation")
    static let navigateToShelters = Notification.Name("navigateToShelters")
    static let navigateToCommunity = Notification.Name("navigateToCommunity")
}
