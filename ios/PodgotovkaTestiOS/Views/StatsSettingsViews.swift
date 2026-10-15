import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.themes, id: \.self) { theme in
                    let stats = store.state.stats[theme] ?? ThemeStats()
                    Section(theme) {
                        HStack { Text("Вопросов"); Spacer(); Text("\(store.questions(for: theme).count)") }
                        HStack { Text("Пройдено"); Spacer(); Text("\(stats.seen.count)") }
                        HStack { Text("Ошибок в повторении"); Spacer(); Text("\(stats.mistakes.count)").foregroundStyle(stats.mistakes.isEmpty ? .green : .orange) }
                        HStack { Text("Правильных ответов"); Spacer(); Text("\(stats.correctCount)") }
                        HStack { Text("Неправильных ответов"); Spacer(); Text("\(stats.wrongCount)") }
                    }
                }
            }
            .navigationTitle("Статистика")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var days = 20
    @State private var confirmThemeReset = false
    @State private var confirmAllReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("План обучения") {
                    Stepper("Дней: \(days)", value: $days, in: 1...90)
                    Button("Сохранить срок") { store.setTrainingDays(days) }
                    Text("Текущий день: \(store.currentDay()) из \(store.state.trainingDays)").foregroundStyle(.secondary)
                }
                Section("Тема для сброса") {
                    ForEach(store.themes, id: \.self) { theme in
                        Button(role: .destructive) {
                            store.reset(theme: theme)
                        } label: {
                            Label("Сбросить «\(theme)»", systemImage: "arrow.counterclockwise")
                        }
                    }
                }
                Section("Все данные") {
                    Button(role: .destructive) { confirmAllReset = true } label: {
                        Label("Полный сброс обучения", systemImage: "trash")
                    }
                }
                Section("О приложении") {
                    Text("Подготовка к тестированию 2026")
                    Text("424 вопроса • 2 независимые темы • экзамен 20 вопросов")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Настройки")
            .onAppear { days = store.state.trainingDays }
            .confirmationDialog("Сбросить всё обучение?", isPresented: $confirmAllReset, titleVisibility: .visible) {
                Button("Сбросить", role: .destructive) { store.resetAll() }
                Button("Отмена", role: .cancel) { }
            }
        }
    }
}
