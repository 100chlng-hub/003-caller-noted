package com.callernoted.caller_noted

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.callernoted.app/call_events"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        intent?.let {
            val phone = it.getStringExtra("phoneNumber")
            val action = it.getStringExtra("action")
            if (phone != null && action == "create_event") {
                methodChannel?.invokeMethod("onCallEndedNotificationClicked", mapOf(
                    "phoneNumber" to phone,
                    "durationSeconds" to it.getIntExtra("durationSeconds", 0)
                ))
            }
        }
    }
}
