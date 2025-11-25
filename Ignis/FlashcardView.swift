import SwiftUI

struct FlashcardView: View {
    @StateObject private var educationService = EducationService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var currentCardIndex = 0
    @State private var showAnswer = false
    @State private var cardOffset = CGSize.zero
    @State private var cardRotation: Double = 0
    @State private var studySession: FlashcardStudySession
    @State private var sessionStats = SessionStats()

    private var reviewCards: [Flashcard]

    init() {
        let cards = EducationService.shared.getFlashcardsForReview()
        self.reviewCards = Array(cards.prefix(20))
        self._studySession = State(initialValue: FlashcardStudySession(cards: cards))
    }

    private var currentCard: Flashcard? {
        guard currentCardIndex < reviewCards.count else { return nil }
        return reviewCards[currentCardIndex]
    }

    private var progress: Double {
        guard !reviewCards.isEmpty else { return 1.0 }
        return Double(currentCardIndex) / Double(reviewCards.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appGradientBackground.ignoresSafeArea()

                if let card = currentCard {
                    VStack(spacing: 0) {
                        headerSection
                        progressSection
                        cardSection(card: card)
                        difficultyButtons
                    }
                } else {
                    completionView
                }
            }
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onChanged { value in
                    cardOffset = value.translation
                    cardRotation = Double(value.translation.width / 10)
                }
                .onEnded { value in
                    handleSwipe(value)
                }
        )
    }

    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.appTextPrimary)
                    .padding(12)
                    .background(Color.appCard)
                    .clipShape(Circle())
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Flashcard Review")
                    .font(.appSubheadline.bold())
                    .foregroundColor(.appTextPrimary)

                Text("\(currentCardIndex + 1) of \(reviewCards.count)")
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var progressSection: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .appPrimary))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .animation(.easeInOut(duration: 0.3), value: progress)

            HStack {
                Text("\(Int(progress * 100))% Complete")
                    .font(.appSmall)
                    .foregroundColor(.appTextSecondary)

                Spacer()

                HStack(spacing: 16) {
                    StatLabel(
                        value: "\(sessionStats.correct)",
                        label: "Correct",
                        color: .appSuccess
                    )

                    StatLabel(
                        value: "\(sessionStats.incorrect)",
                        label: "Incorrect",
                        color: .appError
                    )

                    StatLabel(
                        value: "\(sessionStats.streak)",
                        label: "Streak",
                        color: .appPrimary
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func cardSection(card: Flashcard) -> some View {
        VStack(spacing: 20) {
            FlashcardView3D(
                card: card,
                showAnswer: showAnswer,
                offset: cardOffset,
                rotation: cardRotation
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showAnswer.toggle()
                }
            }

            if !showAnswer {
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showAnswer = true
                    }
                }) {
                    HStack {
                        Image(systemName: "eye.fill")
                        Text("Show Answer")
                    }
                    .font(.appSubheadline)
                    .foregroundColor(.appTextPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.appCard)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
    }

    private var difficultyButtons: some View {
        VStack(spacing: 16) {
            if showAnswer {
                Text("How well did you know this?")
                    .font(.appSubheadline)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    ForEach(FlashcardDifficulty.allCases, id: \.self) { difficulty in
                        DifficultyButton(
                            difficulty: difficulty,
                            action: { selectDifficulty(difficulty) }
                        )
                    }
                }
            } else {

                if let currentCard = currentCard, !currentCard.tags.isEmpty {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.appTextTertiary)
                            .font(.caption)

                        Text(currentCard.tags.joined(separator: " • "))
                            .font(.appSmall)
                            .foregroundColor(.appTextTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.appCard.opacity(0.5))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .animation(.easeInOut(duration: 0.3), value: showAnswer)
    }

    private var completionView: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.appSuccess)

            VStack(spacing: 16) {
                Text("Session Complete!")
                    .font(.appTitle)
                    .foregroundColor(.appTextPrimary)

                Text("Great job! You've reviewed all your flashcards for today.")
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            SessionSummaryView(stats: sessionStats, totalCards: reviewCards.count)

            Button(action: { dismiss() }) {
                Text("Continue Learning")
                    .font(.appSubheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .appButtonPrimary()
            }
        }
        .padding(20)
    }

    private func selectDifficulty(_ difficulty: FlashcardDifficulty) {
        guard let card = currentCard else { return }

        updateSessionStats(difficulty: difficulty)

        educationService.reviewFlashcard(card, difficulty: difficulty)

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        nextCard()
    }

    private func updateSessionStats(difficulty: FlashcardDifficulty) {
        switch difficulty {
        case .again:
            sessionStats.incorrect += 1
            sessionStats.streak = 0
        case .hard:
            sessionStats.correct += 1
            sessionStats.streak += 1
        case .good:
            sessionStats.correct += 1
            sessionStats.streak += 1
        case .easy:
            sessionStats.correct += 1
            sessionStats.streak += 1
        }

        sessionStats.maxStreak = max(sessionStats.maxStreak, sessionStats.streak)
    }

    private func nextCard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showAnswer = false
            currentCardIndex += 1
            cardOffset = .zero
            cardRotation = 0
        }
    }

    private func handleSwipe(_ value: DragGesture.Value) {
        let swipeThreshold: CGFloat = 100

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            if abs(value.translation.width) > swipeThreshold {
                if value.translation.width > 0 {

                    if showAnswer {
                        selectDifficulty(.easy)
                    }
                } else {

                    if showAnswer {
                        selectDifficulty(.again)
                    }
                }
            } else {

                cardOffset = .zero
                cardRotation = 0
            }
        }
    }
}

