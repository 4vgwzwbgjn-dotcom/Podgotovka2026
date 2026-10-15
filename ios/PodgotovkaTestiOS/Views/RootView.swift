import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView().tabItem { Label("Главная", systemImage: "house.fill") }
            StatsView().tabItem { Label("Статистика", systemImage: "chart.bar.fill") }
            SettingsView().tabItem { Label("Настройки", systemImage: "gearshape.fill") }
        }
        .tint(.cyan)
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showExam = false
    @State private var showLearn = false
    @State private var smart = true
    @State private var selectedTheme = "Технические вопросы 2026"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    ForEach(store.themes, id: \.self) { theme in
                        ThemeCard(theme: theme) {
                            selectedTheme = theme
                            smart = true
                            showLearn = true
                        }
                    }
                    examCard
                }
                .padding()
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Подготовка к тесту")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLearn) {
                LearnView(theme: selectedTheme, smart: smart)
            }
            .sheet(isPresented: $showExam) {
                ExamView(theme: selectedTheme)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("20 дней → уверенная подготовка")
                .font(.title2.bold())
            Text("Ошибки автоматически возвращаются в следующее повторение.")
                .foregroundStyle(.secondary)
        }
    }

    private var examCard: some View {
        Button {
            selectedTheme = store.selectedTheme
            showExam = true
        } label: {
            HStack {
                Image(systemName: "graduationcap.fill").font(.title2)
                VStack(alignment: .leading) {
                    Text("Экзамен — 20 вопросов").font(.headline)
                    Text("Сдача: максимум 2 ошибки").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

struct ThemeCard: View {
    @EnvironmentObject private var store: AppStore
    let theme: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(theme).font(.headline)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                ProgressView(value: store.progress(for: theme))
                HStack {
                    Text("Пройдено \(store.selectedStatsFor(theme).seen.count) из \(store.questions(for: theme).count)")
                    Spacer()
                    Text("\(Int(store.progress(for: theme) * 100))%")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

private extension AppStore {
    func selectedStatsFor(_ theme: String) -> ThemeStats { state.stats[theme] ?? ThemeStats() }
}

struct LearnView: View {
    @EnvironmentObject private var store: AppStore
    let theme: String
    let smart: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var questions: [Question] = []
    @State private var index = 0
    @State private var selected: Int?
    @State private var textAnswer = ""
    @State private var answered = false
    @State private var isCorrect = false

    var body: some View {
        NavigationStack {
            Group {
                if questions.isEmpty {
                    ContentUnavailableView("Нет вопросов", systemImage: "checkmark.circle")
                } else {
                    questionBody
                }
            }
            .navigationTitle(smart ? "Умное обучение" : "Обучение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Закрыть") { dismiss() } } }
            .onAppear { load() }
        }
    }

    private var questionBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ProgressView(value: Double(index + 1), total: Double(questions.count))
                Text("Вопрос \(index + 1) из \(questions.count)").font(.caption).foregroundStyle(.secondary)
                Text(questions[index].question).font(.title3.bold())
                if questions[index].type == "text" {
                    textQuestion
                } else {
                    ForEach(Array(questions[index].options.enumerated()), id: \.offset) { i, option in
                        optionButton(i, option)
                    }
                }
                if answered && !isCorrect { explanation }
                if answered {
                    Button(index + 1 < questions.count ? "Следующий вопрос" : "Завершить") { next() }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
    }

    private var textQuestion: some View {
        VStack(spacing: 12) {
            TextField("Введите ответ", text: $textAnswer)
                .textFieldStyle(.roundedBorder)
                .disabled(answered)
            if !answered {
                Button("Проверить") {
                    isCorrect = normalize(textAnswer) == normalize(questions[index].answerText)
                    answered = true
                    store.answer(questions[index], isCorrect: isCorrect)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Label(isCorrect ? "Правильно" : "Неправильно", systemImage: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? .green : .red)
            }
        }
    }

    private func optionButton(_ i: Int, _ option: String) -> some View {
        Button {
            guard !answered else { return }
            selected = i
            isCorrect = (i == questions[index].correct)
            answered = true
            store.answer(questions[index], isCorrect: isCorrect)
        } label: {
            HStack(alignment: .top) {
                Text("\(i + 1)").font(.headline.monospaced()).frame(width: 26)
                Text(option).multilineTextAlignment(.leading)
                Spacer()
                if answered && i == questions[index].correct { Image(systemName: "checkmark.circle.fill") }
                if answered && selected == i && i != questions[index].correct { Image(systemName: "xmark.circle.fill") }
            }
            .padding()
            .background(background(for: i), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func background(for i: Int) -> Color {
        if answered && i == questions[index].correct { return .green.opacity(0.22) }
        if answered && selected == i { return .red.opacity(0.22) }
        return Color.secondary.opacity(0.12)
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Правильный ответ", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            Text(questions[index].answerText).font(.headline)
            Text(questions[index].hint).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
    }

    private func load() {
        store.ensureStarted()
        questions = smart ? store.smartQuestions(for: theme) : store.dailyQuestions(for: theme)
    }

    private func next() {
        if index + 1 < questions.count {
            index += 1; selected = nil; textAnswer = ""; answered = false; isCorrect = false
        } else { dismiss() }
    }

    private func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: ",", with: ".")
            .filter { !$0.isWhitespace }
    }
}

struct ExamView: View {
    @EnvironmentObject private var store: AppStore
    let theme: String
    @Environment(\.dismiss) private var dismiss
    @State private var questions: [Question] = []
    @State private var index = 0
    @State private var wrong = 0
    @State private var selected: Int?
    @State private var textAnswer = ""
    @State private var answered = false
    @State private var finished = false

    var body: some View {
        NavigationStack {
            Group {
                if finished { resultView }
                else if questions.isEmpty { ContentUnavailableView("Недостаточно вопросов", systemImage: "questionmark") }
                else { examBody }
            }
            .navigationTitle("Экзамен")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Закрыть") { dismiss() } } }
            .onAppear { questions = Array(store.questions(for: theme).shuffled().prefix(20)) }
        }
    }

    private var examBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack { Text("Вопрос \(index + 1)/20"); Spacer(); Text("Ошибки: \(wrong)") }
                    .font(.subheadline.bold())
                ProgressView(value: Double(index + 1), total: 20)
                Text(questions[index].question).font(.title3.bold())
                if questions[index].type == "text" {
                    textExamQuestion
                } else {
                    ForEach(Array(questions[index].options.enumerated()), id: \.offset) { i, option in
                        Button { answerChoice(i) } label: {
                            HStack { Text("\(i + 1)").bold(); Text(option); Spacer() }
                                .padding().background(optionColor(i), in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(.plain)
                    }
                }
                if answered {
                    Button(index + 1 < 20 ? "Следующий" : "Завершить экзамен") { next() }
                        .buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
                }
            }.padding()
        }
    }

    private var textExamQuestion: some View {
        VStack(spacing: 12) {
            TextField("Введите ответ", text: $textAnswer)
                .textFieldStyle(.roundedBorder)
                .disabled(answered)
            if !answered {
                Button("Ответить") {
                    let ok = normalize(textAnswer) == normalize(questions[index].answerText)
                    answered = true
                    if !ok { wrong += 1 }
                }.buttonStyle(.borderedProminent)
            }
        }
    }

    private func answerChoice(_ i: Int) {
        guard !answered else { return }
        selected = i; answered = true
        if i != questions[index].correct { wrong += 1 }
    }

    private func optionColor(_ i: Int) -> Color {
        if !answered { return .secondary.opacity(0.12) }
        if i == questions[index].correct { return .green.opacity(0.22) }
        if selected == i { return .red.opacity(0.22) }
        return .secondary.opacity(0.12)
    }

    private func next() {
        if index + 1 < 20 {
            index += 1; selected = nil; textAnswer = ""; answered = false
        } else { finished = true }
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            Image(systemName: wrong <= 2 ? "checkmark.seal.fill" : "xmark.seal.fill").font(.system(size: 64)).foregroundStyle(wrong <= 2 ? .green : .red)
            Text(wrong <= 2 ? "Экзамен сдан" : "Экзамен не сдан").font(.largeTitle.bold())
            Text("Неправильных ответов: \(wrong) из 20")
            Text(wrong <= 2 ? "Допустимо не более 2 ошибок." : "Для сдачи необходимо не более 2 ошибок.").foregroundStyle(.secondary)
            Button("Готово") { dismiss() }.buttonStyle(.borderedProminent)
        }.padding()
    }

    private func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: ",", with: ".")
            .filter { !$0.isWhitespace }
    }
}
