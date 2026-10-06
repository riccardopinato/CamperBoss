import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate {
  private var backupExportChannel: FlutterMethodChannel?
  private var pendingBackupExport: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "PrivacyBackupPlugin"
    ) {
      PrivacyBackupPlugin.register(with: registrar)
    }

    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "BackupFileExportPlugin"
    ) {
      let channel = FlutterMethodChannel(
        name: "com.camperboss/file_export",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "exportFile" else {
          result(FlutterMethodNotImplemented)
          return
        }
        self?.beginBackupExport(call: call, result: result)
      }
      backupExportChannel = channel
    }
  }

  private func beginBackupExport(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard pendingBackupExport == nil else {
      result(
        FlutterError(
          code: "export_busy",
          message: "Another backup export is already active",
          details: nil
        )
      )
      return
    }

    guard
      let arguments = call.arguments as? [String: Any],
      let sourcePath = arguments["sourcePath"] as? String,
      !sourcePath.isEmpty
    else {
      result(
        FlutterError(
          code: "export_invalid_arguments",
          message: "sourcePath is required",
          details: nil
        )
      )
      return
    }

    let sourceURL = URL(fileURLWithPath: sourcePath)
    guard FileManager.default.fileExists(atPath: sourceURL.path) else {
      result(
        FlutterError(
          code: "export_source_missing",
          message: "Backup source file does not exist",
          details: nil
        )
      )
      return
    }

    guard let presenter = topViewController() else {
      result(
        FlutterError(
          code: "export_picker_failed",
          message: "Unable to present the document picker",
          details: nil
        )
      )
      return
    }

    pendingBackupExport = result
    let picker = UIDocumentPickerViewController(
      forExporting: [sourceURL],
      asCopy: true
    )
    picker.delegate = self
    presenter.present(picker, animated: true)
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    let result = pendingBackupExport
    pendingBackupExport = nil
    result?(urls.first?.absoluteString)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let result = pendingBackupExport
    pendingBackupExport = nil
    result?(nil)
  }

  private func topViewController() -> UIViewController? {
    var current = window?.rootViewController
    while let presented = current?.presentedViewController {
      current = presented
    }
    return current
  }
}
