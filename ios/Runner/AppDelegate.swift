import AppIntents
import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let siriChannelName = "dosey/siri_shortcuts"
  private let openMedicationsActivityType = "com.dosey.open_medications"
  private let openHistoryActivityType = "com.dosey.open_history"
  private let openTodayActivityType = "com.dosey.open_today"

  static let sharedAppGroupIdentifier = "group.com.evacates.dosey.shared"
  static let dailySummaryDayStampKey = "siri.dailySummary.dayStamp"
  static let dailySummaryTakenDosesKey = "siri.dailySummary.takenDoses"
  static let dailySummaryRemainingDosesKey = "siri.dailySummary.remainingDoses"
  static let dailySummaryTakenNamesKey = "siri.dailySummary.takenNames"
  static let dailySummaryRemainingNamesKey = "siri.dailySummary.remainingNames"
  static let dailySummaryTotalDosesTodayKey = "siri.dailySummary.totalDosesToday"
  static let dailySummaryCompletedDosesTodayKey = "siri.dailySummary.completedDosesToday"
  static let dailySummaryNextDoseEpochMsKey = "siri.dailySummary.nextDoseEpochMs"
  static let dailySummaryNextDoseMedicationNameKey = "siri.dailySummary.nextDoseMedicationName"
  static let widgetDarkModeKey = "dosey.widget.darkMode"
  static let widgetHighContrastKey = "dosey.widget.highContrast"
  static let widgetUiScaleKey = "dosey.widget.uiScale"
  static let pendingSiriNavigationKey = "siri.pendingNavigationDestination"

  private var siriChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    configureSiriChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  static var summaryDefaults: UserDefaults {
    UserDefaults(suiteName: sharedAppGroupIdentifier) ?? .standard
  }

  private func configureSiriChannel() {
    guard siriChannel == nil,
      let registrar = self.registrar(forPlugin: "SiriShortcutsBridge")
    else {
      return
    }
    let channel = FlutterMethodChannel(
      name: siriChannelName,
      binaryMessenger: registrar.messenger()
    )

    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleSiriMethodCall(call: call, result: result)
    }

    siriChannel = channel
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    let handled = handleIncomingSiriActivity(userActivity)
    let parentHandled = super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
    return handled || parentHandled
  }

  func handleIncomingSiriActivity(_ userActivity: NSUserActivity) -> Bool {
    let destination: String?
    switch userActivity.activityType {
    case openMedicationsActivityType:
      destination = "medications"
    case openHistoryActivityType:
      destination = "history"
    case openTodayActivityType:
      destination = "today"
    default:
      destination = nil
    }
    guard let dest = destination else {
      return false
    }
    notifyFlutterDestination(dest)
    return true
  }

  private func notifyFlutterDestination(_ destination: String) {
    if let channel = siriChannel {
      channel.invokeMethod("openDestinationFromSiri", arguments: destination)
    } else {
      AppDelegate.summaryDefaults.set(destination, forKey: AppDelegate.pendingSiriNavigationKey)
    }
  }

  private func donateNavigationUserActivity(destination: String) {
    let activityType: String
    let title: String
    switch destination {
    case "history":
      activityType = openHistoryActivityType
      title = "Open Velouria History"
    case "today":
      activityType = openTodayActivityType
      title = "Open Velouria Today"
    default:
      activityType = openMedicationsActivityType
      title = "Open Velouria Medications"
    }

    let activity = NSUserActivity(activityType: activityType)
    activity.title = title
    activity.isEligibleForSearch = true
    activity.isEligibleForPrediction = true
    activity.persistentIdentifier = activityType
    activity.userInfo = ["destination": destination]
    activity.becomeCurrent()
  }

  private func handleSiriMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(true)
    case "donateNavigationShortcut":
      guard let args = call.arguments as? [String: Any],
        let destination = args["destination"] as? String
      else {
        result(
          FlutterError(
            code: "invalid_args",
            message: "donateNavigationShortcut expects destination string.",
            details: nil
          )
        )
        return
      }
      donateNavigationUserActivity(destination: destination)
      result(nil)
    case "consumePendingDestination":
      let defs = AppDelegate.summaryDefaults
      let key = AppDelegate.pendingSiriNavigationKey
      let value = defs.string(forKey: key)
      if value != nil {
        defs.removeObject(forKey: key)
      }
      result(value)
    case "updateDailySummary":
      guard let args = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_args",
            message: "updateDailySummary expects a map payload.",
            details: nil
          )
        )
        return
      }

      let defaults = AppDelegate.summaryDefaults
      defaults.set(args["dayStamp"] as? String, forKey: AppDelegate.dailySummaryDayStampKey)
      defaults.set(args["takenDoses"] as? Int ?? 0, forKey: AppDelegate.dailySummaryTakenDosesKey)
      defaults.set(args["remainingDoses"] as? Int ?? 0, forKey: AppDelegate.dailySummaryRemainingDosesKey)
      defaults.set(args["takenMedicationNames"] as? [String] ?? [], forKey: AppDelegate.dailySummaryTakenNamesKey)
      defaults.set(args["remainingMedicationNames"] as? [String] ?? [], forKey: AppDelegate.dailySummaryRemainingNamesKey)

      let inferredTotal = (args["takenDoses"] as? Int ?? 0) + (args["remainingDoses"] as? Int ?? 0)
      defaults.set(args["totalDosesToday"] as? Int ?? inferredTotal, forKey: AppDelegate.dailySummaryTotalDosesTodayKey)
      defaults.set(
        args["completedDosesToday"] as? Int ?? (args["takenDoses"] as? Int ?? 0),
        forKey: AppDelegate.dailySummaryCompletedDosesTodayKey
      )
      let nextMs = args["nextDoseEpochMs"] as? Int ?? -1
      if nextMs > 0 {
        defaults.set(nextMs, forKey: AppDelegate.dailySummaryNextDoseEpochMsKey)
      } else {
        defaults.removeObject(forKey: AppDelegate.dailySummaryNextDoseEpochMsKey)
      }
      let nextName = (args["nextDoseMedicationName"] as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      if !nextName.isEmpty {
        defaults.set(nextName, forKey: AppDelegate.dailySummaryNextDoseMedicationNameKey)
      } else {
        defaults.removeObject(forKey: AppDelegate.dailySummaryNextDoseMedicationNameKey)
      }
      defaults.set(args["darkMode"] as? Bool ?? false, forKey: AppDelegate.widgetDarkModeKey)
      defaults.set(args["highContrast"] as? Bool ?? false, forKey: AppDelegate.widgetHighContrastKey)
      defaults.set(args["uiScale"] as? Double ?? 1.0, forKey: AppDelegate.widgetUiScaleKey)

      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadTimelines(ofKind: "DoseyWidget")
      }

      result(nil)
    case "updateWidgetAppearance":
      guard let args = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_args",
            message: "updateWidgetAppearance expects a map payload.",
            details: nil
          )
        )
        return
      }
      let defaults = AppDelegate.summaryDefaults
      defaults.set(args["darkMode"] as? Bool ?? false, forKey: AppDelegate.widgetDarkModeKey)
      defaults.set(args["highContrast"] as? Bool ?? false, forKey: AppDelegate.widgetHighContrastKey)
      defaults.set(args["uiScale"] as? Double ?? 1.0, forKey: AppDelegate.widgetUiScaleKey)
      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadTimelines(ofKind: "DoseyWidget")
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

