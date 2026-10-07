package com.camperboss.camperboss

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val exportRequestCode = 43021
    private val notificationPermissionRequestCode = 43022
    private var pendingExport: PendingExport? = null
    private var pendingNotificationPermission: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.camperboss/device_storage",
        ).setMethodCallHandler { call, result ->
            if (call.method != "storageStats") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                val stats = StatFs(filesDir.absolutePath)
                result.success(
                    mapOf(
                        "totalBytes" to stats.totalBytes,
                        "freeBytes" to stats.availableBytes,
                    ),
                )
            } catch (error: Exception) {
                result.error(
                    "storage_stats_failed",
                    error.message ?: "Unable to read storage capacity",
                    null,
                )
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.camperboss/notification_permission",
        ).setMethodCallHandler { call, result ->
            if (call.method != "request") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                result.success(true)
                return@setMethodCallHandler
            }

            if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
            ) {
                result.success(true)
                return@setMethodCallHandler
            }

            if (pendingNotificationPermission != null) {
                result.error(
                    "notification_permission_busy",
                    "Notification permission request already active",
                    null,
                )
                return@setMethodCallHandler
            }

            pendingNotificationPermission = result
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                notificationPermissionRequestCode,
            )
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.camperboss/file_export",
        ).setMethodCallHandler { call, result ->
            if (call.method != "exportFile") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            if (pendingExport != null) {
                result.error(
                    "export_busy",
                    "Another backup export is already active",
                    null,
                )
                return@setMethodCallHandler
            }

            val sourcePath = call.argument<String>("sourcePath")
            val fileName = call.argument<String>("fileName")
            val mimeType =
                call.argument<String>("mimeType") ?: "application/zip"

            if (sourcePath.isNullOrBlank() || fileName.isNullOrBlank()) {
                result.error(
                    "export_invalid_arguments",
                    "sourcePath and fileName are required",
                    null,
                )
                return@setMethodCallHandler
            }

            val source = File(sourcePath)
            if (!source.isFile) {
                result.error(
                    "export_source_missing",
                    "Backup source file does not exist",
                    null,
                )
                return@setMethodCallHandler
            }

            pendingExport = PendingExport(sourcePath, result)
            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = mimeType
                putExtra(Intent.EXTRA_TITLE, fileName)
            }
            try {
                startActivityForResult(intent, exportRequestCode)
            } catch (error: Exception) {
                pendingExport = null
                result.error(
                    "export_picker_failed",
                    error.message ?: "Unable to open the document picker",
                    null,
                )
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != notificationPermissionRequestCode) return

        val pending = pendingNotificationPermission ?: return
        pendingNotificationPermission = null
        pending.success(
            grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED,
        )
    }

    @Deprecated("Deprecated in Android SDK; retained for document picker interoperability.")
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != exportRequestCode) return

        val pending = pendingExport ?: return
        pendingExport = null

        if (resultCode != Activity.RESULT_OK) {
            pending.result.success(null)
            return
        }

        val destination = data?.data
        if (destination == null) {
            pending.result.error(
                "export_destination_missing",
                "The document picker returned no destination",
                null,
            )
            return
        }

        Thread {
            try {
                FileInputStream(File(pending.sourcePath)).use { input ->
                    val output = contentResolver.openOutputStream(destination, "w")
                        ?: throw IllegalStateException(
                            "Unable to open the selected destination",
                        )
                    output.use {
                        input.copyTo(it, bufferSize = 64 * 1024)
                        it.flush()
                    }
                }
                runOnUiThread {
                    pending.result.success(destination.toString())
                }
            } catch (error: Exception) {
                runOnUiThread {
                    pending.result.error(
                        "export_write_failed",
                        error.message ?: "Unable to save the backup",
                        null,
                    )
                }
            }
        }.start()
    }

    private data class PendingExport(
        val sourcePath: String,
        val result: MethodChannel.Result,
    )
}
