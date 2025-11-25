import SwiftUI

struct LessonDetailView: View {
    @StateObject private var educationService = EducationService.shared
    @Environment(\.dismiss) private var dismiss

    let lesson: Lesson
    let module: LearningModule

    @State private var readingProgress: Double = 0.0
    @State private var startTime = Date()
    @State private var showNotes = false
    @State private var userNotes = ""
    @State private var isBookmarked = false
    @State private var showQuiz = false
    @State private var currentSectionIndex = 0
    @State private var animateProgress = false

    @State private var timer: Timer?
    @State private var readingTime: TimeInterval = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appGradientBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                        progressIndicator
                        contentSections
                        actionButtons
                    }
                }
                .onAppear {
                    setupLesson()
                }
                .onDisappear {
                    completeLesson()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showNotes) {
            NotesView(notes: $userNotes, onSave: saveNotes)
        }
        .sheet(isPresented: $showQuiz) {
            if let quiz = module.quiz {
                QuizView(quiz: quiz, module: module)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.appTextPrimary)
                        .padding(12)
                        .background(Color.appCard)
                        .clipShape(Circle())
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: { toggleBookmark() }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.title3)
                            .foregroundColor(isBookmarked ? .appPrimary : .appTextSecondary)
                    }

                    Button(action: { showNotes = true }) {
                        Image(systemName: "note.text")
                            .font(.title3)
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.appCard)
                .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(lesson.title)
                    .font(.appTitle)
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.leading)

                HStack {
                    Label(lesson.formattedReadingTime, systemImage: "clock")
                        .font(.appCaption)
                        .foregroundColor(.appTextSecondary)

                    Spacer()

                    Text("Lesson 1 of \(module.lessons.count)")
                        .font(.appCaption)
                        .foregroundColor(.appTextTertiary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var progressIndicator: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Reading Progress")
                    .font(.appSubheadline)
                    .foregroundColor(.appTextSecondary)

                Spacer()

                Text("\(Int(readingProgress * 100))%")
                    .font(.appSubheadline.bold())
                    .foregroundColor(.appPrimary)
            }

            ProgressView(value: readingProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .appPrimary))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .animation(.easeInOut(duration: 0.3), value: readingProgress)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var contentSections: some View {
        LazyVStack(spacing: 24) {
            ForEach(Array(lesson.content.sections.enumerated()), id: \.element.id) { index, section in
                ContentSectionView(
                    section: section,
                    isVisible: index <= currentSectionIndex,
                    onVisible: {
                        updateReadingProgress(for: index)
                    }
                )
            }

        }
        .padding(.horizontal, 20)
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            if readingProgress >= 0.8 && !lesson.isCompleted {
                Button(action: markAsComplete) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark as Complete")
                            .font(.appSubheadline.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .appButtonPrimary()
                }
                .scaleEffect(animateProgress ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: animateProgress)
                .onAppear {
                    animateProgress = true
                }
            }

            if lesson.isCompleted && module.quiz != nil {
                Button(action: { showQuiz = true }) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                        Text("Take Quiz")
                            .font(.appSubheadline.bold())
                    }
                    .foregroundColor(.appTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appPrimary, lineWidth: 2)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }

    private func setupLesson() {
        startTime = Date()
        userNotes = educationService.persistenceService.loadLessonNotes(lessonId: lesson.id)
        isBookmarked = module.bookmarkedLessons.contains(lesson.id)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            readingTime += 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            simulateReading()
        }
    }

    private func simulateReading() {
        let totalSections = lesson.content.sections.count
        guard currentSectionIndex < totalSections else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if currentSectionIndex < totalSections - 1 {
                currentSectionIndex += 1
                simulateReading()
            }
        }
    }

    private func updateReadingProgress(for sectionIndex: Int) {
        let totalSections = lesson.content.sections.count
        let newProgress = Double(sectionIndex + 1) / Double(totalSections)

        withAnimation(.easeInOut(duration: 0.3)) {
            readingProgress = newProgress
        }
    }

    private func markAsComplete() {
        timer?.invalidate()
        let timeSpent = Date().timeIntervalSince(startTime)
        educationService.completeLesson(lesson, timeSpent: timeSpent)

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        dismiss()
    }

    private func completeLesson() {
        timer?.invalidate()

        if readingTime > 30 {

        }
    }

    private func toggleBookmark() {
        educationService.toggleBookmark(lessonId: lesson.id, moduleId: module.id)
        isBookmarked.toggle()

        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    private func saveNotes() {
        educationService.updateLessonNotes(lessonId: lesson.id, moduleId: module.id, notes: userNotes)
    }
}

