import SwiftUI

struct EducationView: View {
    @StateObject private var educationService = EducationService.shared

    @State private var selectedModule: LearningModule?
    @State private var selectedLesson: Lesson?
    @State private var showFlashcards = false
    @State private var showQuiz = false
    @State private var showSearch = false
    @State private var showStats = false
    @State private var showSettings = false

    @State private var searchText = ""
    @State private var animateCards = false

    private var filteredModules: [LearningModule] {
        if !searchText.isEmpty {
            return educationService.searchModules(query: searchText)
        }

        return educationService.modules
    }

    private var todaysLesson: Lesson? {

        for module in educationService.modules where module.isUnlocked {
            for lesson in module.lessons where !lesson.isCompleted {
                return lesson
            }
        }
        return nil
    }

    private var flashcardsForReview: [Flashcard] {
        educationService.getFlashcardsForReview()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appGradientBackground.ignoresSafeArea()

                if educationService.isLoading {
                    loadingView
                } else {
                    mainContent
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                setupEducationView()
            }
            .refreshable {
                await refreshData()
            }
        }
        .sheet(item: $selectedModule) { module in
            ModuleDetailView(module: module)
        }
        .sheet(item: $selectedLesson) { lesson in
            if let module = educationService.modules.first(where: { $0.lessons.contains(where: { $0.id == lesson.id }) }) {
                LessonDetailView(lesson: lesson, module: module)
            }
        }
        .sheet(isPresented: $showFlashcards) {
            FlashcardView()
        }
        .sheet(isPresented: $showStats) {
            StatisticsView()
        }
        .sheet(isPresented: $showSettings) {
            EducationSettingsView()
        }
        .alert("Education Error", isPresented: .constant(educationService.error != nil)) {
            Button("OK") {
                educationService.error = nil
            }
        } message: {
            Text(educationService.error?.localizedDescription ?? "")
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                .scaleEffect(1.5)

            Text("Loading your learning journey...")
                .font(.appSubheadline)
                .foregroundColor(.appTextSecondary)
        }
    }

    private var mainContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 24) {
                headerSection

                if showSearch {
                    searchSection
                }

                if let lesson = todaysLesson {
                    todaysLessonCard(lesson: lesson)
                }

                if !flashcardsForReview.isEmpty {
                    flashcardReviewCard
                }

                moduleGrid
                quickActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                animateCards = true
            }
        }
    }

    private func setupEducationView() {
        if educationService.modules.isEmpty {
            educationService.loadInitialData()
        }
    }

    private func refreshData() async {
        educationService.loadInitialData()
    }
}

extension EducationView {

