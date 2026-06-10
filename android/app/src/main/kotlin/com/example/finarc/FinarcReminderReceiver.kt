package com.yashsharma.finarc

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class FinarcReminderReceiver : BroadcastReceiver() {
    companion object {
        private const val REMINDER_CHANNEL_ID = "finarc_reminders"
        private const val REMINDER_CHANNEL_NAME = "Finarc Reminders"
        private const val EXTRA_ROUTE = "finarc_route"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null) return
        createChannelIfNeeded(context)

        val reminderId = intent.getIntExtra("reminder_id", (System.currentTimeMillis() % Int.MAX_VALUE).toInt())
        val title = intent.getStringExtra("title") ?: "Finarc Reminder"
        val body = intent.getStringExtra("body") ?: "Open Finarc to review updates."
        val route = intent.getStringExtra(EXTRA_ROUTE) ?: "/"

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_ROUTE, route)
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            reminderId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, REMINDER_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .build()

        NotificationManagerCompat.from(context).notify(reminderId, notification)
    }

    private fun createChannelIfNeeded(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            REMINDER_CHANNEL_ID,
            REMINDER_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Finance reminders from Finarc"
        }
        manager.createNotificationChannel(channel)
    }
}
