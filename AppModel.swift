import Foundation

struct Question: Codable, Identifiable, Hashable {
    let id: Int
    let sourceRow: Int?
    let theme: String
    let question: String
    let type: String
    let options: [String]
    let correct: Int?
    let answerText: String
    let hint: String
}

struct ThemeStats: Codable {
    var seen: Set<Int> = []
    var mistakes: Set<Int> = []
    var correctCount: Int = 0
    var wrongCount: Int = 0
    var answeredCount: Int = 0
}

struct PersistedState: Codable {
    var trainingDays: Int = 20
    var startDate: Date?
    var stats: [String: ThemeStats] = [:]
}

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var questions: [Question] = []
    @Published private(set) var state = PersistedState()
    @Published var selectedTheme = "Технические вопросы 2026"

    let themes = ["Технические вопросы 2026", "Ответственные за БПР 2026"]
    private let stateKey = "PodgotovkaTestiOS.state.v1"

    init() {
        loadQuestions()
        loadState()
    }

    var selectedStats: ThemeStats { state.stats[selectedTheme] ?? ThemeStats() }

    func questions(for theme: String) -> [Question] { questions.filter { $0.theme == theme } }

    func progress(for theme: String) -> Double {
        let total = questions(for: theme).count
        guard total > 0 else { return 0 }
        return min(1, Double((state.stats[theme] ?? ThemeStats()).seen.count) / Double(total))
    }

    func currentDay() -> Int {
        guard let start = state.startDate else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: start), to: Calendar.current.startOfDay(for: Date())).day ?? 0
        return min(state.trainingDays, max(1, days + 1))
    }

    func setTrainingDays(_ days: Int) {
        state.trainingDays = min(90, max(1, days))
        state.startDate = Date()
        save()
    }

    func ensureStarted() {
        if state.startDate == nil { state.startDate = Date(); save() }
    }

    func smartQuestions(for theme: String) -> [Question] {
        let all = questions(for: theme)
        let stats = state.stats[theme] ?? ThemeStats()
        let mistakes = all.filter { stats.mistakes.contains($0.id) }
        let new = all.filter { !stats.seen.contains($0.id) }
        return (mistakes + Array(new.prefix(10))).uniqueByID().shuffled()
    }

    func dailyQuestions(for theme: String) -> [Question] {
        let all = questions(for: theme)
        let stats = state.stats[theme] ?? ThemeStats()
        let day = currentDay()
        let total = all.count
        let base = Int(ceil(Double(total) / Double(max(1, state.trainingDays))))
        let start = min(total, (day - 1) * base)
        let end = min(total, start + base)
        let newQuestions = Array(all.sorted { $0.id < $1.id }[start..<end])
        let errors = all.filter { stats.mistakes.contains($0.id) }
        return (errors + newQuestions).uniqueByID().shuffled()
    }

    func answer(_ question: Question, isCorrect: Bool) {
        var stats = state.stats[question.theme] ?? ThemeStats()
        stats.seen.insert(question.id)
        stats.answeredCount += 1
        if isCorrect {
            stats.correctCount += 1
            stats.mistakes.remove(question.id)
        } else {
            stats.wrongCount += 1
            stats.mistakes.insert(question.id)
        }
        state.stats[question.theme] = stats
        save()
    }

    func reset(theme: String) {
        state.stats[theme] = ThemeStats()
        state.startDate = Date()
        save()
    }

    func resetAll() {
        state = PersistedState()
        save()
    }

    private func loadQuestions() {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Question].self, from: data) else { return }
        questions = decoded
    }

    private func loadState() {
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let decoded = try? JSONDecoder().decode(PersistedState.self, from: data) else { return }
        state = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: stateKey)
        }
        objectWillChange.send()
    }
}

extension Array where Element == Question {
    func uniqueByID() -> [Question] {
        var ids = Set<Int>()
        return filter { ids.insert($0.id).inserted }
    }
}
