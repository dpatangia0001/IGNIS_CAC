import SwiftUI
import Foundation
import Combine

@MainActor
class EducationService: ObservableObject {
    static let shared = EducationService()

    @Published var modules: [LearningModule] = []
    @Published var userProgress: UserProgress = UserProgress()
    @Published var currentModule: LearningModule?
    @Published var currentLesson: Lesson?
    @Published var flashcards: [Flashcard] = []
    @Published var isLoading = false
    @Published var error: EducationError?

    let persistenceService: EducationPersistenceService
    private let analyticsService: EducationAnalyticsService
    private let notificationService: EducationNotificationService
    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.persistenceService = EducationPersistenceService()
        self.analyticsService = EducationAnalyticsService()
        self.notificationService = EducationNotificationService()

        setupBindings()
        loadInitialData()
    }

    private func setupBindings() {

        $userProgress
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] progress in
                self?.persistenceService.saveUserProgress(progress)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.updateDailyStreak()
            }
            .store(in: &cancellables)
    }

    func loadInitialData() {
        isLoading = true

        Task {
            do {

                userProgress = try await persistenceService.loadUserProgress()

                modules = try await loadModules()

                flashcards = try await loadFlashcards()

                updateUnlockedModules()

                isLoading = false
            } catch {
                self.error = EducationError.dataLoadingFailed(error.localizedDescription)
                isLoading = false
            }
        }
    }

    private func loadModules() async throws -> [LearningModule] {

        return SampleEducationData.allModules
    }

    private func loadFlashcards() async throws -> [Flashcard] {
        return SampleEducationData.allFlashcards
    }

    func startModule(_ module: LearningModule) {
        guard module.isUnlocked else {
            error = .moduleNotUnlocked
            return
        }

        currentModule = module
        analyticsService.trackModuleStarted(module.id)

        var updatedModule = module
        updatedModule.lastAccessedDate = Date()
        updateModule(updatedModule)
    }

    func completeLesson(_ lesson: Lesson, timeSpent: TimeInterval) {
        guard let moduleIndex = modules.firstIndex(where: { $0.id == lesson.moduleId }) else { return }

        var module = modules[moduleIndex]
        module.completedLessons.insert(lesson.id)

        if let lessonIndex = module.lessons.firstIndex(where: { $0.id == lesson.id }) {
            module.lessons[lessonIndex].isCompleted = true
            module.lessons[lessonIndex].timeSpent += timeSpent
            module.lessons[lessonIndex].lastAccessedDate = Date()
        }

        let xpGained = calculateLessonXP(lesson)
        userProgress.totalXP += xpGained
        userProgress.studyTimeToday += timeSpent
        userProgress.totalStudyTime += timeSpent

        updateModule(module)
        checkForLevelUp()
        checkForAchievements(module: module)

        analyticsService.trackLessonCompleted(lesson.id, timeSpent: timeSpent, xpGained: xpGained)
    }

    func submitQuizAttempt(_ attempt: QuizAttempt) {
        guard let moduleIndex = modules.firstIndex(where: { $0.quiz?.id == attempt.quizId }) else { return }

        var module = modules[moduleIndex]
        module.quizAttempts.append(attempt)

        let xpGained = calculateQuizXP(attempt)
        userProgress.totalXP += xpGained

        updateModule(module)
        checkForLevelUp()
        checkForAchievements(module: module)

        analyticsService.trackQuizCompleted(attempt.quizId, score: attempt.score, xpGained: xpGained)
    }

    private func updateModule(_ module: LearningModule) {
        if let index = modules.firstIndex(where: { $0.id == module.id }) {
            modules[index] = module
        }

        if module.isCompleted && !userProgress.completedModules.contains(module.id) {
            userProgress.completedModules.insert(module.id)
            updateUnlockedModules()

            notificationService.scheduleModuleCompletionNotification(module)
        }
    }

    private func updateUnlockedModules() {
        for i in 0..<modules.count {
            let module = modules[i]
            let prerequisitesMet = module.prerequisites.allSatisfy { prerequisiteId in
                userProgress.completedModules.contains(prerequisiteId)
            }

            if prerequisitesMet && !modules[i].isUnlocked {
                modules[i].isUnlocked = true
                userProgress.unlockedModules.insert(module.id)

                notificationService.scheduleModuleUnlockedNotification(module)
            }
        }
    }

    private func calculateLessonXP(_ lesson: Lesson) -> Int {
        let baseXP = 10
        let timeBonus = Int(lesson.estimatedDuration / 60) * 2
        return baseXP + timeBonus
    }

    private func calculateQuizXP(_ attempt: QuizAttempt) -> Int {
        let baseXP = 25
        let scoreBonus = Int(attempt.score * 50)
        return baseXP + scoreBonus
    }

    private func checkForLevelUp() {
        let newLevel = (userProgress.totalXP / 100) + 1
        if newLevel > userProgress.currentLevel {
            let oldLevel = userProgress.currentLevel
            userProgress.currentLevel = newLevel

            let achievement = Achievement(
                id: UUID(),
                title: "Level \(newLevel) Reached!",
                description: "You've advanced to level \(newLevel)",
                iconName: "star.fill",
                unlockedDate: Date(),
                category: .completion
            )
            userProgress.achievements.append(achievement)

            notificationService.scheduleLevelUpNotification(oldLevel: oldLevel, newLevel: newLevel)
            analyticsService.trackLevelUp(newLevel)
        }
    }

    private func checkForAchievements(module: LearningModule) {

        checkStreakAchievements()
        checkCompletionAchievements()
        checkMasteryAchievements(module: module)
    }

    private func checkStreakAchievements() {
        let streakMilestones = [7, 14, 30, 60, 100]
        for milestone in streakMilestones {
            if userProgress.currentStreak == milestone {
                let achievement = Achievement(
                    id: UUID(),
                    title: "\(milestone)-Day Streak!",
                    description: "You've studied for \(milestone) consecutive days",
                    iconName: "flame.fill",
                    unlockedDate: Date(),
                    category: .streak
                )
                userProgress.achievements.append(achievement)
                break
            }
        }
    }

    private func checkCompletionAchievements() {
        let completedCount = userProgress.completedModules.count
        let totalModules = modules.count

        if completedCount == totalModules && completedCount > 0 {
            let achievement = Achievement(
                id: UUID(),
                title: "Fire Safety Master",
                description: "Completed all available modules",
                iconName: "crown.fill",
                unlockedDate: Date(),
                category: .mastery
            )
            userProgress.achievements.append(achievement)
        }
    }

    private func checkMasteryAchievements(module: LearningModule) {

        if let quiz = module.quiz,
           let bestAttempt = module.quizAttempts.max(by: { $0.score < $1.score }),
           bestAttempt.score >= 0.95 {

            let achievement = Achievement(
                id: UUID(),
                title: "Perfect Score",
                description: "Achieved 95%+ on \(module.title) quiz",
                iconName: "checkmark.seal.fill",
                unlockedDate: Date(),
                category: .mastery
            )
            userProgress.achievements.append(achievement)
        }
    }

    private func updateDailyStreak() {
        let calendar = Calendar.current
        let today = Date()

        if let lastStudyDate = userProgress.lastStudyDate {
            if calendar.isDate(lastStudyDate, inSameDayAs: today) {

                return
            } else if calendar.isDate(lastStudyDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)!) {

                userProgress.currentStreak += 1
                userProgress.longestStreak = max(userProgress.longestStreak, userProgress.currentStreak)
            } else {

                userProgress.currentStreak = 0
            }
        }

        userProgress.studyTimeToday = 0
    }

    func getFlashcardsForReview() -> [Flashcard] {
        return flashcards.filter { $0.nextReviewDate <= Date() && !$0.isLearned }
    }

    func reviewFlashcard(_ flashcard: Flashcard, difficulty: FlashcardDifficulty) {
        guard let index = flashcards.firstIndex(where: { $0.id == flashcard.id }) else { return }

        var updatedCard = flashcard
        updatedCard = updateFlashcardSpacedRepetition(updatedCard, difficulty: difficulty)
        flashcards[index] = updatedCard

        analyticsService.trackFlashcardReviewed(flashcard.id, difficulty: difficulty)
    }

    private func updateFlashcardSpacedRepetition(_ card: Flashcard, difficulty: FlashcardDifficulty) -> Flashcard {
        var updatedCard = card

        switch difficulty {
        case .again:
            updatedCard.repetitions = 0
            updatedCard.interval = 1
            updatedCard.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        case .hard:
            updatedCard.easeFactor = max(1.3, updatedCard.easeFactor - 0.15)
            updatedCard.repetitions += 1
            updatedCard.interval = max(1, Int(Double(updatedCard.interval) * updatedCard.easeFactor * 0.8))
            updatedCard.nextReviewDate = Calendar.current.date(byAdding: .day, value: updatedCard.interval, to: Date()) ?? Date()

        case .good:
            updatedCard.repetitions += 1
            if updatedCard.repetitions <= 2 {
                updatedCard.interval = updatedCard.repetitions == 1 ? 1 : 6
            } else {
                updatedCard.interval = Int(Double(updatedCard.interval) * updatedCard.easeFactor)
            }
            updatedCard.nextReviewDate = Calendar.current.date(byAdding: .day, value: updatedCard.interval, to: Date()) ?? Date()

        case .easy:
            updatedCard.easeFactor += 0.15
            updatedCard.repetitions += 1
            updatedCard.interval = Int(Double(updatedCard.interval) * updatedCard.easeFactor * 1.3)
            updatedCard.nextReviewDate = Calendar.current.date(byAdding: .day, value: updatedCard.interval, to: Date()) ?? Date()
        }

        if updatedCard.interval > 100 {
            updatedCard.isLearned = true
        }

        return updatedCard
    }

    func toggleBookmark(lessonId: UUID, moduleId: UUID) {
        guard let moduleIndex = modules.firstIndex(where: { $0.id == moduleId }) else { return }

        var module = modules[moduleIndex]
        if module.bookmarkedLessons.contains(lessonId) {
            module.bookmarkedLessons.remove(lessonId)
        } else {
            module.bookmarkedLessons.insert(lessonId)
        }

        updateModule(module)
    }

    func updateLessonNotes(lessonId: UUID, moduleId: UUID, notes: String) {
        guard let moduleIndex = modules.firstIndex(where: { $0.id == moduleId }),
              let lessonIndex = modules[moduleIndex].lessons.firstIndex(where: { $0.id == lessonId }) else { return }

        modules[moduleIndex].lessons[lessonIndex].userNotes = notes
        persistenceService.saveLessonNotes(lessonId: lessonId, notes: notes)
    }

    func searchModules(query: String) -> [LearningModule] {
        guard !query.isEmpty else { return modules }

        return modules.filter { module in
            module.title.localizedCaseInsensitiveContains(query) ||
            module.description.localizedCaseInsensitiveContains(query) ||
            module.lessons.contains { lesson in
                lesson.title.localizedCaseInsensitiveContains(query)
            }
        }
    }

    func filterModules(by category: ModuleCategory? = nil, difficulty: DifficultyLevel? = nil, completed: Bool? = nil) -> [LearningModule] {
        return modules.filter { module in
            if let category = category, module.category != category { return false }
            if let difficulty = difficulty, module.difficulty != difficulty { return false }
            if let completed = completed, module.isCompleted != completed { return false }
            return true
        }
    }

    func getStudyStatistics() -> StudyStatistics {
        let totalLessons = modules.flatMap { $0.lessons }.count
        let completedLessons = modules.flatMap { $0.completedLessons }.count
        let averageScore = modules.compactMap { $0.quiz?.bestScore }.reduce(0, +) / Double(max(1, modules.count))

        return StudyStatistics(
            totalModules: modules.count,
            completedModules: userProgress.completedModules.count,
            totalLessons: totalLessons,
            completedLessons: completedLessons,
            totalStudyTime: userProgress.totalStudyTime,
            currentStreak: userProgress.currentStreak,
            averageQuizScore: averageScore,
            totalAchievements: userProgress.achievements.count
        )
    }
}

