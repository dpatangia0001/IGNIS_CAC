import SwiftUI
import UIKit
import AVFoundation

struct MentalHelpView: View {
    @State private var showCopingModal = false
    @State private var selectedQuickHelp: QuickHelpType? = nil
    @State private var showingResourceDetail = false
    @State private var selectedResource: MentalHealthResource? = nil

    var body: some View {
        NavigationView {
            ZStack {

                Color.appGradientBackground
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 24) {

                        headerSection

                        emergencySection

                        quickHelpSection

                        selfCareSection

                        professionalResourcesSection

                        encouragementSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedQuickHelp) { helpType in
            QuickHelpDetailView(helpType: helpType)
        }
        .sheet(isPresented: $showCopingModal) {
            GuidedBreathingView()
        }
        .sheet(item: $selectedResource) { resource in
            ResourceDetailView(resource: resource)
        }
    }

    private var headerSection: some View {
        HStack(spacing: 16) {

            ZStack {
                Circle()
                    .fill(Color.appGradientPrimary)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.appPrimary.opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Mental Health")
                    .font(.appTitle)
                    .foregroundColor(.appTextPrimary)

                Text("Support when you need it most")
                    .font(.appSubheadline)
                    .foregroundColor(.appTextSecondary)
            }

            Spacer()
        }
        .padding(.top, 20)
    }

    private var emergencySection: some View {
        VStack(spacing: 16) {

            CrisisHotlineCard()

            TextCrisisCard()
        }
    }

    private var quickHelpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Quick Help", icon: "sparkles")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(QuickHelpType.allCases, id: \.self) { helpType in
                    QuickHelpCard(helpType: helpType) {
                        selectedQuickHelp = helpType
                    }
                }
            }
        }
    }

    private var selfCareSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Self-Care Tools", icon: "hands.sparkles")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                SelfCareCard(
                    title: "Guided Breathing",
                    icon: "wind",
                    color: .appInfo,
                    action: { showCopingModal = true }
                )

                SelfCareCard(
                    title: "Mindfulness",
                    icon: "brain.head.profile",
                    color: .appSuccess,
                    action: { selectedQuickHelp = .anxiety }
                )

                SelfCareCard(
                    title: "Grounding",
                    icon: "tree.fill",
                    color: .appWarning,
                    action: { selectedQuickHelp = .shock }
                )

                SelfCareCard(
                    title: "Sleep Tips",
                    icon: "bed.double.fill",
                    color: .appSecondary,
                    action: { selectedQuickHelp = .sleep }
                )
            }
        }
    }

    private var professionalResourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Professional Resources", icon: "stethoscope")

            VStack(spacing: 12) {
                ForEach(MentalHealthResource.sampleResources) { resource in
                    ProfessionalResourceCard(resource: resource) {
                        selectedResource = resource
                    }
                }
            }
        }
    }

    private var encouragementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "You're Not Alone", icon: "heart.fill")

            EncouragementCard()
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appPrimary)

            Text(title)
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)

            Spacer()
        }
    }
}

