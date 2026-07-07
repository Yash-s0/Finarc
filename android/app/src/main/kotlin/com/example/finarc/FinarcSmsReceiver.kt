package com.yashsharma.finarc

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.telephony.SmsMessage
import android.util.Log

class FinarcSmsReceiver : BroadcastReceiver() {
    companion object {
        const val DIAGNOSTICS_PREFS = "finarc_sms_diagnostics"
        const val KEY_LAST_RECEIVED_AT_MILLIS = "last_received_at_millis"
        const val KEY_LAST_SENDER = "last_sender"
        const val KEY_LAST_CALLBACK_SUCCESS_AT_MILLIS = "last_callback_success_at_millis"
        const val KEY_LAST_ERROR = "last_error"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent == null || intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val appContext = context?.applicationContext ?: return

        try {
            val messages: Array<SmsMessage> = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages.isEmpty()) return

            val sender = messages.firstOrNull()?.displayOriginatingAddress?.trim().orEmpty()
            val body = buildString {
                messages.forEach { sms ->
                    append(sms.displayMessageBody.orEmpty())
                }
            }.trim()
            if (body.isBlank()) return

            val receivedAt = System.currentTimeMillis()
            val payload = mapOf(
                "packageName" to "android.sms",
                "appName" to "SMS",
                "sender" to sender,
                "title" to sender,
                "body" to body,
                "bigText" to null,
                "subText" to null,
                "receivedAt" to receivedAt,
                "sourceType" to "sms",
                "isOngoing" to false,
                "category" to "sms",
            )
            NotificationBridge.publish(appContext, payload)
            persistDiagnostics(appContext, receivedAt, sender, null)
            Log.d("FinarcSmsReceiver", "SMS_RECEIVED sender=$sender bodyLen=${body.length}")
        } catch (t: Throwable) {
            persistDiagnostics(appContext, System.currentTimeMillis(), null, t.message ?: t.javaClass.simpleName)
            Log.e("FinarcSmsReceiver", "Failed to process SMS broadcast", t)
        }
    }

    private fun persistDiagnostics(
        context: Context,
        receivedAtMillis: Long,
        sender: String?,
        error: String?,
    ) {
        context.getSharedPreferences(DIAGNOSTICS_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putLong(KEY_LAST_RECEIVED_AT_MILLIS, receivedAtMillis)
            .putLong(KEY_LAST_CALLBACK_SUCCESS_AT_MILLIS, if (error == null) receivedAtMillis else 0L)
            .putString(KEY_LAST_SENDER, sender)
            .putString(KEY_LAST_ERROR, error)
            .apply()
    }
}
