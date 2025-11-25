import SwiftUI

struct QuizView: View {
    @StateObject private var educationService = EducationService.shared
    @Environment(\.dismiss) private var dismiss

    let quiz: Quiz
    let module: LearningModule

    @State private var currentQuestionIndex = 0
    @State private var selectedAnswers: [UUID: [Int]] = [:]
    @State private var showExplanation = false
    @State private var quizStartTime = Date()
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showResults = false
    @State private var isSubmitting = false
    @State private var animateProgress = false

    private var currentQuestion: QuizQuestion {
        quiz.questions[currentQuestionIndex]
    }

    private var isLastQuestion: Bool {
        currentQuestionIndex == quiz.questions.count - 1
    }

    private var progress: Double {
        Double(currentQuestionIndex + 1) / Double(quiz.questions.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appGradientBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection
                    progressSection
                    questionSection
                    answerSection
                    navigationSection
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupQuiz()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .sheet(isPresented: $showResults) {
            QuizResultsView(
                quiz: quiz,
                module: module,
                answers: selectedAnswers,
                timeSpent: Date().timeIntervalSince(quizStartTime)
            )
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
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
                    Text(quiz.title)
                        .font(.appSubheadline.bold())
                        .foregroundColor(.appTextPrimary)

                    if let timeLimit = quiz.timeLimit, timeLimit > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(formatTime(timeRemaining))
                                .font(.appCaption)
                                .monospacedDigit()
                        }
                        .foregroundColor(timeRemaining < 60 ? .appError : .appTextSecondary)
                        .animation(.easeInOut(duration: 0.3), value: timeRemaining < 60)
                    }
                }
            }

            Text("Question \(currentQuestionIndex + 1) of \(quiz.questions.count)")
                .font(.appCaption)
                .foregroundColor(.appTextTertiary)
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

                Text("\(currentQuestion.points) pts")
                    .font(.appSmall.bold())
                    .foregroundColor(.appPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(currentQuestion.question)
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let mediaURL = currentQuestion.mediaURL {
                AsyncImage(url: mediaURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appCard)
                        .frame(height: 200)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .appCardStyle()
        .padding(.horizontal, 20)
    }

    private var answerSection: some View {
        VStack(spacing: 12) {
            ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                AnswerOptionView(
                    option: option,
                    index: index,
                    isSelected: selectedAnswers[currentQuestion.id]?.contains(index) ?? false,
                    questionType: currentQuestion.type,
                    showCorrectAnswer: showExplanation,
                    isCorrect: currentQuestion.correctAnswers.contains(index)
                ) {
                    selectAnswer(index)
                }
            }

            if showExplanation {
                explanationView
            }
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.3), value: showExplanation)
    }

    private var explanationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.appWarning)
                    .font(.title3)

                Text("Explanation")
                    .font(.appSubheadline.bold())
                    .foregroundColor(.appTextPrimary)
            }

            Text(currentQuestion.explanation)
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(Color.appCard.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .transition(.opacity.combined(with: .scale))
    }

    private var navigationSection: some View {
        HStack(spacing: 16) {
            if currentQuestionIndex > 0 {
                Button(action: previousQuestion) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.appSubheadline)
                    .foregroundColor(.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Button(action: nextQuestionOrSubmit) {
                HStack {
                    Text(isLastQuestion ? "Submit Quiz" : "Next")
                    if !isLastQuestion {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.appSubheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .appButtonPrimary()
            }
            .disabled(selectedAnswers[currentQuestion.id]?.isEmpty ?? true)
            .opacity(selectedAnswers[currentQuestion.id]?.isEmpty ?? true ? 0.6 : 1.0)
            .scaleEffect(animateProgress ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animateProgress)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .onAppear {
            if !(selectedAnswers[currentQuestion.id]?.isEmpty ?? true) {
                animateProgress = true
            }
        }
        .onChange(of: selectedAnswers[currentQuestion.id]) { _ in
            animateProgress = !(selectedAnswers[currentQuestion.id]?.isEmpty ?? true)
        }
    }

    private func setupQuiz() {
        quizStartTime = Date()

        if let timeLimit = quiz.timeLimit, timeLimit > 0 {
            timeRemaining = timeLimit
            startTimer()
        }

        for question in quiz.questions {
            selectedAnswers[question.id] = []
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {

                submitQuiz()
            }
        }
    }

    private func selectAnswer(_ index: Int) {
        let questionId = currentQuestion.id

        switch currentQuestion.type {
        case .multipleChoice, .trueFalse:

            selectedAnswers[questionId] = [index]

        case .multipleSelect:

            var currentSelections = selectedAnswers[questionId] ?? []
            if currentSelections.contains(index) {
                currentSelections.removeAll { $0 == index }
            } else {
                currentSelections.append(index)
            }
            selectedAnswers[questionId] = currentSelections

        case .shortAnswer:

            break
        }

        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        if currentQuestion.type == .multipleChoice || currentQuestion.type == .trueFalse {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !showExplanation {
                    showExplanation = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if !isLastQuestion {
                            nextQuestion()
                        }
                    }
                }
            }
        }
    }

    private func nextQuestion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showExplanation = false
            currentQuestionIndex += 1
        }
    }

    private func previousQuestion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showExplanation = false
            currentQuestionIndex -= 1
        }
    }

    private func nextQuestionOrSubmit() {
        if isLastQuestion {
            submitQuiz()
        } else {
            if showExplanation {
                nextQuestion()
            } else {
                showExplanation = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    nextQuestion()
                }
            }
        }
    }

    private func submitQuiz() {
        timer?.invalidate()
        isSubmitting = true

        let attempt = QuizAttempt(
            id: UUID(),
            quizId: quiz.id,
            startDate: quizStartTime,
            endDate: Date(),
            answers: selectedAnswers,
            score: calculateScore(),
            isCompleted: true
        )

        educationService.submitQuizAttempt(attempt)

        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()

        showResults = true
    }

    private func calculateScore() -> Double {
        var totalPoints = 0
        var earnedPoints = 0

        for question in quiz.questions {
            totalPoints += question.points

            if let userAnswers = selectedAnswers[question.id] {
                let correctAnswers = Set(question.correctAnswers)
                let userAnswerSet = Set(userAnswers)

                if correctAnswers == userAnswerSet {
                    earnedPoints += question.points
                }
            }
        }

        return totalPoints > 0 ? Double(earnedPoints) / Double(totalPoints) : 0.0
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct AnswerOptionView: View {
    let option: String
    let index: Int
    let isSelected: Bool
    let questionType: QuestionType
    let showCorrectAnswer: Bool
    let isCorrect: Bool
    let onTap: () -> Void

    private var backgroundColor: Color {
        if showCorrectAnswer {
            if isCorrect {
                return .appSuccess.opacity(0.2)
            } else if isSelected && !isCorrect {
                return .appError.opacity(0.2)
            }
        } else if isSelected {
            return .appPrimary.opacity(0.2)
        }
        return Color.appCard
    }

    private var borderColor: Color {
        if showCorrectAnswer {
            if isCorrect {
                return .appSuccess
            } else if isSelected && !isCorrect {
                return .appError
            }
        } else if isSelected {
            return .appPrimary
        }
        return Color.appBorder
    }

    private var iconName: String {
        switch questionType {
        case .multipleChoice, .trueFalse:
            if showCorrectAnswer {
                return isCorrect ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : "circle")
            }
            return isSelected ? "largecircle.fill.circle" : "circle"

        case .multipleSelect:
            if showCorrectAnswer {
                return isCorrect ? "checkmark.square.fill" : (isSelected ? "xmark.square.fill" : "square")
            }
            return isSelected ? "checkmark.square.fill" : "square"

        case .shortAnswer:
            return "text.cursor"
        }
    }

    private var iconColor: Color {
        if showCorrectAnswer {
            if isCorrect {
                return .appSuccess
            } else if isSelected && !isCorrect {
                return .appError
            }
        } else if isSelected {
            return .appPrimary
        }
        return .appTextSecondary
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 24)

                Text(option)
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if showCorrectAnswer && isCorrect {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.appWarning)
                }
            }
            .padding(16)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.3), value: showCorrectAnswer)
        .disabled(showCorrectAnswer)
    }
}

