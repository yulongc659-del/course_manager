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
    channel.setMethodCallHandler { (call, result) in
      if call.method == "updateWidget",
         let args = call.arguments as? [String: Any],
         let json = args["data"] as? String {
        let defaults = UserDefaults(suiteName: "group.com.course.manager") ?? UserDefaults.standard
        defaults.set(json, forKey: "widget_data")
        defaults.synchronize()
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
      }
    }
  }
}
