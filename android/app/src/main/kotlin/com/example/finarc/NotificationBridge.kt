package com.yashsharma.finarc

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

object NotificationBridge {
    private const val PREFS_NAME = "finarc_notification_bridge"
    private const val PREFS_KEY_PENDING_EVENTS = "pending_events"
    private const val PREFS_KEY_SMS_DETECTION_ENABLED = "sms_detection_enabled"
    private const val PREFS_KEY_NOTIFICATION_DETECTION_ENABLED = "notification_detection_enabled"
    private const val MAX_PERSISTED_EVENTS = 256

    @Volatile
    private var sinkRef: ((Map<String, Any?>) -> Unit)? = null

    @Synchronized
    fun publish(context: Context, payload: Map<String, Any?>): Boolean {
        val packageName = payload["packageName"] as? String
        if (NotificationCapturePolicy.shouldIgnorePackage(packageName)) {
            return false
        }
        persistPayload(context.applicationContext, payload)
        val sink = sinkRef ?: return false
        sink(payload)
        return true
    }

    @Synchronized
    fun publish(payload: Map<String, Any?>): Boolean {
        val packageName = payload["packageName"] as? String
        if (NotificationCapturePolicy.shouldIgnorePackage(packageName)) {
            return false
        }
        val sink = sinkRef
        if (sink != null) {
            sink(payload)
            return true
        }
        return false
    }

    @Synchronized
    fun setEventSink(context: Context, sink: ((Map<String, Any?>) -> Unit)?) {
        sinkRef = sink
    }

    @Synchronized
    fun drainQueue(context: Context): List<Map<String, Any?>> {
        return persistedQueue(context.applicationContext)
    }

    @Synchronized
    fun acknowledgeQueue(context: Context, eventIds: List<String>) {
        if (eventIds.isEmpty()) return
        val remaining = persistedQueue(context.applicationContext).filterNot {
            (it["nativeEventId"] as? String) in eventIds
        }
        writeQueue(context.applicationContext, remaining)
    }

    fun isSmsDetectionEnabled(context: Context): Boolean =
        sharedPreferences(context.applicationContext).getBoolean(PREFS_KEY_SMS_DETECTION_ENABLED, false)

    fun isNotificationDetectionEnabled(context: Context): Boolean =
        sharedPreferences(context.applicationContext).getBoolean(PREFS_KEY_NOTIFICATION_DETECTION_ENABLED, false)

    fun setDetectionSettings(context: Context, smsEnabled: Boolean, notificationEnabled: Boolean) {
        sharedPreferences(context.applicationContext).edit()
            .putBoolean(PREFS_KEY_SMS_DETECTION_ENABLED, smsEnabled)
            .putBoolean(PREFS_KEY_NOTIFICATION_DETECTION_ENABLED, notificationEnabled)
            .apply()
    }

    @Synchronized
    fun hasActiveSink(): Boolean = sinkRef != null

    private fun persistPayload(context: Context, payload: Map<String, Any?>) {
        val prefs = sharedPreferences(context)
        val queue = JSONArray(prefs.getString(PREFS_KEY_PENDING_EVENTS, "[]"))
        val event = payload.toMutableMap()
        event["nativeEventId"] = event["nativeEventId"] ?: eventId(event)
        val eventId = event["nativeEventId"] as String
        for (index in 0 until queue.length()) {
            if (queue.optJSONObject(index)?.optString("nativeEventId") == eventId) return
        }
        queue.put(mapToJson(event))

        val trimmed = JSONArray()
        val startIndex = maxOf(0, queue.length() - MAX_PERSISTED_EVENTS)
        for (index in startIndex until queue.length()) {
            trimmed.put(queue.get(index))
        }

        prefs.edit().putString(PREFS_KEY_PENDING_EVENTS, trimmed.toString()).apply()
    }

    private fun persistedQueue(context: Context): List<Map<String, Any?>> {
        val prefs = sharedPreferences(context)
        val raw = prefs.getString(PREFS_KEY_PENDING_EVENTS, "[]") ?: "[]"
        val queue = JSONArray(raw)
        val drained = mutableListOf<Map<String, Any?>>()
        for (index in 0 until queue.length()) {
            val item = queue.optJSONObject(index) ?: continue
            drained += jsonToMap(item)
        }
        return drained
    }

    private fun writeQueue(context: Context, payloads: List<Map<String, Any?>>) {
        val queue = JSONArray()
        payloads.forEach { queue.put(mapToJson(it)) }
        sharedPreferences(context).edit().putString(PREFS_KEY_PENDING_EVENTS, queue.toString()).apply()
    }

    private fun eventId(payload: Map<String, Any?>): String = listOf(
        payload["sourceType"], payload["packageName"], payload["sender"], payload["title"],
        payload["body"], payload["receivedAt"],
    ).joinToString("|").hashCode().toString()

    private fun mapToJson(payload: Map<String, Any?>): JSONObject {
        val json = JSONObject()
        payload.forEach { (key, value) ->
            json.put(key, value ?: JSONObject.NULL)
        }
        return json
    }

    private fun jsonToMap(json: JSONObject): Map<String, Any?> {
        val map = linkedMapOf<String, Any?>()
        val keys = json.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val value = json.get(key)
            map[key] = if (value == JSONObject.NULL) null else value
        }
        return map
    }

    private fun sharedPreferences(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
}
