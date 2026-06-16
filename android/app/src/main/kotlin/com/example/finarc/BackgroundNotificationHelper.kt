package com.yashsharma.finarc

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

object BackgroundNotificationHelper {
    private const val DETECTED_CHANNEL_ID = "finarc_detected_txn"
    private const val DETECTED_CHANNEL_NAME = "Detected Transactions"
    private const val EXTRA_ROUTE = "finarc_route"
    private const val FALLBACK_ROUTE = "/pending"
    private const val FALLBACK_NOTIFICATION_ID = 46021

    fun showCapturedTransactionNotification(
        context: Context,
        appName: String?,
        title: String,
        body: String,
    ) {
        if (!isPostNotificationsGranted(context)) return
        createChannelsIfNeeded(context)

        val previewParts = listOfNotNull(
            appName?.takeIf { it.isNotBlank() },
            title.takeIf { it.isNotBlank() },
            body.takeIf { it.isNotBlank() },
        )
        val previewText = previewParts.joinToString(" • ").ifBlank {
            "Open Finarc to review the captured transaction notification."
        }

        val notification = NotificationCompat.Builder(context, DETECTED_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Transaction notification captured")
            .setContentText(previewText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(previewText))
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(createRoutePendingIntent(context, FALLBACK_ROUTE))
            .build()

        NotificationManagerCompat.from(context).notify(FALLBACK_NOTIFICATION_ID, notification)
    }

    private fun isPostNotificationsGranted(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun createChannelsIfNeeded(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val detectedChannel = NotificationChannel(
            DETECTED_CHANNEL_ID,
            DETECTED_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Alerts for detected transaction notifications"
        }
        manager.createNotificationChannel(detectedChannel)
    }

    private fun createRoutePendingIntent(context: Context, route: String): PendingIntent {
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_ROUTE, route)
        }
        return PendingIntent.getActivity(
            context,
            route.hashCode(),
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
