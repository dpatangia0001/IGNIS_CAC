import SwiftUI
import SwiftData
import UserNotifications

struct MainNavigationView: View {
    @State private var selectedTab = 2
    @State private var showLandingPage = true
    @State private var showSideMenu = false
    @State private var showBottomNavBar = true

    var body: some View {
        if showLandingPage {

                LandingPageView(onStartNow: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showLandingPage = false
                    }
                })
            } else {

                ZStack {

                    Color.black
                        .ignoresSafeArea(.all)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Group {
                        switch selectedTab {
                        case 0:
                            WildfireChatbotView()
                        case 1:
                            MentalHelpView()
                        case 2:
                            HomePageView()
                        case 3:
                            EducationView()
                        case 4:
                            WildfireMap()
                        case 5:
                            CommunityThreadsView()
                        case 6:
                            ResourcesView()
                        case 7:
                            LegislativeView()
                        case 8:
                            FireRiskView()
                        default:
                            HomePageView()
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)

                    if showBottomNavBar {
                        VStack {
                            Spacer()
                            CustomFloatingNavBar(selectedTab: $selectedTab)
                        }
                    }

                    if showSideMenu {
                        SideMenuView(
                            showSideMenu: $showSideMenu,
                            selectedTab: $selectedTab
                        )
                        .transition(.move(edge: .leading))
                        .zIndex(1)
                    }
                }
                .navigationBarHidden(true)
                .navigationViewStyle(StackNavigationViewStyle())
                .onAppear {

                    hideSystemTabBar()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTab"))) { notification in
                    if let tabIndex = notification.userInfo?["tabIndex"] as? Int {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tabIndex
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HideBottomNavBar"))) { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showBottomNavBar = false
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowBottomNavBar"))) { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showBottomNavBar = true
                    }
                }
            }
    }

    private func hideSystemTabBar() {
        DispatchQueue.main.async {

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let tabBarController = window.rootViewController as? UITabBarController {
                tabBarController.tabBar.isHidden = true
                tabBarController.tabBar.alpha = 0
            }

            UITabBar.appearance().isHidden = true
            UITabBar.appearance().alpha = 0
        }
    }

    private func configureStatusBarAppearance() {
        DispatchQueue.main.async {

        }
    }
}

struct SideMenuView: View {
    @Binding var showSideMenu: Bool
    @Binding var selectedTab: Int

    let menuItems = [
        ("Home", "house.fill", 2),
        ("Chatbot", "message.fill", 0),
        ("Mental Health", "heart.fill", 1),
        ("Wildfire Map", "map.fill", 4),
        ("Community", "person.3.fill", 5),
        ("Resources", "gift.fill", 6),
        ("Legislative", "building.columns.fill", 7),
        ("Fire Risk", "flame.fill", 8)
    ]

    var body: some View {
        ZStack {

            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSideMenu = false
                    }
                }

            HStack {
                VStack(alignment: .leading, spacing: 0) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ignis")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.wsOrange)

                        Text("Wildfire Safety")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 30)

                    VStack(spacing: 0) {
                        ForEach(menuItems, id: \.0) { item in
                            MenuItemView(
                                title: item.0,
                                icon: item.1,
                                isSelected: selectedTab == item.2,
                                action: {
                                    if item.2 >= 0 {
                                        selectedTab = item.2
                                    }
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showSideMenu = false
                                    }
                                }
                            )
                        }
                    }

                    Spacer()
                }
                .frame(width: 280)
                .background(
                    Color(red: 0.05, green: 0.05, blue: 0.05)
                )
                .overlay(
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(.wsOrange.opacity(0.3)),
                    alignment: .trailing
                )

                Spacer()
            }
        }
    }
}

struct MenuItemView: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .wsOrange : .gray)
                    .frame(width: 24)

                Text(title)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .wsOrange : .white)

                Spacer()

                if isSelected {
                    Circle()
                        .fill(Color.wsOrange)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .wsOrange.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LazyView<Content: View>: View {
    let build: () -> Content

    init(_ build: @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

struct CustomFloatingNavBar: View {
    @Binding var selectedTab: Int
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 0) {

            NavBarButton(
                icon: "message.fill",
                title: "Chatbot",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )

            Spacer()

            NavBarButton(
                icon: "map.fill",
                title: "Map",
                isSelected: selectedTab == 4,
                action: { selectedTab = 4 }
            )

            Spacer()

            Button {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    selectedTab = 2
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isPressed = false
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.wsOrange, .wsRed]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                        .shadow(color: .wsOrange.opacity(0.4), radius: 6, x: 0, y: 3)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)

                    Image(systemName: "house.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Home")

            Spacer()

            NavBarButton(
                icon: "heart.fill",
                title: "Support",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )

            Spacer()

            NavBarButton(
                icon: "flame.fill",
                title: "Risk",
                isSelected: selectedTab == 8,
                action: { selectedTab = 8 }
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.wsOrange.opacity(0.3), .wsRed.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.8), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 15)
    }
}

struct NavBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                action()
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isPressed = false
            }
        }) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .wsOrange : .white.opacity(0.8))
                    .scaleEffect(isPressed ? 0.8 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)

                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .wsOrange : .white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(title)
        .accessibilityHint(isSelected ? "Selected" : "Not selected")
    }
}

@main
struct IgnisApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {

        NotificationService.shared.setupNotificationCategories()
    }

    var body: some Scene {
        WindowGroup {
            MainNavigationView()
                .preferredColorScheme(.dark)
                .onAppear {

                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        configureSystemAppearance()

        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")

    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        if let aps = userInfo["aps"] as? [String: Any] {
            if let alert = aps["alert"] as? [String: Any] {
                let title = alert["title"] as? String ?? "Wildfire Alert"
                let body = alert["body"] as? String ?? "Emergency notification"

                NotificationService.shared.scheduleEmergencyAlert(
                    title: title,
                    body: body,
                    fireLocation: userInfo["fireLocation"] as? String ?? "Unknown Location"
                )
            }
        }

        completionHandler(.newData)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        _ = response.notification.request.content.userInfo

        switch response.notification.request.content.categoryIdentifier {
        case "EMERGENCY_ALERT":
            NotificationCenter.default.post(name: .navigateToMap, object: nil)
        case "EVACUATION_ALERT":
            NotificationCenter.default.post(name: .navigateToEvacuation, object: nil)
        case "COMMUNITY_POST":
            NotificationCenter.default.post(name: .navigateToCommunity, object: nil)
        default:
            break
        }

        completionHandler()
    }

    private func configureSystemAppearance() {

        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBarAppearance.backgroundColor = .clear
        navigationBarAppearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = .clear
        tabBarAppearance.shadowColor = .clear

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        UITabBar.appearance().isHidden = true
        UITabBar.appearance().alpha = 0.0
        UITabBar.appearance().frame = CGRect.zero

    }
}