struct CrisisHotlineCard: View {
    var body: some View {
        Button(action: {
            if let url = URL(string: "tel://988") {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 16) {

                ZStack {
                    Circle()
                        .fill(Color.appError)
                        .frame(width: 48, height: 48)

                    Image(systemName: "phone.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Crisis? Call 988")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.appTextPrimary)

                    Text("24/7 Suicide & Crisis Lifeline")
                        .font(.appBody)
                        .foregroundColor(.appTextSecondary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.appError)
            }
            .padding(20)
            .appCardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appError.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TextCrisisCard: View {
    var body: some View {
        Button(action: {
            if let url = URL(string: "sms:741741&body=HOME") {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 16) {

                ZStack {
                    Circle()
                        .fill(Color.appWarning)
                        .frame(width: 48, height: 48)

                    Image(systemName: "message.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Text HOME to 741741")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.appTextPrimary)

                    Text("Crisis Text Line - Free 24/7")
                        .font(.appBody)
                        .foregroundColor(.appTextSecondary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.appWarning)
            }
            .padding(20)
            .appCardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appWarning.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum QuickHelpType: String, CaseIterable, Identifiable {
    case shock = "Shock"
    case anxiety = "Anxiety"
    case grief = "Grief"
    case sleep = "Sleep"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .shock: return "exclamationmark.triangle.fill"
        case .anxiety: return "waveform.path.ecg"
        case .grief: return "heart.fill"
        case .sleep: return "bed.double.fill"
        }
    }

    var color: Color {
        switch self {
        case .shock: return .appWarning
        case .anxiety: return .appInfo
        case .grief: return .appPrimary
        case .sleep: return .appSecondary
        }
    }

    var description: String {
        switch self {
        case .shock: return "Dealing with sudden trauma or shock"
        case .anxiety: return "Managing anxiety and stress"
        case .grief: return "Coping with loss and grief"
        case .sleep: return "Improving sleep and rest"
        }
    }
}

struct QuickHelpCard: View {
    let helpType: QuickHelpType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {

                ZStack {
                    Circle()
                        .fill(helpType.color.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: helpType.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(helpType.color)
                }

                Text(helpType.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appTextPrimary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .appCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SelfCareCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {

                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .appCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MentalHealthResource: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: ResourceType
    let contactInfo: String
    let isAvailable24_7: Bool

    enum ResourceType {
        case therapy, support, crisis, medical

        var icon: String {
            switch self {
            case .therapy: return "person.2.fill"
            case .support: return "hands.and.sparkles.fill"
            case .crisis: return "cross.case.fill"
            case .medical: return "stethoscope"
            }
        }

        var color: Color {
            switch self {
            case .therapy: return .appInfo
            case .support: return .appSuccess
            case .crisis: return .appError
            case .medical: return .appPrimary
            }
        }
    }

    static let sampleResources = [
        MentalHealthResource(
            title: "SAMHSA Helpline",
            description: "Substance abuse and mental health services",
            type: .crisis,
            contactInfo: "1-800-662-4357",
            isAvailable24_7: true
        ),
        MentalHealthResource(
            title: "Local Therapy Services",
            description: "Find qualified therapists in your area",
            type: .therapy,
            contactInfo: "Search nearby",
            isAvailable24_7: false
        ),
        MentalHealthResource(
            title: "Support Groups",
            description: "Connect with others who understand",
            type: .support,
            contactInfo: "Find groups",
            isAvailable24_7: false
        )
    ]
}

struct ProfessionalResourceCard: View {
    let resource: MentalHealthResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {

                ZStack {
                    Circle()
                        .fill(resource.type.color.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: resource.type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(resource.type.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(resource.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.appTextPrimary)

                        if resource.isAvailable24_7 {
                            Text("24/7")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.appSuccess)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.appSuccess.opacity(0.2))
                                )
                        }

                        Spacer()
                    }

                    Text(resource.description)
                        .font(.appBody)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)

                    Text(resource.contactInfo)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(resource.type.color)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appTextTertiary)
            }
            .padding(16)
            .appCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EncouragementCard: View {
    @State private var showShareSheet = false

    private let encouragementText = "You are stronger than you know. Reaching out for help is a sign of courage, not weakness. Every step you take toward healing matters, no matter how small it may seem."

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text(encouragementText)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.appTextPrimary)
                .lineSpacing(4)

            Button(action: { showShareSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))

                    Text("Share Encouragement")
                        .font(.system(size: 14, weight: .semibold))

                    Spacer()
                }
                .foregroundColor(.appPrimary)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appPrimary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .appCardStyle()
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [encouragementText])
        }
    }
}

struct QuickHelpDetailView: View {
    let helpType: QuickHelpType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(helpType.color.opacity(0.2))
                                    .frame(width: 64, height: 64)

                                Image(systemName: helpType.icon)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(helpType.color)
                            }

                            Spacer()

                            Button("Done") {
                                dismiss()
                            }
                            .foregroundColor(.appPrimary)
                        }

                        Text(helpType.rawValue)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.appTextPrimary)