    var headerSection: some View {
        VStack(spacing: 20) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WildSafe Academy")
                        .font(.appTitle)
                        .foregroundColor(.appTextPrimary)

                    Text("Learn. Practice. Stay Safe.")
                        .font(.appSubheadline)
                        .foregroundColor(.appTextSecondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: { showSearch.toggle() }) {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                            .foregroundColor(.appTextSecondary)
                            .padding(10)
                            .background(Color.appCard.opacity(0.7))
                            .clipShape(Circle())
                    }

                    Button(action: { showStats = true }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.title3)
                            .foregroundColor(.appTextSecondary)
                            .padding(10)
                            .background(Color.appCard.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
            }

            HStack(spacing: 20) {

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Level \(educationService.userProgress.currentLevel)")
                            .font(.appSubheadline.bold())
                            .foregroundColor(.appTextPrimary)

                        Text("\(educationService.userProgress.totalXP) XP")
                            .font(.appSmall)
                            .foregroundColor(.appTextSecondary)
                    }

                    ProgressView(value: educationService.userProgress.levelProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .appPrimary))
                        .frame(width: 60)
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.appCard.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.appPrimary)
                                .font(.caption)
                            Text("\(educationService.userProgress.currentStreak)")
                                .font(.appSubheadline.bold())
                                .foregroundColor(.appTextPrimary)
                        }

                        Text("\(Int(educationService.userProgress.studyTimeToday / 60))min today")
                            .font(.appSmall)
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.appCard.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.top, 20)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : -20)
        .animation(.easeOut(duration: 0.6), value: animateCards)
    }

    func todaysLessonCard(lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Continue Learning")
                    .font(.appHeadline)
                    .foregroundColor(.appTextPrimary)

                Spacer()

                Image(systemName: "book.fill")
                    .foregroundColor(.appPrimary)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(lesson.title)
                    .font(.appSubheadline.bold())
                    .foregroundColor(.appTextPrimary)

                if let firstSection = lesson.content.sections.first {
                    Text(String(firstSection.content.prefix(120)) + "...")
                        .font(.appBody)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(3)
                }

                HStack {
                    Label(lesson.formattedReadingTime, systemImage: "clock")
                        .font(.appSmall)
                        .foregroundColor(.appTextTertiary)

                    Spacer()

                    if lesson.isCompleted {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .font(.appSmall)
                            .foregroundColor(.appSuccess)
                    }
                }

                Button(action: {
                    selectedLesson = lesson
                }) {
                    HStack {
                        Text(lesson.isCompleted ? "Review Lesson" : "Start Learning")
                        Image(systemName: "arrow.right")
                    }
                    .font(.appCaption.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .appButtonPrimary()
                }
            }
        }
        .padding(20)
        .appCardStyle()
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateCards)
    }

    var moduleGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Learning Modules")
                    .font(.appHeadline)
                    .foregroundColor(.appTextPrimary)

                Spacer()

                Text("\(filteredModules.count) modules")
                    .font(.appCaption)
                    .foregroundColor(.appTextTertiary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Array(filteredModules.enumerated()), id: \.element.id) { index, module in
                    moduleCard(module)
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 30)
                        .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1 + 0.3), value: animateCards)
                }
            }

            if filteredModules.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No modules found",
                    message: "Try adjusting your search or filters"
                )
                .padding(.vertical, 40)
            }
        }
    }

    func moduleCard(_ module: LearningModule) -> some View {
        Button(action: {
            if module.isUnlocked {
                selectedModule = module
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {

                    Image(systemName: module.iconName)
                        .font(.title2)
                        .foregroundColor(module.colorScheme.colors.primary)
                        .frame(width: 32, height: 32)
                        .background(module.colorScheme.colors.primary.opacity(0.1))
                        .clipShape(Circle())

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if module.isUnlocked {
                            Text(module.formattedDuration)
                                .font(.appSmall)
                                .foregroundColor(.appTextTertiary)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.appTextTertiary)
                        }

                        DifficultyBadge(difficulty: module.difficulty)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(module.title)
                        .font(.appSubheadline.bold())
                        .foregroundColor(module.isUnlocked ? .appTextPrimary : .appTextTertiary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)

                    Text(module.description)
                        .font(.appCaption)
                        .foregroundColor(module.isUnlocked ? .appTextSecondary : .appTextTertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                VStack(spacing: 6) {
                    HStack {
                        Text("\(Int(module.progress * 100))% complete")
                            .font(.appSmall)
                            .foregroundColor(.appTextTertiary)

                        Spacer()

                        if module.isCompleted, let badge = module.badge {
                            Text(badge)
                                .font(.appSmall)
                                .foregroundColor(.appPrimary)
                                .lineLimit(1)
                        }
                    }

                    ProgressView(value: module.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: module.colorScheme.colors.primary))
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        .opacity(module.isUnlocked ? 1 : 0.3)
                }
            }
            .padding(16)
            .frame(height: 160)
            .appCardStyle()
            .opacity(module.isUnlocked ? 1 : 0.6)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(module.isCompleted ? Color.appSuccess : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!module.isUnlocked)
    }

    var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                quickActionButton(
                    title: "Flashcards",
                    subtitle: "\(flashcardsForReview.count) due",
                    icon: "rectangle.stack.fill",
                    color: .appPrimary,
                    action: { showFlashcards = true }
                )

                quickActionButton(
                    title: "Statistics",
                    subtitle: "View progress",
                    icon: "chart.bar.fill",
                    color: .appSecondary,
                    action: { showStats = true }
                )

                quickActionButton(
                    title: "Achievements",
                    subtitle: "\(educationService.userProgress.achievements.count) earned",
                    icon: "trophy.fill",
                    color: .appWarning,
                    action: {  }
                )
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.5), value: animateCards)
    }

    func quickActionButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(height: 24)

                VStack(spacing: 2) {
                    Text(title)
                        .font(.appCaption.bold())
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.appSmall)
                        .foregroundColor(.appTextTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .appCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.appTextTertiary)
                    .font(.title3)

                TextField("Search modules and lessons...", text: $searchText)
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                    .textFieldStyle(PlainTextFieldStyle())

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.appTextTertiary)
                    }
                }
            }
            .padding(16)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .transition(.opacity.combined(with: .scale))
    }

    private var flashcardReviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Flashcard Review")
                    .font(.appHeadline)
                    .foregroundColor(.appTextPrimary)

                Spacer()

                Image(systemName: "rectangle.stack.fill")
                    .foregroundColor(.appSecondary)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("\(flashcardsForReview.count) cards ready for review")
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)

                Button(action: { showFlashcards = true }) {
                    HStack {
                        Text("Start Review")
                        Image(systemName: "arrow.right")
                    }
                    .font(.appCaption.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.appSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(20)
        .appCardStyle()
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.25), value: animateCards)
    }
}

