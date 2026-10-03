import Flutter
import Foundation

final class PrivacyBackupPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.camperboss/privacy",
      binaryMessenger: registrar.messenger()
    )
    let storageChannel = FlutterMethodChannel(
      name: "com.camperboss/device_storage",
      binaryMessenger: registrar.messenger()
    )
    let instance = PrivacyBackupPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addMethodCallDelegate(instance, channel: storageChannel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "storageStats" {
      handleStorageStats(result: result)
      return
    }

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

  private func handleStorageStats(result: @escaping FlutterResult) {
    do {
      let baseURL =
        FileManager.default.urls(
          for: .applicationSupportDirectory,
          in: .userDomainMask
        ).first ??
        FileManager.default.urls(
          for: .documentDirectory,
          in: .userDomainMask
        ).first

      guard let baseURL else {
        result(
          FlutterError(
            code: "storage_stats_unavailable",
            message: "Application storage URL is unavailable.",
            details: nil
          )
        )
        return
      }

      let values = try baseURL.resourceValues(
        forKeys: [
          .volumeAvailableCapacityForImportantUsageKey,
          .volumeTotalCapacityKey,
        ]
      )
      guard
        let freeBytes = values.volumeAvailableCapacityForImportantUsage,
        let totalBytes = values.volumeTotalCapacity
      else {
        result(
          FlutterError(
            code: "storage_stats_unavailable",
            message: "Volume capacity is unavailable.",
            details: nil
          )
        )
        return
      }

      result([
        "totalBytes": Int64(totalBytes),
        "freeBytes": Int64(freeBytes),
      ])
    } catch {
      result(
        FlutterError(
          code: "storage_stats_failed",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }
}