class EducationPersistenceService {
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default

    func saveUserProgress(_ progress: UserProgress) {
        if let encoded = try? JSONEncoder().encode(progress) {
            userDefaults.set(encoded, forKey: "UserProgress")
        }
    }

    func loadUserProgress() async throws -> UserProgress {
        guard let data = userDefaults.data(forKey: "UserProgress"),
              let progress = try? JSONDecoder().decode(UserProgress.self, from: data) else {
            return UserProgress()
        }
        return progress
    }

    func saveLessonNotes(lessonId: UUID, notes: String) {
        userDefaults.set(notes, forKey: "LessonNotes_\(lessonId)")
    }

    func loadLessonNotes(lessonId: UUID) -> String {
        return userDefaults.string(forKey: "LessonNotes_\(lessonId)") ?? ""
    }
}

class EducationAnalyticsService {
    func trackModuleStarted(_ moduleId: UUID) {

        print("📊 Module started: \(moduleId)")
    }

    func trackLessonCompleted(_ lessonId: UUID, timeSpent: TimeInterval, xpGained: Int) {
        print("📊 Lesson completed: \(lessonId), time: \(timeSpent)s, XP: \(xpGained)")
    }

    func trackQuizCompleted(_ quizId: UUID, score: Double, xpGained: Int) {
        print("📊 Quiz completed: \(quizId), score: \(score), XP: \(xpGained)")
    }

