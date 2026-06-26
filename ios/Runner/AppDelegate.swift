import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    registerWidgetChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func registerWidgetChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(
      name: "com.course.manager/widget",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "updateWidget":
        if let args = call.arguments as? [String: Any],
           let jsonString = args["data"] as? String {
          self?.saveWidgetData(jsonString)
          WidgetData.reloadAllTimelines()
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing data", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func saveWidgetData(_ json: String) {
    let defaults = WidgetData.sharedDefaults()
    defaults.set(json, forKey: "widget_data")
    defaults.synchronize()
  }
}

struct WidgetData {
  static let appGroup = "group.com.course.manager"

  static func sharedDefaults() -> UserDefaults {
    return UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
  }

  static func loadWidgetData() -> [String: Any]? {
    guard let json = sharedDefaults().string(forKey: "widget_data"),
          let data = json.data(using: .utf8) else { return nil }
    return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
  }

  static func reloadAllTimelines() {
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }
}
