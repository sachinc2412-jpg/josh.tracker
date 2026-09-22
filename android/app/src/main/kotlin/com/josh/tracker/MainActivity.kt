package com.josh.tracker

import android.Manifest
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ReminderEngine.createChannel(this)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.josh.tracker/reminders")
        channel?.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "status" -> result.success(ReminderEngine.allowed(this))
                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT >= 33 && !ReminderEngine.allowed(this)) {
                            if (permissionResult != null) result.error("busy", "Permission request in progress", null)
                            else {
                                permissionResult = result
                                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 401)
                            }
                        } else result.success(ReminderEngine.allowed(this))
                    }
                    "configure" -> {
                        ReminderEngine.configure(this, call.arguments as String)
                        result.success(null)
                    }
                    "snooze" -> result.success(ReminderEngine.snooze(this, call.arguments as String))
                    "launchHabit" -> {
                        result.success(intent.getStringExtra("habit"))
                        intent.removeExtra("habit")
                    }
                    "settings" -> {
                        val i = if (Build.VERSION.SDK_INT >= 26) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, android.net.Uri.parse("package:$packageName"))
                        }
                        startActivity(i)
                        result.success(null)
                    }
                    "test" -> {
                        ReminderEngine.notify(this, "test", "A gentle nudge", "Your reminders are ready. A little better, every day.", false)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("reminders", e.message, null)
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 401) {
            permissionResult?.success(ReminderEngine.allowed(this))
            permissionResult = null
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val habit = intent.getStringExtra("habit")
        if (habit != null) channel?.invokeMethod("openHabit", habit)
        intent.removeExtra("habit")
    }
}