                        Text(helpType.description)
                            .font(.appSubheadline)
                            .foregroundColor(.appTextSecondary)
                    }

                    helpContent
                }
                .padding(20)
            }
            .background(Color.appGradientBackground.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private var helpContent: some View {
        switch helpType {
        case .shock:
            shockContent
        case .anxiety:
            anxietyContent
        case .grief:
            griefContent
        case .sleep:
            sleepContent
        }
    }

    private var shockContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            GuideSection(title: "Immediate Steps", icon: "1.circle.fill") {
                GuideItem(text: "Find a safe, quiet place")
                GuideItem(text: "Focus on slow, deep breathing")
                GuideItem(text: "Ground yourself - notice 5 things you can see")
                GuideItem(text: "Reach out to someone you trust")
            }

            GuideSection(title: "Grounding Techniques", icon: "2.circle.fill") {
                GuideItem(text: "5-4-3-2-1 method: 5 things you see, 4 you hear, 3 you touch, 2 you smell, 1 you taste")
                GuideItem(text: "Hold an ice cube or splash cold water on your face")
                GuideItem(text: "Listen to calming music or sounds")
            }
        }
    }

    private var anxietyContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            GuideSection(title: "Breathing Exercises", icon: "wind") {
                GuideItem(text: "Box breathing: Inhale 4, hold 4, exhale 4, hold 4")
                GuideItem(text: "4-7-8 breathing: Inhale 4, hold 7, exhale 8")
                GuideItem(text: "Focus on making your exhale longer than your inhale")
            }

            GuideSection(title: "Mindfulness Tips", icon: "brain.head.profile") {
                GuideItem(text: "Practice the 'STOP' technique: Stop, Take a breath, Observe, Proceed")
                GuideItem(text: "Use progressive muscle relaxation")
                GuideItem(text: "Try meditation apps like Headspace or Calm")
            }
        }
    }

    private var griefContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            GuideSection(title: "Understanding Grief", icon: "heart.fill") {
                GuideItem(text: "Grief is a natural response to loss")
                GuideItem(text: "There's no 'right' way to grieve or timeline to follow")
                GuideItem(text: "It's okay to feel a range of emotions")
            }

            GuideSection(title: "Coping Strategies", icon: "hands.and.sparkles.fill") {
                GuideItem(text: "Allow yourself to feel without judgment")
                GuideItem(text: "Create meaningful rituals or memorials")
                GuideItem(text: "Connect with others who understand your loss")
                GuideItem(text: "Consider professional grief counseling")
            }
        }
    }

    private var sleepContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            GuideSection(title: "Sleep Hygiene", icon: "bed.double.fill") {
                GuideItem(text: "Keep a consistent sleep schedule")
                GuideItem(text: "Create a relaxing bedtime routine")
                GuideItem(text: "Avoid screens 1 hour before bed")
                GuideItem(text: "Keep your bedroom cool, dark, and quiet")
            }

            GuideSection(title: "Relaxation Techniques", icon: "moon.stars.fill") {
                GuideItem(text: "Try progressive muscle relaxation")
                GuideItem(text: "Practice deep breathing or meditation")
                GuideItem(text: "Listen to calming sounds or white noise")
                GuideItem(text: "Write in a journal to clear your mind")
            }
        }
    }
}

struct GuideSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appPrimary)

                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
            }

            VStack(alignment: .leading, spacing: 12) {
                content
            }
        }
        .padding(20)
        .appCardStyle()
    }
}

