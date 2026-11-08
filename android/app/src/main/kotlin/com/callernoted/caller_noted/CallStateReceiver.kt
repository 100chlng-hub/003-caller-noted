package com.callernoted.caller_noted

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telephony.TelephonyManager
import androidx.core.app.NotificationCompat

class CallStateReceiver : BroadcastReceiver() {

    companion object {
        private var lastState = TelephonyManager.CALL_STATE_IDLE
        private var callStartTime: Long = 0
        private var savedNumber: String? = null
        private const val CHANNEL_ID = "call_ended_channel"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val stateStr = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
            if (!number.isNullOrEmpty()) {
                savedNumber = number
            }

            var state = TelephonyManager.CALL_STATE_IDLE
            if (stateStr == TelephonyManager.EXTRA_STATE_OFFHOOK) {
                state = TelephonyManager.CALL_STATE_OFFHOOK
            } else if (stateStr == TelephonyManager.EXTRA_STATE_RINGING) {
                state = TelephonyManager.CALL_STATE_RINGING
            }

            onCallStateChanged(context, state, savedNumber)
        }
    }

    private fun onCallStateChanged(context: Context, state: Int, number: String?) {
        if (lastState == state) {
            return
        }

        when (state) {
            TelephonyManager.CALL_STATE_RINGING -> {
                // Incoming call ringing
            }
            TelephonyManager.CALL_STATE_OFFHOOK -> {
                // Call answered / started
                callStartTime = System.currentTimeMillis()
            }
            TelephonyManager.CALL_STATE_IDLE -> {
                // Call ended
                if (lastState == TelephonyManager.CALL_STATE_OFFHOOK) {
                    val durationSeconds = ((System.currentTimeMillis() - callStartTime) / 1000).toInt()
                    
                    // Filter: only trigger if call duration >= 10 seconds (avoids missed/wrong calls)
                    if (durationSeconds >= 10 && !number.isNullOrEmpty()) {
                        showCallEndedNotification(context, number, durationSeconds)
                    }
                }
            }
        }
        lastState = state
    }

    private fun showCallEndedNotification(context: Context, phoneNumber: String, duration: Int) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Chiamate Terminate",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Suggerisce la creazione di un evento a calendario"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("phoneNumber", phoneNumber)
            putExtra("durationSeconds", duration)
            putExtra("action", "create_event")
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            1001,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_agenda)
            .setContentTitle("Chiamata terminata con $phoneNumber")
            .setContentText("Tocca per creare subito un appuntamento a calendario")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .addAction(
                android.R.drawable.ic_btn_speak_now,
                "🎙️ Crea con Voce",
                pendingIntent
            )
            .build()

        notificationManager.notify(1001, notification)
    }
}
