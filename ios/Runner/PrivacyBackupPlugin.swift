import Flutter
import Foundation

final class PrivacyBackupPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.camperboss/privacy",
      binaryMessenger: registrar.messenger()
    )
    let instance = PrivacyBackupPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "excludeFromBackup" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let args = call.arguments as? [String: Any],
      let path = args["path"] as? String,
      !path.isEmpty
    else {
      result(
        FlutterError(
          code: "invalid_path",
          message: "A non-empty file path is required.",
          details: nil
        )
      )
      return
    }

    do {
      var url = URL(fileURLWithPath: path)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try url.setResourceValues(values)
      result(nil)
    } catch {
      result(
        FlutterError(
          code: "exclude_backup_failed",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }
}
