//
//  HabitWidget.swift
//  Tracker_Habits_IOS
//
//  Created by Nick Elao on 28/1/26.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MonthEntry {
        MonthEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthEntry) -> ()) {
        completion(MonthEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthEntry>) -> ()) {
        // Actualiza cada pocas horas (también forzamos reload al marcar)
        let now = Date()
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now.addingTimeInterval(6*3600)
        completion(Timeline(entries: [MonthEntry(date: now)], policy: .after(next)))
    }
}

struct MonthEntry: TimelineEntry {
    let date: Date
}

struct MonthWidgetView: View {
    let entry: MonthEntry

    var body: some View {
        let calendar = Calendar.current
        let days = daysInMonth(for: entry.date, calendar: calendar)
        let leadingBlanks = leadingBlankCount(for: entry.date, calendar: calendar)

        // 7 columnas, celdas cuadradas
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        LazyVGrid(columns: columns, spacing: 4) {
            // huecos iniciales para alinear el día 1
            ForEach(0..<leadingBlanks, id: \.self) { _ in
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
            }

            ForEach(days, id: \.self) { day in
                let done = HabitStore.isDone(day, calendar: calendar)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary)
                    .opacity(done ? 0.85 : 0.18)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        // borde muy sutil para "hoy"
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.primary.opacity(isToday(day, calendar: calendar) ? 0.35 : 0.0), lineWidth: 1)
                    )
            }
        }
        .padding(10)
        .containerBackground(.background, for: .widget)
    }

    private func daysInMonth(for date: Date, calendar: Calendar) -> [Date] {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let range = calendar.range(of: .day, in: .month, for: start)!
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: start)
        }
    }

    private func leadingBlankCount(for date: Date, calendar: Calendar) -> Int {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let weekday = calendar.component(.weekday, from: start) // 1..7
        // Convertimos para que Lunes sea 0, Martes 1, ... (según firstWeekday)
        let firstWeekday = calendar.firstWeekday // en ES suele ser 2 (lunes)
        let shift = (weekday - firstWeekday + 7) % 7
        return shift
    }

    private func isToday(_ date: Date, calendar: Calendar) -> Bool {
        calendar.isDate(date, inSameDayAs: Date())
    }
}

@main
struct HabitWidget: Widget {
    let kind: String = "HabitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MonthWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit Month")
        .description("Minimal monthly tracker.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