struct GuideItem: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.appPrimary)
                .frame(width: 6, height: 6)
                .padding(.top, 8)

            Text(text)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct GuidedBreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isBreathing = false
    @State private var breathPhase: BreathPhase = .inhale
    @State private var timer: Timer?
    @State private var cycleCount = 0

    enum BreathPhase {
        case inhale, hold, exhale

        var instruction: String {
            switch self {
            case .inhale: return "Breathe In"
            case .hold: return "Hold"
            case .exhale: return "Breathe Out"
            }
        }

        var duration: TimeInterval {
            switch self {
            case .inhale: return 4.0
            case .hold: return 4.0
            case .exhale: return 6.0
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appGradientBackground.ignoresSafeArea()

                VStack(spacing: 40) {

                    VStack(spacing: 8) {
                        Text("Guided Breathing")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.appTextPrimary)

                        Text("Follow the circle and breathe")
                            .font(.appSubheadline)
                            .foregroundColor(.appTextSecondary)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(Color.appPrimary.opacity(0.3), lineWidth: 3)
                            .frame(width: 200, height: 200)

                        Circle()
                            .fill(Color.appGradientPrimary)
                            .frame(width: isBreathing ? 200 : 100, height: isBreathing ? 200 : 100)
                            .animation(.easeInOut(duration: breathPhase.duration), value: isBreathing)
                    }

                    Text(breathPhase.instruction)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.appTextPrimary)

                    Text("Cycle \(cycleCount)")
                        .font(.appBody)
                        .foregroundColor(.appTextSecondary)

                    Spacer()

                    HStack(spacing: 20) {
                        Button(isBreathing ? "Stop" : "Start") {
                            toggleBreathing()
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .appButtonPrimary()

                        Button("Reset") {
                            resetBreathing()
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .appButtonSecondary()
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        timer?.invalidate()
                        dismiss()
                    }
                    .foregroundColor(.appPrimary)
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func toggleBreathing() {
        if isBreathing {
            timer?.invalidate()
            isBreathing = false
        } else {
            startBreathingCycle()
        }
    }

    private func startBreathingCycle() {
        isBreathing = true
        breathPhase = .inhale

        timer = Timer.scheduledTimer(withTimeInterval: breathPhase.duration, repeats: false) { _ in
            nextBreathPhase()
        }
    }

    private func nextBreathPhase() {
        switch breathPhase {
        case .inhale:
            breathPhase = .hold
        case .hold:
            breathPhase = .exhale
        case .exhale:
            breathPhase = .inhale
            cycleCount += 1
        }

        if isBreathing {
            timer = Timer.scheduledTimer(withTimeInterval: breathPhase.duration, repeats: false) { _ in
                nextBreathPhase()
            }
        }
    }

    private func resetBreathing() {
        timer?.invalidate()
        isBreathing = false
        breathPhase = .inhale
        cycleCount = 0
    }
}

struct ResourceDetailView: View {
    let resource: MentalHealthResource
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(resource.type.color.opacity(0.2))
                                    .frame(width: 64, height: 64)

                                Image(systemName: resource.type.icon)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(resource.type.color)
                            }

                            Spacer()

                            Button("Done") {
                                dismiss()
                            }
                            .foregroundColor(.appPrimary)
                        }

                        Text(resource.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.appTextPrimary)

                        Text(resource.description)
                            .font(.appSubheadline)
                            .foregroundColor(.appTextSecondary)
                    }

                    if resource.contactInfo.contains("1-800") || resource.contactInfo.contains("988") {
                        Button(action: {
                            let cleanNumber = resource.contactInfo.filter { $0.isNumber || $0 == "-" }
                            if let url = URL(string: "tel://\(cleanNumber)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("Call \(resource.contactInfo)")
                                Spacer()
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.appTextPrimary)
                            .padding(16)
                            .background(Color.appSuccess)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(20)
            }
            .background(Color.appGradientBackground.ignoresSafeArea())
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    MentalHelpView()
}
