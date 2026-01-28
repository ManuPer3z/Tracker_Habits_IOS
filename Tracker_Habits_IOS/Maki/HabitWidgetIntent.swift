//
//  HabitWidgetIntent.swift
//  Tracker_Habits_IOS
//
//  Created by Nick Elao on 28/1/26.
//

import AppIntents

// Entidad seleccionable en “Editar widget”
struct HabitEntity: AppEntity, Identifiable, Hashable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Habit"
    static var defaultQuery = HabitQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct HabitQuery: EntityQuery {
    func entities(for identifiers: [HabitEntity.ID]) async throws -> [HabitEntity] {
        let habits = HabitStore.loadHabits()
        let set = Set(identifiers)
        return habits
            .filter { set.contains($0.id) }
            .map { HabitEntity(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        HabitStore.loadHabits().map { HabitEntity(id: $0.id, name: $0.name) }
    }

    func defaultResult() async -> HabitEntity? {
        let habits = HabitStore.loadHabits()
        guard let first = habits.first else { return nil }
        return HabitEntity(id: first.id, name: first.name)
    }
}

// Intent que aparece al editar el widget
struct HabitWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Habit Widget"
    static var description = IntentDescription("Choose which habit this widget shows.")

    @Parameter(title: "Habit")
    var habit: HabitEntity?
}