struct QuizResultsView: View {
    @StateObject private var educationService = EducationService.shared
    @Environment(\.dismiss) private var dismiss

    let quiz: Quiz
    let module: LearningModule
    let answers: [UUID: [Int]]
    let timeSpent: TimeInterval

    private var score: Double {
        var totalPoints = 0
        var earnedPoints = 0

        for question in quiz.questions {
            totalPoints += question.points

            if let userAnswers = answers[question.id] {
                let correctAnswers = Set(question.correctAnswers)
                let userAnswerSet = Set(userAnswers)

                if correctAnswers == userAnswerSet {
                    earnedPoints += question.points
                }
            }
        }

        return totalPoints > 0 ? Double(earnedPoints) / Double(totalPoints) : 0.0
    }

    private var passed: Bool {
        score >= quiz.passingScore
    }

    private var performanceMessage: String {
        switch score {
        case 0.9...:
            return "Outstanding! You've mastered this material."
        case 0.8..<0.9:
            return "Great job! You have a solid understanding."
        case 0.7..<0.8:
            return "Good work! You passed the quiz."
        case 0.6..<0.7:
            return "Close! Review the material and try again."
        default:
            return "Keep studying! You'll get it next time."
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appGradientBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        scoreSection
                        statisticsSection
                        reviewSection
                        actionButtons
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Quiz Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(passed ? .appSuccess : .appError)

            Text(passed ? "Congratulations!" : "Keep Trying!")
                .font(.appTitle)
                .foregroundColor(.appTextPrimary)

            Text(performanceMessage)
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var scoreSection: some View {
        VStack(spacing: 20) {
            HStack {
                VStack {
                    Text("\(Int(score * 100))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.appPrimary)
                    Text("SCORE")
                        .font(.appSmall.bold())
                        .foregroundColor(.appTextSecondary)
                }

                Spacer()

                VStack {
                    Text("\(Int(score * 100))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.appTextPrimary)
                    Text("PERCENT")
                        .font(.appSmall.bold())
                        .foregroundColor(.appTextSecondary)
                }
            }

            ProgressView(value: score)
                .progressViewStyle(LinearProgressViewStyle(tint: passed ? .appSuccess : .appError))
                .scaleEffect(x: 1, y: 3, anchor: .center)
        }
        .padding(24)
        .appCardStyle()
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quiz Statistics")
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)

            HStack {
                StatisticView(
                    title: "Questions",
                    value: "\(quiz.questions.count)",
                    icon: "questionmark.circle"
                )

                StatisticView(
                    title: "Time Spent",
                    value: formatTime(timeSpent),
                    icon: "clock"
                )

                StatisticView(
                    title: "Correct",
                    value: "\(correctAnswersCount)/\(quiz.questions.count)",
                    icon: "checkmark.circle"
                )
            }
        }
        .padding(20)
        .appCardStyle()
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Question Review")
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)

            LazyVStack(spacing: 12) {
                ForEach(Array(quiz.questions.enumerated()), id: \.element.id) { index, question in
                    QuestionReviewRow(
                        question: question,
                        index: index + 1,
                        userAnswers: answers[question.id] ?? [],
                        isCorrect: isAnswerCorrect(question: question)
                    )
                }
            }
        }
        .padding(20)
        .appCardStyle()
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            if !passed && canRetakeQuiz() {
                Button(action: retakeQuiz) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retake Quiz")
                    }
                    .font(.appSubheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .appButtonPrimary()
                }
            }