struct FlashcardView3D: View {
    let card: Flashcard
    let showAnswer: Bool
    let offset: CGSize
    let rotation: Double

    @State private var isFlipped = false

    var body: some View {
        ZStack {

            CardFace(
                text: card.back,
                isAnswer: true,
                difficulty: card.difficulty
            )
            .rotation3DEffect(
                .degrees(isFlipped ? 0 : 180),
                axis: (x: 0, y: 1, z: 0)
            )
            .opacity(showAnswer ? 1 : 0)

            CardFace(
                text: card.front,
                isAnswer: false,
                difficulty: card.difficulty
            )
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .opacity(showAnswer ? 0 : 1)
        }
        .frame(height: 300)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(1.0 - abs(offset.width) / 1000)
        .onChange(of: showAnswer) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                isFlipped = showAnswer
            }
        }
    }
}

struct CardFace: View {
    let text: String
    let isAnswer: Bool
    let difficulty: DifficultyLevel

    var body: some View {
        VStack(spacing: 20) {
            if !isAnswer {
                HStack {
                    Text("Question")
                        .font(.appSmall.bold())
                        .foregroundColor(.appTextTertiary)

                    Spacer()

                    DifficultyBadge(difficulty: difficulty)
                }
            } else {
                HStack {
                    Text("Answer")
                        .font(.appSmall.bold())
                        .foregroundColor(.appTextTertiary)

                    Spacer()

                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.appWarning)
                        .font(.caption)
                }
            }

            Spacer()

            Text(text)
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appGradientCard)
                .shadow(color: .appPrimary.opacity(0.1), radius: 12, x: 0, y: 8)
        )
    }
}

struct DifficultyButton: View {
    let difficulty: FlashcardDifficulty
    let action: () -> Void

    private var config: (icon: String, title: String, subtitle: String) {
        switch difficulty {
        case .again:
            return ("arrow.clockwise", "Again", "< 1m")
        case .hard:
            return ("minus.circle", "Hard", "< 6m")
        case .good:
            return ("checkmark.circle", "Good", "< 10m")
        case .easy:
            return ("checkmark.circle.fill", "Easy", "4d")
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: config.icon)
                    .font(.title2)
                    .foregroundColor(difficulty.color)

                Text(config.title)
                    .font(.appCaption.bold())
                    .foregroundColor(.appTextPrimary)

                Text(config.subtitle)
                    .font(.appSmall)
                    .foregroundColor(.appTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(difficulty.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}

struct DifficultyBadge: View {
    let difficulty: DifficultyLevel

    var body: some View {
        Text(difficulty.rawValue)
            .font(.appSmall.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(difficulty.color)
            .clipShape(Capsule())
    }
}

struct StatLabel: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.appCaption.bold())
                .foregroundColor(color)

            Text(label)
                .font(.appSmall)
                .foregroundColor(.appTextTertiary)
        }
    }
}

struct SessionSummaryView: View {
    let stats: SessionStats
    let totalCards: Int

    private var accuracy: Double {
        let total = stats.correct + stats.incorrect
        return total > 0 ? Double(stats.correct) / Double(total) : 0.0
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Session Summary")
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)

            HStack(spacing: 20) {
                SummaryStatView(
                    title: "Cards Reviewed",
                    value: "\(totalCards)",
                    icon: "rectangle.stack.fill",
                    color: .appPrimary
                )

                SummaryStatView(
                    title: "Accuracy",
                    value: "\(Int(accuracy * 100))%",
                    icon: "target",
                    color: .appSuccess
                )

                SummaryStatView(
                    title: "Best Streak",
                    value: "\(stats.maxStreak)",
                    icon: "flame.fill",
                    color: .appWarning
                )
            }
        }
        .padding(20)
        .appCardStyle()
    }
}

struct SummaryStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.appSubheadline.bold())
                .foregroundColor(.appTextPrimary)

            Text(title)
                .font(.appSmall)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FlashcardStudySession {
    let cards: [Flashcard]
    let startTime = Date()
    var endTime: Date?

    var duration: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }
}

struct SessionStats {
    var correct = 0
    var incorrect = 0
    var streak = 0
    var maxStreak = 0
}

struct FlashcardView_Previews: PreviewProvider {
    static var previews: some View {
        FlashcardView()
    }
}
