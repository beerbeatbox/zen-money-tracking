import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let widgetChannel = FlutterMethodChannel(
        name: "com.dopaminelab.thumby/widget",
        binaryMessenger: controller.binaryMessenger
      )

      widgetChannel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "updateTodaySpending":
          guard let args = call.arguments as? [String: Any] else {
            result(
              FlutterError(
                code: "INVALID_ARGS",
                message: "Invalid arguments for today spending update",
                details: nil
              )
            )
            return
          }
          let amount = args["amount"] as? Double
          let hasBudgetKey = args.keys.contains("budgetRemaining")
          let budgetRemaining = hasBudgetKey ? (args["budgetRemaining"] as? Double) : nil
          self?.saveTodaySpending(amount: amount, budgetRemaining: budgetRemaining, shouldUpdateBudget: hasBudgetKey)
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveTodaySpending(amount: Double?, budgetRemaining: Double?, shouldUpdateBudget: Bool) {
    let appGroupId = "group.com.dopaminelab.thumby"
    let amountKey = "today_spending_amount"
    let updatedAtKey = "today_spending_updated_at"
    let budgetRemainingKey = "today_budget_remaining"
    let budgetUpdatedAtKey = "today_budget_updated_at"

    guard let defaults = UserDefaults(suiteName: appGroupId) else {
      return
    }

    // Update spending amount if provided
    if let amount = amount {
      defaults.set(amount, forKey: amountKey)
      defaults.set(Date().timeIntervalSince1970, forKey: updatedAtKey)
    }

    // Update budget if the key was present in args
    if shouldUpdateBudget {
      if let budgetRemaining = budgetRemaining {
        defaults.set(budgetRemaining, forKey: budgetRemainingKey)
        defaults.set(Date().timeIntervalSince1970, forKey: budgetUpdatedAtKey)
      } else {
        // Explicitly nil means clear the budget
        defaults.removeObject(forKey: budgetRemainingKey)
        defaults.removeObject(forKey: budgetUpdatedAtKey)
      }
    }

    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadTimelines(ofKind: "ThumbySpending")
    }
  }
}
