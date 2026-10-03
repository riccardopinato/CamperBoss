package com.camperboss.camperboss

import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
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
    }
}