@available(iOS 16.0, *)
struct DoseySummaryIntent: AppIntent {
  static var title: LocalizedStringResource = "Ask Velouria"
  static var description = IntentDescription(
    "Ask Velouria what medication doses are taken, missed, or next."
  )
  static var openAppWhenRun = false

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let defaults = AppDelegate.summaryDefaults
    let taken = defaults.integer(forKey: AppDelegate.dailySummaryTakenDosesKey)
    let remaining = defaults.integer(forKey: AppDelegate.dailySummaryRemainingDosesKey)
    let total = max(
      defaults.integer(forKey: AppDelegate.dailySummaryTotalDosesTodayKey),
      taken + remaining
    )
    let completed = min(
      max(defaults.integer(forKey: AppDelegate.dailySummaryCompletedDosesTodayKey), taken),
      max(total, 1)
    )
    let nextName = defaults.string(forKey: AppDelegate.dailySummaryNextDoseMedicationNameKey) ?? ""
    let nextMs = defaults.integer(forKey: AppDelegate.dailySummaryNextDoseEpochMsKey)

    let progress = total > 0 ? "\(completed) of \(total)" : "no scheduled"
    let nextText: String
    if nextMs > 0 && !nextName.isEmpty {
      let date = Date(timeIntervalSince1970: TimeInterval(nextMs) / 1000.0)
      let formatter = DateFormatter()
      formatter.dateStyle = .none
      formatter.timeStyle = .short
      nextText = "Next dose is \(nextName) at \(formatter.string(from: date))."
    } else {
      nextText = "No next dose is listed."
    }

    let dialog = "Velouria: \(progress) doses confirmed today. \(remaining) awaiting confirmation. \(nextText)"
    return .result(dialog: IntentDialog(stringLiteral: dialog))
  }
}

@available(iOS 16.0, *)
struct DoseyOpenTodayIntent: AppIntent {
  static var title: LocalizedStringResource = "Open Velouria Today"
  static var openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    AppDelegate.summaryDefaults.set("today", forKey: AppDelegate.pendingSiriNavigationKey)
    return .result()
  }
}

@available(iOS 16.0, *)
struct DoseyShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: DoseySummaryIntent(),
      phrases: [
        "Ask \(.applicationName) what meds are left",
        "Ask \(.applicationName) did I take my pill",
        "\(.applicationName) check in"
      ],
      shortTitle: "Medication check-in",
      systemImageName: "pills.fill"
    )
    AppShortcut(
      intent: DoseyOpenTodayIntent(),
      phrases: [
        "Open \(.applicationName) today",
        "Show my \(.applicationName) doses"
      ],
      shortTitle: "Open today",
      systemImageName: "heart.text.square.fill"
    )
  }
}
