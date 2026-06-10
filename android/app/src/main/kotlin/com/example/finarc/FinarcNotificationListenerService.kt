package com.yashsharma.finarc

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class FinarcNotificationListenerService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        if (sbn.packageName == packageName) return

        val notification = sbn.notification ?: return
        if (shouldIgnoreNotification(sbn, notification)) return

        val extras = notification.extras
        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim().orEmpty()
        val body = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim().orEmpty()
        val bigText = extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim().orEmpty()
        val subText = extras?.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()?.trim().orEmpty()

        if (title.isBlank() && body.isBlank() && bigText.isBlank()) return

        val appName = try {
            val info = packageManager.getApplicationInfo(sbn.packageName, 0)
            packageManager.getApplicationLabel(info).toString()
        } catch (_: Exception) {
            null
        }

        val payload = mapOf(
            "packageName" to sbn.packageName,
            "appName" to appName,
            "title" to title,
            "body" to body,
            "bigText" to if (bigText.isBlank()) null else bigText,
            "subText" to if (subText.isBlank()) null else subText,
            "receivedAt" to sbn.postTime,
            "postTime" to sbn.postTime,
            "sourceType" to "appNotification",
            "isOngoing" to sbn.isOngoing,
            "category" to notification.category,
        )

        NotificationBridge.publish(payload)
    }

    private fun shouldIgnoreNotification(
        sbn: StatusBarNotification,
        notification: Notification,
    ): Boolean {
        if (sbn.isOngoing) return true

        val flags = notification.flags
        if ((flags and Notification.FLAG_ONGOING_EVENT) != 0) return true
        if ((flags and Notification.FLAG_FOREGROUND_SERVICE) != 0) return true

        val category = notification.category.orEmpty()
        if (category == Notification.CATEGORY_TRANSPORT || category == Notification.CATEGORY_SYSTEM) {
            return true
        }

        return false
    }
}
