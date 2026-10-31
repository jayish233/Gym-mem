import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Lets the Scan screen send the member to Settings after a camera denial.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PresenceSettings") {
      FlutterMethodChannel(name: "presence/settings", binaryMessenger: registrar.messenger())
        .setMethodCallHandler { _, result in
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
          result(nil)
        }
    }
  }
}
