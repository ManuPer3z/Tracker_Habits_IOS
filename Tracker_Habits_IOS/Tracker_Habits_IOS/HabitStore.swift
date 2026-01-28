import Foundation

struct Habit: Codable, Identifiable, Hashable {
    let id: String
    var name: String
}

enum HabitStore {
    static let appGroupId = "group.com.manuperez.habitwidget"

    private static let habitsKey = "habits"                  // [Habit]
    private static let completionsKey = "completionsByHabit"  // [habitId: [yyyy-MM-dd]]
    private static let activeHabitKey = "activeHabitId"       // String (habitId)

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupId)!
    }

    // MARK: - Habits

    static func loadHabits() -> [Habit] {
        guard let data = defaults.data(forKey: habitsKey) else {
            // Seed inicial
            let seed = [Habit(id: UUID().uuidString, name: "Crossfit")]
            saveHabits(seed)

            // Seed también del active habit para que todo tenga sentido
            setActiveHabitId(seed[0].id)

            return seed
        }
        return (try? JSONDecoder().decode([Habit].self, from: data)) ?? []
    }

    static func saveHabits(_ habits: [Habit]) {
        let data = try? JSONEncoder().encode(habits)
        defaults.set(data, forKey: habitsKey)

        // Si no existe activeHabit o apunta a un id que ya no existe, arreglamos
        let active = defaults.string(forKey: activeHabitKey)
        if active == nil || !habits.contains(where: { $0.id == active }) {
            if let first = habits.first {
                setActiveHabitId(first.id)
            }
        }
    }

    static func addHabit(name: String) -> Habit {
        var habits = loadHabits()
        let newHabit = Habit(id: UUID().uuidString, name: name)
        habits.append(newHabit)
        saveHabits(habits)
        return newHabit
    }

    static func renameHabit(id: String, name: String) {
        var habits = loadHabits()
        guard let idx = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[idx].name = name
        saveHabits(habits)
    }

    static func habitName(for id: String) -> String {
        loadHabits().first(where: { $0.id == id })?.name ?? "Habit"
    }

    static func defaultHabitId() -> String {
        // Importante: NO devolver UUID() nuevo si no hay hábitos,
        // porque eso rompe la estabilidad del widget/app.
        let habits = loadHabits()
        if let first = habits.first { return first.id }

        // Si llegara aquí (muy raro), crea un seed
        let seed = Habit(id: UUID().uuidString, name: "Crossfit")
        saveHabits([seed])
        setActiveHabitId(seed.id)
        return seed.id
    }

    // MARK: - Active habit (widget dinámico)

    static func getActiveHabitId() -> String {
        let habits = loadHabits()
        if let stored = defaults.string(forKey: activeHabitKey),
           habits.contains(where: { $0.id == stored }) {
            return stored
        }
        // Si no hay o no es válido, usamos el primero
        let fallback = habits.first?.id ?? defaultHabitId()
        setActiveHabitId(fallback)
        return fallback
    }

    static func setActiveHabitId(_ id: String) {
        defaults.set(id, forKey: activeHabitKey)
    }

    // MARK: - Completions

    private static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let start = calendar.startOfDay(for: date)
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = calendar.timeZone
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: start)
    }

    private static func loadCompletionMap() -> [String: [String]] {
        guard let data = defaults.data(forKey: completionsKey) else { return [:] }
        return (try? JSONDecoder().decode([String: [String]].self, from: data)) ?? [:]
    }

    private static func saveCompletionMap(_ map: [String: [String]]) {
        let data = try? JSONEncoder().encode(map)
        defaults.set(data, forKey: completionsKey)
    }

    static func isDone(_ date: Date, habitId: String, calendar: Calendar = .current) -> Bool {
        let key = dayKey(for: date, calendar: calendar)
        let map = loadCompletionMap()
        let arr = map[habitId] ?? []
        return Set(arr).contains(key)
    }

    static func markDoneToday(habitId: String, calendar: Calendar = .current) {
        let key = dayKey(for: Date(), calendar: calendar)
        var map = loadCompletionMap()
        var set = Set(map[habitId] ?? [])
        set.insert(key)
        map[habitId] = Array(set)
        saveCompletionMap(map)
    }

    static func unmarkToday(habitId: String, calendar: Calendar = .current) {
        let key = dayKey(for: Date(), calendar: calendar)
        var map = loadCompletionMap()
        var set = Set(map[habitId] ?? [])
        set.remove(key)
        map[habitId] = Array(set)
        saveCompletionMap(map)
    }
}