    func trackFlashcardReviewed(_ cardId: UUID, difficulty: FlashcardDifficulty) {
        print("📊 Flashcard reviewed: \(cardId), difficulty: \(difficulty)")
    }

    func trackLevelUp(_ newLevel: Int) {
        print("📊 Level up: \(newLevel)")
    }
}

class EducationNotificationService {
    func scheduleModuleCompletionNotification(_ module: LearningModule) {

        print("🔔 Module completed: \(module.title)")
    }

    func scheduleModuleUnlockedNotification(_ module: LearningModule) {
        print("🔔 Module unlocked: \(module.title)")
    }

    func scheduleLevelUpNotification(oldLevel: Int, newLevel: Int) {
        print("🔔 Level up: \(oldLevel) → \(newLevel)")
    }

    func scheduleStudyReminder() {

        print("🔔 Time to study!")
    }
}

enum EducationError: LocalizedError {
    case dataLoadingFailed(String)
    case moduleNotUnlocked
    case quizNotAvailable
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .dataLoadingFailed(let message):
            return "Failed to load education data: \(message)"
        case .moduleNotUnlocked:
            return "This module is not yet unlocked. Complete prerequisite modules first."
        case .quizNotAvailable:
            return "Quiz is not available for this module."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

enum FlashcardDifficulty: String, CaseIterable {
    case again = "Again"
    case hard = "Hard"
    case good = "Good"
    case easy = "Easy"

    var color: Color {
        switch self {
        case .again: return .appError
        case .hard: return .appWarning
        case .good: return .appSuccess
        case .easy: return .appInfo
        }
    }
}

struct StudyStatistics {
    let totalModules: Int
    let completedModules: Int
    let totalLessons: Int
    let completedLessons: Int
    let totalStudyTime: TimeInterval
    let currentStreak: Int
    let averageQuizScore: Double
    let totalAchievements: Int

    var moduleCompletionRate: Double {
        guard totalModules > 0 else { return 0 }
        return Double(completedModules) / Double(totalModules)
    }

    var lessonCompletionRate: Double {
        guard totalLessons > 0 else { return 0 }
        return Double(completedLessons) / Double(totalLessons)
    }
}

struct SampleEducationData {
    static let allModules: [LearningModule] = [
        createWildfireBasicsModule(),
        createHomeSafetyModule(),
        createEmergencyPlanningModule(),
        createFireBehaviorModule()
    ]

    static let allFlashcards: [Flashcard] = createSampleFlashcards()

    private static func createWildfireBasicsModule() -> LearningModule {
        LearningModule(
            id: UUID(),
            title: "Wildfire Basics",
            description: "Understanding fire behavior, causes, and basic safety principles",
            category: .basics,
            difficulty: .beginner,
            estimatedDuration: 900,
            iconName: "flame.fill",
            colorScheme: .primary,
            prerequisites: [],
            lessons: createBasicsLessons(),
            quiz: createBasicsQuiz(),
            flashcards: createBasicsFlashcards(),
            resources: createBasicsResources(),
            isUnlocked: true,
            completedLessons: [],
            quizAttempts: [],
            lastAccessedDate: nil,
            bookmarkedLessons: []
        )
    }

    private static func createBasicsLessons() -> [Lesson] {
        [
            Lesson(
                id: UUID(),
                moduleId: UUID(),
                title: "What Are Wildfires?",
                content: LessonContent(sections: [
                    ContentSection(
                        id: UUID(),
                        type: .text,
                        title: "Definition",
                        content: "A wildfire is an uncontrolled fire that spreads rapidly through vegetation...",
                        mediaURL: nil
                    )
                ]),
                estimatedDuration: 300,
                isCompleted: false,
                lastAccessedDate: nil,
                userNotes: ""
            )
        ]
    }

