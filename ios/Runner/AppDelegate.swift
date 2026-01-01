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
          guard
            let args = call.arguments as? [String: Any],
            let amount = args["amount"] as? Double
          else {
            result(
              FlutterError(
                code: "INVALID_ARGS",
                message: "Missing amount for today spending update",
                details: nil
              )
            )
            return
          }
          self?.saveTodaySpending(amount: amount)
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveTodaySpending(amount: Double) {
    let appGroupId = "group.com.dopaminelab.thumby"
    let amountKey = "today_spending_amount"
    let updatedAtKey = "today_spending_updated_at"

    guard let defaults = UserDefaults(suiteName: appGroupId) else {
      return
    }

    defaults.set(amount, forKey: amountKey)
    defaults.set(Date().timeIntervalSince1970, forKey: updatedAtKey)

    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadTimelines(ofKind: "ThumbySpending")
    }
  }
}
