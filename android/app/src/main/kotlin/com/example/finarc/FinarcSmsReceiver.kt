package com.example.finarc

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.telephony.SmsMessage

class FinarcSmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent == null || intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val bundle = intent.extras ?: return

        val pdus = bundle.get("pdus") as? Array<*> ?: return
        val format = bundle.getString("format")
        val receivedAt = System.currentTimeMillis()

        for (pdu in pdus) {
            val bytes = pdu as? ByteArray ?: continue
            val message = if (format != null) {
                SmsMessage.createFromPdu(bytes, format)
            } else {
                @Suppress("DEPRECATION")
                SmsMessage.createFromPdu(bytes)
            }

            val sender = message.displayOriginatingAddress?.trim().orEmpty()
            val body = message.displayMessageBody?.trim().orEmpty()
            if (body.isBlank()) continue

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
            NotificationBridge.publish(payload)
        }
    }
}
