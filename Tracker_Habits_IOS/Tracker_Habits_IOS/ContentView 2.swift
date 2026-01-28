//
//  ContentView 2.swift
//  Tracker_Habits_IOS
//
//  Created by Nick Elao on 28/1/26.
//


import SwiftUI
import WidgetKit
import UIKit

struct ContentView: View {
    @State private var habits: [Habit] = HabitStore.loadHabits()
    @State private var selectedHabitId: String = HabitStore.defaultHabitId()
    @State private var newHabitName: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Picker("Habit", selection: $selectedHabitId) {
                ForEach(habits) { h in
                    Text(h.name).tag(h.id)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedHabitId) { _, newId in
                HabitStore.setActiveHabitId(newId)
                WidgetCenter.shared.reloadAllTimelines()
            }

            HStack(spacing: 12) {
                Button("Cumplido") {
                    HabitStore.markDoneToday(habitId: selectedHabitId)
                    WidgetCenter.shared.reloadAllTimelines()
                    exitToHome()
                }
                .buttonStyle(.borderedProminent)

                Button("Desmarcar") {
                    HabitStore.unmarkToday(habitId: selectedHabitId)
                    WidgetCenter.shared.reloadAllTimelines()
                    exitToHome()
                }
                .buttonStyle(.bordered)
            }

            Divider().opacity(0.4)

            HStack(spacing: 8) {
                TextField("Nuevo hábito", text: $newHabitName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                Button("Add") {
                    let name = newHabitName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }

                    let created = HabitStore.addHabit(name: name)
                    habits = HabitStore.loadHabits()
                    selectedHabitId = created.id
                    newHabitName = ""

                    // Mantener sincronizado el widget dinámico
                    HabitStore.setActiveHabitId(created.id)
                    WidgetCenter.shared.reloadAllTimelines()

                    exitToHome()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .onAppear {
            habits = HabitStore.loadHabits()
            selectedHabitId = HabitStore.getActiveHabitId()
            HabitStore.setActiveHabitId(selectedHabitId)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

// MARK: - Exit to Home (personal app helper)

private func exitToHome() {
    UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { exit(0) }
}