struct ContentSectionView: View {
    let section: ContentSection
    let isVisible: Bool
    let onVisible: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = section.title {
                Text(title)
                    .font(.appHeadline)
                    .foregroundColor(.appTextPrimary)
            }

            Group {
                switch section.type {
                case .text:
                    Text(section.content)
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)

                case .image:
                    if let mediaURL = section.mediaURL {
                        AsyncImage(url: mediaURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
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

                case .checklist:
                    ChecklistView(items: section.content.components(separatedBy: "\n"))

                case .infographic:
                    InfographicView(content: section.content)

                default:
                    Text(section.content)
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)
                }
            }
        }
        .padding(20)
        .appCardStyle()
        .opacity(isVisible ? 1 : 0.3)
        .scaleEffect(isVisible ? 1 : 0.95)
        .animation(.easeInOut(duration: 0.5), value: isVisible)
        .onAppear {
            if !hasAppeared && isVisible {
                hasAppeared = true
                onVisible()
            }
        }
    }
}

struct InteractiveElementView: View {
    let element: InteractiveElement

    var body: some View {
        switch element {
        case .checklistItem(let item, let isChecked):
            ChecklistItemView(item: item, isChecked: isChecked)
        case .quiz(let quizId):
            QuickQuizView(quizId: quizId)
        case .flashcard(let cardId):
            FlashcardPreview(cardId: cardId)
        case .simulation(let title):
            SimulationView(title: title)
        case .calculator(let title):
            CalculatorView(title: title)
        }
    }
}

struct ChecklistView: View {
    let items: [String]
    @State private var checkedItems: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                ChecklistItemView(
                    item: item,
                    isChecked: checkedItems.contains(index)
                ) {
                    toggleItem(index)
                }
            }
        }
    }

    private func toggleItem(_ index: Int) {
        if checkedItems.contains(index) {
            checkedItems.remove(index)
        } else {
            checkedItems.insert(index)
        }
    }
}

struct ChecklistItemView: View {
    let item: String
    let isChecked: Bool
    var onToggle: (() -> Void)? = nil

    var body: some View {
        Button(action: { onToggle?() }) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? .appSuccess : .appTextSecondary)
                    .font(.title3)

                Text(item)
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                    .strikethrough(isChecked)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isChecked)
    }
}

struct InfographicView: View {
    let content: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.largeTitle)
                .foregroundColor(.appPrimary)

            Text(content)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Color.appGradientPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct QuickQuizView: View {
    let quizId: UUID

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.appPrimary)
                    .font(.title2)

                Text("Quick Knowledge Check")
                    .font(.appSubheadline.bold())
                    .foregroundColor(.appTextPrimary)

                Spacer()
            }

            Text("Test what you've learned so far")
                .font(.appCaption)
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Start Quiz") {

            }
            .font(.appCaption.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .appButtonPrimary()
        }
        .padding(16)
        .appCardStyle()
    }
}

struct FlashcardPreview: View {
    let cardId: UUID

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundColor(.appSecondary)
                    .font(.title2)

                Text("Flashcard Review")
                    .font(.appSubheadline.bold())
                    .foregroundColor(.appTextPrimary)

                Spacer()
            }

            Button("Review Flashcards") {

            }
            .font(.appCaption.bold())
            .foregroundColor(.appTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .appCardStyle()
    }
}

struct SimulationView: View {
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .foregroundColor(.appAccent)
                    .font(.title2)

                Text(title)
                    .font(.appSubheadline.bold())
                    .foregroundColor(.appTextPrimary)

                Spacer()
            }

            Button("Start Simulation") {

            }
            .font(.appCaption.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.appAccent)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .appCardStyle()
    }
}

struct CalculatorView: View {
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calculator.fill")
                    .foregroundColor(.appInfo)
                    .font(.title2)

                Text(title)
                    .font(.appSubheadline.bold())
                    .foregroundColor(.appTextPrimary)

                Spacer()
            }

            Button("Open Calculator") {

            }
            .font(.appCaption.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.appInfo)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .appCardStyle()
    }
}

struct NotesView: View {
    @Binding var notes: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TextEditor(text: $notes)
                    .font(.appBody)
                    .padding(16)
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(20)

                Spacer()
            }
            .background(Color.appGradientBackground)
            .navigationTitle("My Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct LessonDetailView_Previews: PreviewProvider {
    static var previews: some View {
        LessonDetailView(
            lesson: Lesson.sample(),
            module: LearningModule.sample()
        )
    }
}