    private static func createBasicsQuiz() -> Quiz {
        Quiz(
            id: UUID(),
            moduleId: UUID(),
            title: "Wildfire Basics Quiz",
            description: "Test your understanding of wildfire fundamentals",
            questions: [
                QuizQuestion(
                    id: UUID(),
                    question: "What percentage of wildfires are caused by human activities?",
                    type: .multipleChoice,
                    options: ["50%", "75%", "90%", "95%"],
                    correctAnswers: [2],
                    explanation: "According to the National Park Service, human activities cause about 90% of wildfires.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "What are the three elements needed for fire to exist (the fire triangle)?",
                    type: .multipleSelect,
                    options: ["Heat", "Fuel", "Oxygen", "Wind", "Dryness", "Spark"],
                    correctAnswers: [0, 1, 2],
                    explanation: "The fire triangle consists of Heat, Fuel, and Oxygen. Remove any one element and the fire cannot continue.",
                    points: 15,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Lightning causes more wildfires than human activities.",
                    type: .trueFalse,
                    options: ["True", "False"],
                    correctAnswers: [1],
                    explanation: "False. While lightning does cause wildfires, human activities account for about 90% of all wildfires.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Which weather conditions increase wildfire risk?",
                    type: .multipleSelect,
                    options: ["High humidity", "Strong winds", "Low humidity", "High temperatures", "Recent rainfall", "Drought conditions"],
                    correctAnswers: [1, 2, 3, 5],
                    explanation: "Strong winds, low humidity, high temperatures, and drought conditions all increase wildfire risk by creating dry conditions and helping fires spread.",
                    points: 15,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "What is the best time of year for wildfires in most regions?",
                    type: .multipleChoice,
                    options: ["Spring", "Summer", "Fall", "Winter"],
                    correctAnswers: [2],
                    explanation: "Fall is typically the most dangerous time for wildfires due to dry conditions, low humidity, and strong seasonal winds.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Which human activities commonly cause wildfires?",
                    type: .multipleSelect,
                    options: ["Campfires", "Cigarettes", "Power lines", "Vehicle exhaust", "Fireworks", "Controlled burns"],
                    correctAnswers: [0, 1, 2, 3, 4],
                    explanation: "All of these except controlled burns are common causes. Controlled burns are intentional and managed by professionals.",
                    points: 20,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Wildfires only burn trees and grass.",
                    type: .trueFalse,
                    options: ["True", "False"],
                    correctAnswers: [1],
                    explanation: "False. Wildfires can burn homes, structures, vehicles, and any combustible material, not just vegetation.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "What does the term 'fire weather' refer to?",
                    type: .multipleChoice,
                    options: ["Weather that causes fires", "Hot summer weather", "Weather conditions that promote fire spread", "Weather during fire season"],
                    correctAnswers: [2],
                    explanation: "Fire weather refers to specific atmospheric conditions like low humidity, high temperatures, and strong winds that promote rapid fire spread.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Which type of vegetation burns most easily?",
                    type: .multipleChoice,
                    options: ["Green, healthy plants", "Dead, dry vegetation", "Recently watered plants", "Thick tree bark"],
                    correctAnswers: [1],
                    explanation: "Dead, dry vegetation acts as kindling and burns much more easily than living, moisture-rich plants.",
                    points: 10,
                    mediaURL: nil
                )
            ],
            timeLimit: 900,
            passingScore: 0.7,
            maxAttempts: 3
        )
    }

    private static func createBasicsResources() -> [Resource] {
        [
            Resource(
                id: UUID(),
                title: "Wildfire Safety Checklist",
                description: "Essential preparation steps",
                type: .checklist,
                url: nil
            )
        ]
    }

    private static func createHomeSafetyModule() -> LearningModule {
        LearningModule(
            id: UUID(),
            title: "Home Safety & Defensible Space",
            description: "Protect your home with proper landscaping, materials, and maintenance practices",
            category: .prevention,
            difficulty: .intermediate,
            estimatedDuration: 1200,
            iconName: "house.fill",
            colorScheme: .secondary,
            prerequisites: [],
            lessons: createHomeSafetyLessons(),
            quiz: createHomeSafetyQuiz(),
            flashcards: createHomeSafetyFlashcards(),
            resources: createHomeSafetyResources(),
            isUnlocked: true,
            completedLessons: [],
            quizAttempts: [],
            lastAccessedDate: nil,
            bookmarkedLessons: []
        )
    }

    private static func createEmergencyPlanningModule() -> LearningModule {
        LearningModule(
            id: UUID(),
            title: "Emergency Planning",
            description: "Create evacuation plans, emergency kits, and communication strategies",
            category: .emergency,
            difficulty: .intermediate,
            estimatedDuration: 1500,
            iconName: "exclamationmark.triangle.fill",
            colorScheme: .warning,
            prerequisites: [],
            lessons: createEmergencyPlanningLessons(),
            quiz: createEmergencyPlanningQuiz(),
            flashcards: createEmergencyPlanningFlashcards(),
            resources: createEmergencyPlanningResources(),
            isUnlocked: true,
            completedLessons: [],
            quizAttempts: [],
            lastAccessedDate: nil,
            bookmarkedLessons: []
        )
    }

    private static func createFireBehaviorModule() -> LearningModule {
        LearningModule(
            id: UUID(),
            title: "Fire Behavior & Science",
            description: "Advanced understanding of fire dynamics, weather, and terrain effects",
            category: .advanced,
            difficulty: .advanced,
            estimatedDuration: 1800,
            iconName: "wind",
            colorScheme: .error,
            prerequisites: [],
            lessons: createFireBehaviorLessons(),
            quiz: createFireBehaviorQuiz(),
            flashcards: createFireBehaviorFlashcards(),
            resources: createFireBehaviorResources(),
            isUnlocked: true,
            completedLessons: [],
            quizAttempts: [],
            lastAccessedDate: nil,
            bookmarkedLessons: []
        )
    }