struct StreakIndicator: View {
    let streak: Int
    let longestStreak: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundColor(.appPrimary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak)")
                    .font(.title2.bold())
                    .foregroundColor(.appTextPrimary)
                Text("day streak")
                    .font(.caption2)
                    .foregroundColor(.appTextSecondary)
            }

            if longestStreak > streak {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(longestStreak)")
                        .font(.appCaption.bold())
                        .foregroundColor(.appTextTertiary)
                    Text("best")
                        .font(.caption2)
                        .foregroundColor(.appTextTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .appCardStyle()
    }
}

struct LevelIndicator: View {
    let level: Int
    let xp: Int
    let progress: Double

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Level \(level)")
                .font(.appCaption.bold())
                .foregroundColor(.appTextPrimary)

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .appSecondary))
                .frame(width: 60)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)

            Text("\(xp) XP")
                .font(.caption2)
                .foregroundColor(.appTextTertiary)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.appTextTertiary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.appHeadline)
                    .foregroundColor(.appTextSecondary)

                Text(message)
                    .font(.appBody)
                    .foregroundColor(.appTextTertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct ModuleDetailView: View {
    let module: LearningModule
    @State private var selectedLesson: Lesson?
    @State private var showQuiz = false
    @State private var showFlashcards = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appGradientBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        progressSection
                        lessonsSection
                        if module.quiz != nil {
                            quizSection
                        }
                        if let flashcards = module.flashcards, !flashcards.isEmpty {
                            flashcardsSection
                        }
                        resourcesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(module.title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $selectedLesson) { lesson in
            LessonDetailView(lesson: lesson, module: module)
        }
        .sheet(isPresented: $showQuiz) {
            if let quiz = module.quiz {
                QuizView(quiz: quiz, module: module)
            }
        }
        .sheet(isPresented: $showFlashcards) {
            if let flashcards = module.flashcards {
                FlashcardView()
            }
        }
    }

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: module.iconName)
                    .font(.title)
                    .foregroundColor(module.colorScheme.colors.primary)
                    .frame(width: 48, height: 48)
                    .background(module.colorScheme.colors.primary.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(module.title)
                        .font(.appTitle)
                        .foregroundColor(.appTextPrimary)

                    HStack {
                        DifficultyBadge(difficulty: module.difficulty)
                        Text("•")
                            .foregroundColor(.appTextTertiary)
                        Text(module.formattedDuration)
                            .font(.appCaption)
                            .foregroundColor(.appTextTertiary)
                    }
                }

                Spacer()
            }

            Text(module.description)
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .appCardStyle()
    }

    var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.appHeadline)
                    .foregroundColor(.appTextPrimary)

                Spacer()

                Text("\(Int(module.progress * 100))% Complete")
                    .font(.appCaption)
                    .foregroundColor(.appTextTertiary)
            }

            ProgressView(value: module.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: module.colorScheme.colors.primary))
                .scaleEffect(x: 1, y: 2, anchor: .center)

            if module.isCompleted, let badge = module.badge {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.appSuccess)
                    Text(badge)
                        .font(.appCaption.bold())
                        .foregroundColor(.appSuccess)
                }
            }
        }
        .padding(20)
        .appCardStyle()
    }

    var lessonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Lessons")
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)

            ForEach(Array(module.lessons.enumerated()), id: \.element.id) { index, lesson in
                lessonCard(lesson, index: index + 1)
            }
        }
    }

    func lessonCard(_ lesson: Lesson, index: Int) -> some View {
        Button(action: {
            selectedLesson = lesson
        }) {
            HStack(spacing: 16) {

                Text("\(index)")
                    .font(.appCaption.bold())
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(lesson.isCompleted ? Color.appSuccess : Color.appPrimary)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.appSubheadline.bold())
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.leading)

                    Text(lesson.formattedReadingTime)
                        .font(.appCaption)
                        .foregroundColor(.appTextTertiary)
                }

                Spacer()

                if lesson.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appSuccess)
                        .font(.title3)
                } else {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.appPrimary)
                        .font(.title3)
                }
            }
            .padding(16)
            .appCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }

    var quizSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quiz")
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)

            Button(action: {
                showQuiz = true
            }) {
                HStack(spacing: 16) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.appPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.appPrimary.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(module.quiz?.title ?? "Module Quiz")
                            .font(.appSubheadline.bold())
                            .foregroundColor(.appTextPrimary)

                        Text("\(module.quiz?.questions.count ?? 0) questions")
                            .font(.appCaption)
                            .foregroundColor(.appTextTertiary)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .foregroundColor(.appPrimary)
                }
                .padding(16)
                .appCardStyle()
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    var flashcardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Flashcards")
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)

            Button(action: {
                showFlashcards = true
            }) {
                HStack(spacing: 16) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.title2)
                        .foregroundColor(.appAccent)
                        .frame(width: 40, height: 40)
                        .background(Color.appAccent.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Study Flashcards")
                            .font(.appSubheadline.bold())
                            .foregroundColor(.appTextPrimary)

                        Text("\(module.flashcards?.count ?? 0) cards")
                            .font(.appCaption)
                            .foregroundColor(.appTextTertiary)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .foregroundColor(.appAccent)
                }
                .padding(16)
                .appCardStyle()
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resources")
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)

            ForEach(module.resources, id: \.id) { resource in
                resourceCard(resource)
            }
        }
    }

    func resourceCard(_ resource: Resource) -> some View {
        Button(action: {

            if let urlString = resource.url, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: resource.type.iconName)
                    .font(.title3)
                    .foregroundColor(.appSecondary)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.title)
                        .font(.appCaption.bold())
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.leading)

                    Text(resource.description)
                        .font(.appSmall)
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.appTextTertiary)
            }
            .padding(12)
            .background(Color.appCard.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatisticsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Statistics")
                    .font(.appTitle)
                    .foregroundColor(.appTextPrimary)
                Text("Coming soon...")
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct EducationSettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Education Settings")
                    .font(.appTitle)
                    .foregroundColor(.appTextPrimary)
                Text("Coming soon...")
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct EducationView_Previews: PreviewProvider {
    static var previews: some View {
        EducationView()
    }
}
