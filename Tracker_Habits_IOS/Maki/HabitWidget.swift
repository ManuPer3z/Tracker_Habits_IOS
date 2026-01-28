import WidgetKit
import SwiftUI

// MARK: - Entry

struct MonthEntry: TimelineEntry {
    let date: Date
}

// MARK: - Provider (TimelineProvider normal)

struct MonthProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthEntry {
        MonthEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthEntry) -> Void) {
        completion(MonthEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthEntry>) -> Void) {
        let now = Date()
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: now)
            ?? now.addingTimeInterval(6 * 3600)

        completion(Timeline(entries: [MonthEntry(date: now)], policy: .after(next)))
    }
}

// MARK: - Main View

struct MonthWidgetView: View {
    let entry: MonthEntry
    @Environment(\.widgetFamily) var family

    private let outerPadding: CGFloat = 12
    private let titleHeight: CGFloat = 18
    private let titleBottomGap: CGFloat = 10

    // ✅ ACTIVE HABIT
    var habitId: String { HabitStore.getActiveHabitId() }
    var habitName: String { HabitStore.habitName(for: habitId) }

    var body: some View {
        let cal = Calendar.current
        let current = startOfMonth(entry.date, calendar: cal)
        let m1 = cal.date(byAdding: .month, value: -1, to: current)!
        let m2 = cal.date(byAdding: .month, value: -2, to: current)!

        VStack(alignment: .leading, spacing: titleBottomGap) {
            Text(habitName)
                .font(.system(size: 14, weight: .semibold))
                .opacity(0.9)
                .lineLimit(1)
                .frame(height: titleHeight)

            GeometryReader { geo in
                let gridAreaH = geo.size.height

                switch family {
                case .systemSmall:
                    MonthGrid(month: current, habitId: habitId)

                case .systemMedium:
                    HStack(spacing: 10) {
                        MonthGrid(month: m1, habitId: habitId)
                        MonthGrid(month: current, habitId: habitId)
                    }

                case .systemLarge:
                    // ✅ 3 meses EN VERTICAL (para rellenar el grande)
                    VStack(spacing: 10) {
                        MonthGrid(month: m2, habitId: habitId)
                        MonthGrid(month: m1, habitId: habitId)
                        MonthGrid(month: current, habitId: habitId)
                    }
                    .frame(height: gridAreaH, alignment: .top)

                default:
                    MonthGrid(month: current, habitId: habitId)
                }
            }
        }
        .padding(outerPadding)
        .containerBackground(.ultraThinMaterial, for: .widget)
    }

    private func startOfMonth(_ date: Date, calendar: Calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }
}

// MARK: - Month grid (7x6)

private struct MonthGrid: View {
    let month: Date
    let habitId: String

    private let cols = 7
    private let rows = 6
    private let minSpacing: CGFloat = 3
    private let maxSpacing: CGFloat = 7

    var body: some View {
        let cal = Calendar.current
        let cells = monthCells(for: month, calendar: cal)

        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let cellW = floor(w / CGFloat(cols))
            let cellH = floor(h / CGFloat(rows))
            let cell = max(4, min(cellW, cellH))

            let hSpacing = clamp((w - cell * CGFloat(cols)) / CGFloat(max(cols - 1, 1)), minSpacing, maxSpacing)
            let vSpacing = clamp((h - cell * CGFloat(rows)) / CGFloat(max(rows - 1, 1)), minSpacing, maxSpacing)

            let columns = Array(repeating: GridItem(.fixed(cell), spacing: hSpacing), count: cols)
            let radius = max(3, cell * 0.18)

            LazyVGrid(columns: columns, spacing: vSpacing) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, d in
                    if let day = d {
                        let done = HabitStore.isDone(day, habitId: habitId, calendar: cal)
                        let today = cal.isDate(day, inSameDayAs: Date())

                        // ✅ “Hoy” NO blanco cantoso
                        let baseOpacity: Double = done ? 0.82 : 0.18
                        let todayBoost: Double = today ? (done ? 0.06 : 0.12) : 0.0
                        let finalOpacity = min(0.92, baseOpacity + todayBoost)

                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color.primary)
                            .opacity(finalOpacity)
                            .frame(width: cell, height: cell)
                            .overlay(
                                RoundedRectangle(cornerRadius: radius)
                                    .stroke(Color.primary.opacity(today ? 0.22 : 0.0), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(Color.primary.opacity(0.06))
                            .frame(width: cell, height: cell)
                    }
                }
            }
            .frame(width: w, height: h, alignment: .topLeading)
        }
    }

    private func monthCells(for month: Date, calendar: Calendar) -> [Date?] {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let range = calendar.range(of: .day, in: .month, for: start)!
        let numDays = range.count

        let weekday = calendar.component(.weekday, from: start)
        let firstWeekday = calendar.firstWeekday
        let leading = (weekday - firstWeekday + 7) % 7

        var out: [Date?] = Array(repeating: nil, count: leading)
        for d in 0..<numDays {
            out.append(calendar.date(byAdding: .day, value: d, to: start)!)
        }

        let total = rows * cols
        if out.count < total { out += Array(repeating: nil, count: total - out.count) }
        if out.count > total { out = Array(out.prefix(total)) }
        return out
    }

    private func clamp(_ value: CGFloat, _ minV: CGFloat, _ maxV: CGFloat) -> CGFloat {
        min(max(value, minV), maxV)
    }
}

// MARK: - Widget

struct HabitWidget: Widget {
    let kind: String = "HabitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthProvider()) { entry in
            MonthWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit Month")
        .description("Minimal monthly tracker (active habit).")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
