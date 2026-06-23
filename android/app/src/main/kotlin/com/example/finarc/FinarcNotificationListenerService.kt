package com.yashsharma.finarc

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class FinarcNotificationListenerService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        if (sbn.packageName == packageName) return
        if (NotificationCapturePolicy.shouldIgnorePackage(sbn.packageName)) return

        val notification = sbn.notification ?: return
        if (shouldIgnoreNotification(sbn, notification)) return

        val extras = notification.extras
        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim().orEmpty()
        val body = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim().orEmpty()
        val bigText = extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim().orEmpty()
        val subText = extras?.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()?.trim().orEmpty()
        val textLines = extras
            ?.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
            ?.mapNotNull { it?.toString()?.trim() }
            ?.filter { it.isNotBlank() }
            .orEmpty()
        val expandedText = listOf(bigText, textLines.joinToString(" "))
            .filter { it.isNotBlank() }
            .distinct()
            .joinToString(" ")

        if (title.isBlank() && body.isBlank() && expandedText.isBlank()) return
        val likelyFinancial = NotificationCapturePolicy.isLikelyFinancialContent(
            title = title,
            body = body,
            bigText = expandedText,
            subText = subText,
        )
        if (!likelyFinancial && !NotificationBridge.hasActiveSink()) return

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
            "bigText" to if (expandedText.isBlank()) null else expandedText,
            "subText" to if (subText.isBlank()) null else subText,
            "receivedAt" to sbn.postTime,
            "postTime" to sbn.postTime,
            "sourceType" to "appNotification",
            "isOngoing" to sbn.isOngoing,
            "category" to notification.category,
        )

        val deliveredToFlutter = NotificationBridge.publish(applicationContext, payload)
        if (!deliveredToFlutter && likelyFinancial) {
            BackgroundNotificationHelper.showCapturedTransactionNotification(
                context = applicationContext,
            )
        }
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
