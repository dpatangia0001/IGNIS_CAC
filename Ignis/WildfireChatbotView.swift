import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

struct WildfireChatbotView: View {
    @StateObject private var deepSeekService = DeepSeekService()
    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    @State private var isTyping = false
    @State private var scrollToBottom = false
    @State private var navigateToHome = false
    @State private var titleGlow = false

    private var backgroundView: some View {
        ZStack {

            Color.appGradientBackground
                .ignoresSafeArea()

            GeometryReader { geometry in
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(
                            Color.appPrimary.opacity(0.05)
                        )
                        .frame(
                            width: CGFloat.random(in: 20...40),
                            height: CGFloat.random(in: 20...40)
                        )
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 3...6))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                            value: titleGlow
                        )
                }
            }
            .opacity(0.6)
        }
    }

    var body: some View {
        ZStack {

            backgroundView

            VStack(spacing: 0) {

                headerView

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {

                            if messages.isEmpty {
                                welcomeMessage
                            }

                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if isTyping {
                                TypingIndicator()
                                    .id("typing")
                            }

                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    .onChange(of: isTyping) { _, _ in
                        if isTyping {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }

                Spacer()

                inputArea
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {

            NotificationCenter.default.post(name: NSNotification.Name("HideBottomNavBar"), object: nil)

            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                titleGlow = true
            }
        }
        .onDisappear {

            NotificationCenter.default.post(name: NSNotification.Name("ShowBottomNavBar"), object: nil)
        }
        .alert("API Error", isPresented: .constant(deepSeekService.errorMessage != nil)) {
            Button("OK") {
                deepSeekService.errorMessage = nil
            }
        } message: {
            Text(deepSeekService.errorMessage ?? "")
        }
        .onChange(of: navigateToHome) { _, newValue in
            if newValue {

                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToTab"),
                    object: nil,
                    userInfo: ["tabIndex": 2]
                )
                navigateToHome = false
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 0) {

            HStack {
                Button(action: {
                    navigateToHome = true
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.appTextPrimary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.appSurface)
                        )
                }

                Spacer()

                Text("Fire Expert")
                    .font(.appTitle)
                    .foregroundColor(.appTextPrimary)
                    .shadow(color: Color.appPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
                    .scaleEffect(titleGlow ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: titleGlow)

                Spacer()

                Button(action: {
                    clearChat()
                }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundColor(.appError)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.appSurface)
                        )
                }
                .disabled(messages.isEmpty)
                .opacity(messages.isEmpty ? 0.5 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .background(Color.appSurface)

            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.appBorder.opacity(0.3),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 4)
        }
    }

    private var welcomeMessage: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.appPrimary.opacity(0.3),
                                    Color.appSecondary.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(titleGlow ? 1.1 : 1.0)
                        .opacity(titleGlow ? 0.8 : 0.6)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.appPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
                }

                VStack(spacing: 8) {
                    Text("Ask me anything about")
                        .font(.appSubheadline)
                        .foregroundColor(.appTextSecondary)

                    Text("Wildfire Safety")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.appTextPrimary)
                        .shadow(color: Color.appPrimary.opacity(0.2), radius: 4, x: 0, y: 2)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                EnhancedQuickActionButton(title: "Evacuation", icon: "exclamationmark.triangle.fill", color: .appError) {
                    sendMessage("What should I do during evacuation?")
                }

                EnhancedQuickActionButton(title: "Air Quality", icon: "lungs.fill", color: .appInfo) {
                    sendMessage("How does wildfire smoke affect air quality?")
                }

                EnhancedQuickActionButton(title: "Emergency Kit", icon: "cross.case.fill", color: .appWarning) {
                    sendMessage("What should I pack in my emergency kit?")
                }

                EnhancedQuickActionButton(title: "Fire Safety", icon: "shield.fill", color: .appSuccess) {
                    sendMessage("How can I protect my home from wildfires?")
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }

    private var inputArea: some View {
        VStack(spacing: 0) {

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appPrimary.opacity(0.3),
                            Color.appSecondary.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)

            HStack(spacing: 12) {

                HStack(spacing: 12) {

                    TextField("Ask about fire safety...", text: $newMessage)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 29)
                                .fill(Color.appCard)
                                .shadow(
                                    color: newMessage.isEmpty ? Color.appBorder.opacity(0.3) : Color.appPrimary.opacity(0.2),
                                    radius: newMessage.isEmpty ? 2 : 8,
                                    x: 0,
                                    y: 2
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 29)
                                        .stroke(
                                            newMessage.isEmpty ? Color.appBorder.opacity(0.5) : Color.appPrimary.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .foregroundColor(.appTextPrimary)
                        .animation(.easeInOut(duration: 0.2), value: newMessage.isEmpty)

                    Button(action: {
                        sendMessage(newMessage)
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? AnyShapeStyle(Color.appButtonSecondary)
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [Color.appPrimary, Color.appSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                )
                                .frame(width: 48, height: 48)
                                .shadow(
                                    color: newMessage.isEmpty ? Color.clear : Color.appPrimary.opacity(0.4),
                                    radius: newMessage.isEmpty ? 0 : 6,
                                    x: 0,
                                    y: 2
                                )

                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .scaleEffect(newMessage.isEmpty ? 0.8 : 1.0)
                        }
                        .scaleEffect(newMessage.isEmpty ? 0.9 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: newMessage.isEmpty)
                    }
                    .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .padding(.bottom, 22)
            .background(

                LinearGradient(
                    colors: [
                        Color.appSurface,
                        Color.appBackground.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .shadow(color: Color.appPrimary.opacity(0.1), radius: 12, x: 0, y: -4)
            )
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    private func sendMessage(_ customMessage: String? = nil) {
        let messageText = customMessage ?? newMessage.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !messageText.isEmpty else { return }

        let userMessage = ChatMessage(content: messageText, isUser: true, timestamp: Date())
        withAnimation(.easeInOut(duration: 0.3)) {
            messages.append(userMessage)
        }

        newMessage = ""

        isTyping = true
        Task {
            let botResponse = await deepSeekService.generateFireExpertResponse(for: messageText)
            await MainActor.run {
                isTyping = false
                let botMessage = ChatMessage(content: botResponse, isUser: false, timestamp: Date())
                withAnimation(.easeInOut(duration: 0.3)) {
                    messages.append(botMessage)
                }
            }
        }
    }

    private func clearChat() {
        withAnimation(.easeInOut(duration: 0.3)) {
            messages.removeAll()
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(messages.last?.id, anchor: .bottom)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.appBody)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.appPrimary)
                        .cornerRadius(18)

                    Text(timeString(from: message.timestamp))
                        .font(.appSmall)
                        .foregroundColor(.appTextTertiary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {

                        Image(systemName: "flame.circle.fill")
                            .font(.title3)
                            .foregroundColor(.appSecondary)

                        Text(message.content)
                            .font(.appBody)
                            .foregroundColor(.appTextPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.appCard)
                            .cornerRadius(18)
                    }

                    Text(timeString(from: message.timestamp))
                        .font(.appSmall)
                        .foregroundColor(.appTextTertiary)
                        .padding(.leading, 32)
                }

                Spacer()
            }
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "flame.circle.fill")
                        .font(.title3)
                        .foregroundColor(.appSecondary)

                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.appTextSecondary)
                                .frame(width: 8, height: 8)
                                .scaleEffect(animationOffset == CGFloat(index) ? 1.2 : 0.8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appCard)
                    .cornerRadius(18)
                }
            }

            Spacer()
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever()) {
                animationOffset = 1
            }
        }
    }
}

struct EnhancedQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
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
                action()
            }
        }) {
            VStack(spacing: 12) {

                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                        .shadow(color: color.opacity(0.3), radius: isPressed ? 2 : 8, x: 0, y: isPressed ? 1 : 4)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCard)
                    .shadow(
                        color: Color.appPrimary.opacity(0.1),
                        radius: isPressed ? 2 : 6,
                        x: 0,
                        y: isPressed ? 1 : 3
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.appPrimary)

                Text(title)
                    .font(.appCaption)
                    .foregroundColor(.appTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .appCardStyle()
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    WildfireChatbotView()
}