            Button(action: reviewModule) {
                HStack {
                    Image(systemName: "book.fill")
                    Text("Review Module")
                }
                .font(.appSubheadline)
                .foregroundColor(.appTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var correctAnswersCount: Int {
        quiz.questions.filter { isAnswerCorrect(question: $0) }.count
    }

    private func isAnswerCorrect(question: QuizQuestion) -> Bool {
        guard let userAnswers = answers[question.id] else { return false }
        let correctAnswers = Set(question.correctAnswers)
        let userAnswerSet = Set(userAnswers)
        return correctAnswers == userAnswerSet
    }

    private func canRetakeQuiz() -> Bool {
        let attempts = module.quizAttempts.filter { $0.quizId == quiz.id }.count
        return attempts < quiz.maxAttempts
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return "\(minutes)m \(remainingSeconds)s"
    }

    private func retakeQuiz() {

        dismiss()
    }

    private func reviewModule() {

        dismiss()
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appPrimary)

            Text(value)
                .font(.appSubheadline.bold())
                .foregroundColor(.appTextPrimary)

            Text(title)
                .font(.appSmall)
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuestionReviewRow: View {
    let question: QuizQuestion
    let index: Int
    let userAnswers: [Int]
    let isCorrect: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isCorrect ? .appSuccess : .appError)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Question \(index)")
                    .font(.appCaption.bold())
                    .foregroundColor(.appTextSecondary)

                Text(question.question)
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Text("\(question.points) pts")
                .font(.appSmall)
                .foregroundColor(isCorrect ? .appSuccess : .appTextTertiary)
        }
        .padding(12)
        .background(Color.appCard.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        QuizView(
            quiz: Quiz.sample(),
            module: LearningModule.sample()
        )
    }
}
