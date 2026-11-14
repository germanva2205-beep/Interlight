package com.helpme.help_me

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingListen = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingListen = intent?.getBooleanExtra(EXTRA_LISTEN, false) == true
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hm/native")
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeLaunch" -> {
                    val v = pendingListen
                    pendingListen = false
                    result.success(v)
                }
                "closeApp" -> {
                    result.success(null)
                    finishAndRemoveTask()
                }
                "scheduleAlarm" -> {
                    Alarms.schedule(
                        this,
                        call.argument<Int>("id")!!,
                        call.argument<Number>("millis")!!.toLong(),
                        call.argument<String>("label") ?: ""
                    )
                    result.success(null)
                }
                "cancelAlarm" -> {
                    Alarms.cancel(this, call.argument<Int>("id")!!)
                    result.success(null)
                }
                "isServiceEnabled" -> result.success(VolumeService.running)
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(EXTRA_LISTEN, false)) {
            channel?.invokeMethod("listen", null)
        }
    }

    companion object {
        const val EXTRA_LISTEN = "hm_listen"
    }
}