    private static func createSampleFlashcards() -> [Flashcard] {
        [
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What is the 'fire triangle'?",
                back: "Heat, Fuel, and Oxygen - the three elements needed for fire to exist",
                difficulty: .beginner,
                tags: ["fire-science", "basics"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What percentage of wildfires are caused by humans?",
                back: "Approximately 90% of wildfires are caused by human activities",
                difficulty: .beginner,
                tags: ["statistics", "causes"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What is defensible space?",
                back: "A buffer zone around structures where vegetation is managed to reduce fire risk, typically 30-100 feet",
                difficulty: .intermediate,
                tags: ["prevention", "defensible-space"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What are the three zones of defensible space?",
                back: "Zone 1 (0-30ft): Lean, clean, green. Zone 2 (30-100ft): Reduced fuel. Zone 3 (100-200ft): Thinned vegetation",
                difficulty: .intermediate,
                tags: ["defensible-space", "zones"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What does 'RED FLAG WARNING' mean?",
                back: "Critical fire weather conditions with low humidity, high winds, and high temperatures",
                difficulty: .beginner,
                tags: ["weather", "warnings"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What is the best roofing material for fire resistance?",
                back: "Class A fire-rated materials like metal, tile, or treated wood shingles",
                difficulty: .intermediate,
                tags: ["home-hardening", "materials"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "How far should propane tanks be from structures?",
                back: "At least 30 feet away from any structure or combustible material",
                difficulty: .intermediate,
                tags: ["safety", "propane"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What is the 'Ready, Set, Go!' program?",
                back: "Ready: Prepare your property. Set: Stay aware and prepared. Go: Leave early when threatened",
                difficulty: .beginner,
                tags: ["evacuation", "program"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What wind speed increases fire danger significantly?",
                back: "Winds over 25 mph greatly increase fire spread rate and intensity",
                difficulty: .intermediate,
                tags: ["weather", "wind"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What humidity level is considered critical for fire weather?",
                back: "Relative humidity below 15% creates critical fire weather conditions",
                difficulty: .advanced,
                tags: ["weather", "humidity"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What is a 'fire break'?",
                back: "A strip of land cleared of flammable vegetation to stop or slow fire spread",
                difficulty: .intermediate,
                tags: ["prevention", "firebreak"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What should you do if caught in a wildfire while driving?",
                back: "Stay in vehicle, close windows/vents, turn on headlights, call 911, lie on floor if possible",
                difficulty: .advanced,
                tags: ["emergency", "driving"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What are 'embers' and why are they dangerous?",
                back: "Burning pieces of debris that can travel over a mile ahead of fires and start new fires",
                difficulty: .intermediate,
                tags: ["fire-behavior", "embers"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What is the most important factor in home survival during wildfire?",
                back: "Defensible space - properly maintained vegetation management around the home",
                difficulty: .intermediate,
                tags: ["home-survival", "defensible-space"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "When should you evacuate during a wildfire?",
                back: "As soon as possible when advised, don't wait for mandatory orders. Leave early!",
                difficulty: .beginner,
                tags: ["evacuation", "timing"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What are the signs of approaching wildfire?",
                back: "Smoke, falling ash, strong smell of smoke, red/orange glow on horizon, loud roaring sound",
                difficulty: .beginner,
                tags: ["warning-signs", "detection"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What is 'crown fire'?",
                back: "Fire that spreads through tree crowns/canopy, most dangerous and fastest-spreading type",
                difficulty: .advanced,
                tags: ["fire-behavior", "crown-fire"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What items should be in a wildfire emergency kit?",
                back: "Water, food, medications, important documents, flashlight, radio, first aid, N95 masks",
                difficulty: .intermediate,
                tags: ["emergency-kit", "preparation"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "How often should you clean gutters for fire safety?",
                back: "At least twice a year, and immediately before fire season to remove flammable debris",
                difficulty: .intermediate,
                tags: ["maintenance", "gutters"]
            ),
            Flashcard(
                id: UUID(),
                moduleId: UUID(),
                front: "What is the safest way to dispose of fireplace ashes?",
                back: "Store in metal container with tight lid, away from combustibles, soak with water, wait 72 hours",
                difficulty: .intermediate,
                tags: ["safety", "ash-disposal"]
            )
        ]
    }

    private static func createHomeSafetyLessons() -> [Lesson] {
        [
            Lesson(
                id: UUID(),
                moduleId: UUID(),
                title: "Defensible Space Zones",
                content: LessonContent(sections: [
                    ContentSection(
                        id: UUID(),
                        type: .text,
                        title: "Zone 1: Immediate Zone (0-5 feet)",
                        content: "This is the most critical area around your home. Remove all flammable vegetation and materials. Use hardscaping like gravel, stone, or concrete. Keep this zone 'lean, clean, and green' with well-watered, low-growing plants.",
                        mediaURL: nil
                    ),
                    ContentSection(
                        id: UUID(),
                        type: .text,
                        title: "Zone 2: Intermediate Zone (5-30 feet)",
                        content: "Create horizontal and vertical spacing between plants. Remove ladder fuels that could carry fire from ground to tree crowns. Maintain healthy, green vegetation with regular watering and pruning.",
                        mediaURL: nil
                    ),
                    ContentSection(
                        id: UUID(),
                        type: .checklist,
                        title: "Zone Maintenance Checklist",
                        content: "Zone 1: Remove dead vegetation weekly|Keep gutters clean|Store firewood 30+ feet away|Zone 2: Prune trees 6-10 feet from ground|Create fuel breaks with driveways/paths|Remove dead branches and leaves",
                        mediaURL: nil
                    )
                ]),
                estimatedDuration: 600,
                isCompleted: false,
                userNotes: ""
            ),
            Lesson(
                id: UUID(),
                moduleId: UUID(),
                title: "Fire-Resistant Building Materials",
                content: LessonContent(sections: [
                    ContentSection(
                        id: UUID(),
                        type: .text,
                        title: "Roofing Materials",
                        content: "Class A fire-rated roofing materials include metal, tile, slate, and treated wood shingles. Avoid wood shake roofs which are highly flammable. Regularly clean gutters and roof surfaces of debris.",
                        mediaURL: nil
                    ),
                    ContentSection(
                        id: UUID(),
                        type: .text,
                        title: "Siding and Windows",
                        content: "Use fire-resistant siding materials like stucco, fiber cement, or metal. Install dual-pane windows with tempered glass. Cover vents with fine mesh screens to prevent ember intrusion.",
                        mediaURL: nil
                    )
                ]),
                estimatedDuration: 480,
                isCompleted: false,
                userNotes: ""
            )
        ]
    }

    private static func createHomeSafetyQuiz() -> Quiz {
        Quiz(
            id: UUID(),
            moduleId: UUID(),
            title: "Home Safety & Defensible Space Quiz",
            description: "Test your knowledge of home hardening and defensible space principles",
            questions: [
                QuizQuestion(
                    id: UUID(),
                    question: "How far should Zone 1 (immediate zone) extend from your home?",
                    type: .multipleChoice,
                    options: ["0-5 feet", "5-30 feet", "30-100 feet", "100+ feet"],
                    correctAnswers: [0],
                    explanation: "Zone 1 extends 0-5 feet from your home and should be kept 'lean, clean, and green' with minimal flammable materials.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Which roofing materials are Class A fire-rated?",
                    type: .multipleSelect,
                    options: ["Metal", "Wood shake", "Tile", "Slate", "Asphalt shingles", "Treated wood shingles"],
                    correctAnswers: [0, 2, 3, 5],
                    explanation: "Class A fire-rated materials include metal, tile, slate, and treated wood shingles. Wood shake roofs are highly flammable.",
                    points: 15,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Ladder fuels should be removed to prevent fire from spreading to tree crowns.",
                    type: .trueFalse,
                    options: ["True", "False"],
                    correctAnswers: [0],
                    explanation: "True. Ladder fuels are vegetation that creates a continuous path for fire to climb from ground level to tree crowns.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "What is the recommended distance for storing firewood from structures?",
                    type: .multipleChoice,
                    options: ["10 feet", "20 feet", "30 feet", "50 feet"],
                    correctAnswers: [2],
                    explanation: "Firewood should be stored at least 30 feet away from structures and other combustible materials.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Which home hardening measures help prevent ember intrusion?",
                    type: .multipleSelect,
                    options: ["Fine mesh screens on vents", "Dual-pane windows", "Metal gutters", "Enclosed eaves", "Weather stripping", "Spark arrestors"],
                    correctAnswers: [0, 1, 3, 4, 5],
                    explanation: "All except metal gutters directly help prevent ember intrusion into homes.",
                    points: 20,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Trees in Zone 2 should be pruned how high from the ground?",
                    type: .multipleChoice,
                    options: ["3-5 feet", "6-10 feet", "10-15 feet", "15-20 feet"],
                    correctAnswers: [1],
                    explanation: "Trees should be pruned 6-10 feet from the ground to remove ladder fuels.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Gutters should be cleaned regularly to remove flammable debris.",
                    type: .trueFalse,
                    options: ["True", "False"],
                    correctAnswers: [0],
                    explanation: "True. Debris in gutters can easily ignite from embers and spread fire to the roof.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "What type of plants are best for Zone 1?",
                    type: .multipleChoice,
                    options: ["Dry, native grasses", "High-moisture, low-growing plants", "Dense shrubs", "Tall ornamental grasses"],
                    correctAnswers: [1],
                    explanation: "High-moisture, low-growing plants are best for Zone 1 as they are less likely to ignite and spread fire.",
                    points: 10,
                    mediaURL: nil
                )
            ],
            timeLimit: 900,
            passingScore: 0.7,
            maxAttempts: 3
        )
    }

    private static func createHomeSafetyResources() -> [Resource] {
        [
            Resource(
                id: UUID(),
                title: "Defensible Space Guidelines",
                description: "Comprehensive guide to creating defensible space around your home",
                type: .pdf,
                url: "https://www.readyforwildfire.org/defensible-space/"
            ),
            Resource(
                id: UUID(),
                title: "Home Hardening Checklist",
                description: "Step-by-step checklist for hardening your home against wildfires",
                type: .checklist,
                url: "https://www.insurance.ca.gov/01-consumers/140-catastrophes/Wildfire-Home-Hardening-Checklist.cfm"
            )
        ]
    }

    private static func createEmergencyPlanningLessons() -> [Lesson] {
        [
            Lesson(
                id: UUID(),
                moduleId: UUID(),
                title: "Creating Your Evacuation Plan",
                content: LessonContent(sections: [
                    ContentSection(
                        id: UUID(),
                        type: .text,
                        title: "Multiple Escape Routes",
                        content: "Identify at least two evacuation routes from your neighborhood. Practice driving these routes at different times of day. Consider alternative routes if main roads become blocked during an emergency.",
                        mediaURL: nil
                    ),
                    ContentSection(
                        id: UUID(),
                        type: .text,
                        title: "Meeting Points",
                        content: "Establish a primary and secondary meeting point outside your neighborhood. Choose locations that are easily accessible and known to all family members. Consider locations like schools, community centers, or relatives' homes.",
                        mediaURL: nil
                    ),
                    ContentSection(
                        id: UUID(),
                        type: .checklist,
                        title: "Evacuation Planning Checklist",
                        content: "Map two escape routes|Identify meeting points|Share plan with neighbors|Practice evacuation with family|Keep vehicle fueled|Prepare go-bags|Register for emergency alerts",
                        mediaURL: nil
                    )
                ]),
                estimatedDuration: 720,
                isCompleted: false,
                userNotes: ""
            ),
            Lesson(
                id: UUID(),
                moduleId: UUID(),
                title: "Emergency Kit Essentials",
                content: LessonContent(sections: [
                    ContentSection(
                        id: UUID(),
                        type: .text,
                        title: "72-Hour Kit Basics",
                        content: "Prepare supplies for at least 72 hours per person: 1 gallon of water per person per day, non-perishable food, flashlights, battery-powered radio, extra batteries, first aid kit, medications.",
                        mediaURL: nil
                    ),
                    ContentSection(
                        id: UUID(),
                        type: .text,
                        title: "Important Documents",
                        content: "Keep copies of important documents in a waterproof container: insurance policies, identification, bank records, medical information, emergency contact list. Consider digital copies stored securely online.",
                        mediaURL: nil
                    )
                ]),
                estimatedDuration: 540,
                isCompleted: false,
                userNotes: ""
            )
        ]
    }

    private static func createEmergencyPlanningQuiz() -> Quiz {
        Quiz(
            id: UUID(),
            moduleId: UUID(),
            title: "Emergency Planning Quiz",
            description: "Test your emergency preparedness knowledge",
            questions: [
                QuizQuestion(
                    id: UUID(),
                    question: "How many evacuation routes should you plan from your neighborhood?",
                    type: .multipleChoice,
                    options: ["One main route", "At least two routes", "Three routes", "As many as possible"],
                    correctAnswers: [1],
                    explanation: "You should plan at least two evacuation routes in case one becomes blocked during an emergency.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "How much water should you store per person per day in your emergency kit?",
                    type: .multipleChoice,
                    options: ["1/2 gallon", "1 gallon", "2 gallons", "3 gallons"],
                    correctAnswers: [1],
                    explanation: "Store 1 gallon of water per person per day for drinking, cooking, and hygiene needs.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Which items should be in your go-bag?",
                    type: .multipleSelect,
                    options: ["Medications", "Change of clothes", "Flashlight", "Important documents", "Cash", "Pet supplies"],
                    correctAnswers: [0, 1, 2, 3, 4, 5],
                    explanation: "All of these items are essential for your go-bag to ensure you're prepared for immediate evacuation.",
                    points: 15,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Emergency kits should be prepared for at least 72 hours.",
                    type: .trueFalse,
                    options: ["True", "False"],
                    correctAnswers: [0],
                    explanation: "True. Emergency kits should contain supplies for at least 72 hours, though longer is better.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "When should you evacuate during a wildfire emergency?",
                    type: .multipleChoice,
                    options: ["When mandatory evacuation is ordered", "When you see flames", "As soon as evacuation warning is issued", "When neighbors start leaving"],
                    correctAnswers: [2],
                    explanation: "Evacuate as soon as an evacuation warning is issued. Don't wait for mandatory orders.",
                    points: 15,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "What should you do with important documents?",
                    type: .multipleSelect,
                    options: ["Keep originals only", "Make copies", "Store in waterproof container", "Keep digital copies", "Share with family members"],
                    correctAnswers: [1, 2, 3, 4],
                    explanation: "Make copies, store in waterproof containers, keep digital copies, and share with family members.",
                    points: 15,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "You should practice your evacuation plan regularly.",
                    type: .trueFalse,
                    options: ["True", "False"],
                    correctAnswers: [0],
                    explanation: "True. Regular practice helps ensure everyone knows what to do during an actual emergency.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Where should you establish meeting points?",
                    type: .multipleChoice,
                    options: ["Inside your neighborhood only", "Outside your neighborhood", "At your workplace", "At the nearest fire station"],
                    correctAnswers: [1],
                    explanation: "Meeting points should be outside your neighborhood in case the entire area needs to be evacuated.",
                    points: 10,
                    mediaURL: nil
                )
            ],
            timeLimit: 900,
            passingScore: 0.7,
            maxAttempts: 3
        )
    }

    private static func createEmergencyPlanningResources() -> [Resource] {
        [
            Resource(
                id: UUID(),
                title: "Ready.gov Emergency Kit Checklist",
                description: "Complete emergency kit preparation checklist from Ready.gov",
                type: .checklist,
                url: "https://www.ready.gov/kit"
            ),
            Resource(
                id: UUID(),
                title: "Family Emergency Plan Template",
                description: "Red Cross family emergency plan template",
                type: .pdf,
                url: "https://www.redcross.org/get-help/how-to-prepare-for-emergencies/make-a-plan"
            )
        ]
    }

    private static func createFireBehaviorLessons() -> [Lesson] {
        [
            Lesson(
                id: UUID(),
                moduleId: UUID(),
                title: "Fire Weather and Atmospheric Conditions",
                content: LessonContent(sections: [
                    ContentSection(
                        id: UUID(),
                        type: .text,
                        title: "Critical Fire Weather",
                        content: "Fire weather combines low humidity (below 15%), high temperatures (above 90°F), and strong winds (above 25 mph). These conditions create extreme fire behavior with rapid spread rates and high intensity.",
                        mediaURL: nil
                    ),
                    ContentSection(
                        id: UUID(),
                        type: .text,
                        title: "Wind Patterns",
                        content: "Diurnal winds change throughout the day. Upslope winds during day, downslope at night. Santa Ana and Diablo winds are particularly dangerous, creating extreme fire weather conditions in California.",
                        mediaURL: nil
                    ),
                    ContentSection(
                        id: UUID(),
                        type: .text,
                        title: "Atmospheric Instability",
                        content: "Unstable atmospheric conditions can create fire whirls, erratic fire behavior, and dangerous downdrafts. Haines Index measures atmospheric stability and moisture content.",
                        mediaURL: nil
                    )
                ]),
                estimatedDuration: 900,
                isCompleted: false,
                userNotes: ""
            ),
            Lesson(
                id: UUID(),
                moduleId: UUID(),
                title: "Topography and Fire Spread",
                content: LessonContent(sections: [
                    ContentSection(
                        id: UUID(),
                        type: .text,
                        title: "Slope Effects",
                        content: "Fire spreads faster uphill due to preheating of fuels above the fire. For every 10° increase in slope, fire spread rate can double. Steep slopes create dangerous fire behavior.",
                        mediaURL: nil
                    ),
                    ContentSection(
                        id: UUID(),
                        type: .text,
                        title: "Terrain Features",
                        content: "Canyons, ridges, and saddles affect fire behavior. Narrow canyons create chimney effects. Ridge tops experience increased wind speeds. Saddles channel winds and accelerate fire spread.",
                        mediaURL: nil
                    )
                ]),
                estimatedDuration: 720,
                isCompleted: false,
                userNotes: ""
            )
        ]
    }

    private static func createFireBehaviorQuiz() -> Quiz {
        Quiz(
            id: UUID(),
            moduleId: UUID(),
            title: "Fire Behavior & Science Quiz",
            description: "Advanced fire behavior and meteorology concepts",
            questions: [
                QuizQuestion(
                    id: UUID(),
                    question: "What relative humidity level is considered critical for fire weather?",
                    type: .multipleChoice,
                    options: ["Below 30%", "Below 20%", "Below 15%", "Below 10%"],
                    correctAnswers: [2],
                    explanation: "Relative humidity below 15% is considered critical fire weather, creating extreme fire danger conditions.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "How does slope affect fire spread rate?",
                    type: .multipleChoice,
                    options: ["No significant effect", "Doubles for every 10° increase", "Triples for every 20° increase", "Quadruples for every 30° increase"],
                    correctAnswers: [1],
                    explanation: "Fire spread rate can double for every 10° increase in slope due to preheating effects.",
                    points: 15,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Which factors contribute to critical fire weather?",
                    type: .multipleSelect,
                    options: ["Low humidity", "High temperatures", "Strong winds", "High atmospheric pressure", "Clear skies", "Recent rainfall"],
                    correctAnswers: [0, 1, 2, 4],
                    explanation: "Low humidity, high temperatures, strong winds, and clear skies all contribute to critical fire weather.",
                    points: 20,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Fire always spreads faster downhill than uphill.",
                    type: .trueFalse,
                    options: ["True", "False"],
                    correctAnswers: [1],
                    explanation: "False. Fire spreads faster uphill due to preheating of fuels above the fire front.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "What is the Haines Index used to measure?",
                    type: .multipleChoice,
                    options: ["Wind speed", "Temperature", "Atmospheric stability and moisture", "Fire intensity"],
                    correctAnswers: [2],
                    explanation: "The Haines Index measures atmospheric stability and moisture content to predict fire behavior potential.",
                    points: 15,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Which terrain features can create dangerous fire behavior?",
                    type: .multipleSelect,
                    options: ["Narrow canyons", "Ridge tops", "Saddles", "Flat areas", "North-facing slopes", "Box canyons"],
                    correctAnswers: [0, 1, 2, 5],
                    explanation: "Narrow canyons, ridge tops, saddles, and box canyons all create dangerous fire behavior through wind channeling and terrain effects.",
                    points: 20,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "Santa Ana winds are particularly dangerous for fire spread.",
                    type: .trueFalse,
                    options: ["True", "False"],
                    correctAnswers: [0],
                    explanation: "True. Santa Ana winds create extreme fire weather with hot, dry, strong winds that dramatically increase fire danger.",
                    points: 10,
                    mediaURL: nil
                ),
                QuizQuestion(
                    id: UUID(),
                    question: "What wind speed significantly increases fire danger?",
                    type: .multipleChoice,
                    options: ["Above 15 mph", "Above 20 mph", "Above 25 mph", "Above 30 mph"],
                    correctAnswers: [2],
                    explanation: "Winds above 25 mph significantly increase fire danger by accelerating fire spread and creating spotting.",
                    points: 10,
                    mediaURL: nil
                )
            ],
            timeLimit: 1200,
            passingScore: 0.75,
            maxAttempts: 3
        )
    }

    private static func createFireBehaviorResources() -> [Resource] {
        [
            Resource(
                id: UUID(),
                title: "Fire Weather and Behavior Guide",
                description: "National Interagency Fire Center fire weather guide",
                type: .pdf,
                url: "https://www.nifc.gov/fire-information/fire-weather"
            ),
            Resource(
                id: UUID(),
                title: "Topographic Fire Behavior",
                description: "How terrain affects fire behavior patterns",
                type: .video,
                url: "https://www.nwcg.gov/publications/pms425"
            )
        ]
    }

    private static func createBasicsFlashcards() -> [Flashcard] {
        return Array(createSampleFlashcards().prefix(5))
    }

    private static func createHomeSafetyFlashcards() -> [Flashcard] {
        return Array(createSampleFlashcards().dropFirst(5).prefix(5))
    }

    private static func createEmergencyPlanningFlashcards() -> [Flashcard] {
        return Array(createSampleFlashcards().dropFirst(10).prefix(5))
    }

    private static func createFireBehaviorFlashcards() -> [Flashcard] {
        return Array(createSampleFlashcards().dropFirst(15).prefix(5))
    }
}
