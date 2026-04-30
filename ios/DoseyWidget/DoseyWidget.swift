import SwiftUI
import WidgetKit

private let appGroupIdentifier = "group.com.evacates.dosey.shared"
private let completedKey = "siri.dailySummary.completedDosesToday"
private let totalKey = "siri.dailySummary.totalDosesToday"
private let nextDoseMsKey = "siri.dailySummary.nextDoseEpochMs"
private let nextDoseNameKey = "siri.dailySummary.nextDoseMedicationName"
private let darkModeKey = "dosey.widget.darkMode"
private let highContrastKey = "dosey.widget.highContrast"
private let uiScaleKey = "dosey.widget.uiScale"

struct DoseyEntry: TimelineEntry {
  let date: Date
  let completed: Int
  let total: Int
  let nextDoseDate: Date?
  let nextDoseName: String
  let darkMode: Bool
  let highContrast: Bool
  let uiScale: Double
}

struct DoseyProvider: TimelineProvider {
  func placeholder(in context: Context) -> DoseyEntry {
    DoseyEntry(
      date: .now,
      completed: 2,
      total: 3,
      nextDoseDate: Calendar.current.date(byAdding: .hour, value: 2, to: .now),
      nextDoseName: "Vitamin D",
      darkMode: false,
      highContrast: false,
      uiScale: 1.0
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (DoseyEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DoseyEntry>) -> Void) {
    let entry = loadEntry()
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 20, to: .now) ?? .now.addingTimeInterval(1200)
    completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
  }

  private func loadEntry() -> DoseyEntry {
    let defaults = UserDefaults(suiteName: appGroupIdentifier)
    let total = max(defaults?.integer(forKey: totalKey) ?? 0, 0)
    let completed = min(max(defaults?.integer(forKey: completedKey) ?? 0, 0), max(total, 1))
    let nextMs = defaults?.integer(forKey: nextDoseMsKey) ?? -1
    let nextName = defaults?.string(forKey: nextDoseNameKey) ?? ""
    let nextDate = nextMs > 0 ? Date(timeIntervalSince1970: TimeInterval(nextMs) / 1000.0) : nil
    let darkMode = defaults?.bool(forKey: darkModeKey) ?? false
    let highContrast = defaults?.bool(forKey: highContrastKey) ?? false
    let uiScale = min(max(defaults?.double(forKey: uiScaleKey) ?? 1.0, 0.85), 1.35)

    return DoseyEntry(
      date: .now,
      completed: completed,
      total: max(total, 1),
      nextDoseDate: nextDate,
      nextDoseName: nextName,
      darkMode: darkMode,
      highContrast: highContrast,
      uiScale: uiScale
    )
  }
}

private struct DoseyDots: View {
  let completed: Int
  let total: Int
  let darkMode: Bool
  let highContrast: Bool

  private var doneColor: Color {
    if highContrast { return darkMode ? Color(red: 0.56, green: 0.98, blue: 0.94) : Color(red: 0.0, green: 0.36, blue: 0.32) }
    return darkMode ? Color(red: 0.83, green: 0.74, blue: 0.46) : Color(red: 0.13, green: 0.42, blue: 0.30)
  }

  private var pendingColor: Color {
    if highContrast { return darkMode ? Color(red: 0.56, green: 0.98, blue: 0.94).opacity(0.35) : Color.black.opacity(0.20) }
    return darkMode ? Color(red: 0.18, green: 0.32, blue: 0.30) : Color(red: 0.73, green: 0.80, blue: 0.78)
  }

  var body: some View {
    HStack(spacing: 5) {
      ForEach(0..<min(max(total, 1), 10), id: \.self) { index in
        if index == min(max(total, 1), 10) - 1 && completed >= total {
          Image(systemName: "star.fill")
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(doneColor)
            .frame(width: 12, height: 12)
        } else {
          Circle()
            .fill(index < completed ? doneColor : pendingColor)
            .frame(width: 10, height: 10)
        }
      }
    }
  }
}

struct DoseyWidgetView: View {
  @Environment(\.colorScheme) private var colorScheme

  let entry: DoseyEntry

  private var widgetGradient: LinearGradient {
    if entry.highContrast {
      return LinearGradient(
        colors: entry.darkMode ? [Color(red: 0.01, green: 0.04, blue: 0.04), Color(red: 0.03, green: 0.12, blue: 0.11)] : [.white, Color(red: 0.91, green: 0.97, blue: 0.95)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
    let colors = entry.darkMode
      ? [
        Color(red: 0.01, green: 0.04, blue: 0.04),
        Color(red: 0.04, green: 0.20, blue: 0.18)
      ]
      : [
        Color(red: 0.98, green: 0.97, blue: 0.93),
        Color(red: 0.85, green: 0.94, blue: 0.92)
      ]

    return LinearGradient(
      colors: colors,
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  private var foregroundColor: Color {
    entry.darkMode
      ? (entry.highContrast ? Color(red: 0.96, green: 1.0, blue: 0.99) : Color(red: 0.94, green: 0.95, blue: 0.90))
      : (entry.highContrast ? .black : Color(red: 0.04, green: 0.18, blue: 0.16))
  }

  private var nextText: String {
    guard let nextDoseDate = entry.nextDoseDate, !entry.nextDoseName.isEmpty else {
	      return "All doses aligned"
    }
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return "\(entry.nextDoseName) at \(formatter.string(from: nextDoseDate))"
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      widgetGradient

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Image(systemName: entry.completed >= entry.total ? "checkmark.seal.fill" : "pills.circle.fill")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(foregroundColor)
          Spacer()
          Text("\(entry.completed)/\(entry.total)")
            .font(.system(size: 18 * entry.uiScale, weight: .black, design: .rounded))
            .foregroundStyle(foregroundColor)
        }

        Text(entry.completed >= entry.total ? "All doses aligned" : "Next dose")
          .font(.system(size: 14 * entry.uiScale, weight: .bold, design: .rounded))
          .foregroundStyle(foregroundColor)
          .lineLimit(2)

        DoseyDots(
          completed: entry.completed,
          total: entry.total,
          darkMode: entry.darkMode,
          highContrast: entry.highContrast
        )

        Text(nextText)
          .font(.system(size: 11 * entry.uiScale, weight: .semibold, design: .rounded))
          .foregroundStyle(foregroundColor.opacity(0.72))
          .lineLimit(2)
      }
      .padding(12)
    }
    .widgetBackground(widgetGradient)
  }
}

struct DoseyWidget: Widget {
  let kind = "DoseyWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: DoseyProvider()) { entry in
      DoseyWidgetView(entry: entry)
    }
    .configurationDisplayName("Velouria")
    .description("Daily dose progress and the next scheduled medication.")
    .supportedFamilies([.systemSmall, .systemMedium])
    .contentMarginsDisabled()
  }
}

@main
struct DoseyWidgetBundle: WidgetBundle {
  var body: some Widget {
    DoseyWidget()
  }
}

private extension View {
  @ViewBuilder
  func widgetBackground(_ gradient: LinearGradient) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(gradient, for: .widget)
    } else {
      background(gradient)
    }
  }
}
