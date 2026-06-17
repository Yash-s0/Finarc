package com.yashsharma.finarc

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

object NotificationBridge {
    private const val PREFS_NAME = "finarc_notification_bridge"
    private const val PREFS_KEY_PENDING_EVENTS = "pending_events"
    private const val MAX_PERSISTED_EVENTS = 64

    @Volatile
    private var sinkRef: ((Map<String, Any?>) -> Unit)? = null

    @Synchronized
    fun publish(context: Context, payload: Map<String, Any?>): Boolean {
        val packageName = payload["packageName"] as? String
        if (NotificationCapturePolicy.shouldIgnorePackage(packageName)) {
            return false
        }
        val sink = sinkRef
        if (sink != null) {
            sink(payload)
            return true
        }
        persistPayload(context.applicationContext, payload)
        return false
    }

    @Synchronized
    fun setEventSink(context: Context, sink: ((Map<String, Any?>) -> Unit)?) {
        sinkRef = sink
        if (sink != null) {
            drainPersistedQueue(context.applicationContext).forEach(sink)
        }
    }

    @Synchronized
    fun drainQueue(context: Context): List<Map<String, Any?>> {
        return drainPersistedQueue(context.applicationContext)
    }

    @Synchronized
    fun hasActiveSink(): Boolean = sinkRef != null

    private fun persistPayload(context: Context, payload: Map<String, Any?>) {
        val prefs = sharedPreferences(context)
        val queue = JSONArray(prefs.getString(PREFS_KEY_PENDING_EVENTS, "[]"))
        queue.put(mapToJson(payload))

        val trimmed = JSONArray()
        val startIndex = maxOf(0, queue.length() - MAX_PERSISTED_EVENTS)
        for (index in startIndex until queue.length()) {
            trimmed.put(queue.get(index))
        }

        prefs.edit().putString(PREFS_KEY_PENDING_EVENTS, trimmed.toString()).apply()
    }

    private fun drainPersistedQueue(context: Context): List<Map<String, Any?>> {
        val prefs = sharedPreferences(context)
        val raw = prefs.getString(PREFS_KEY_PENDING_EVENTS, "[]") ?: "[]"
        prefs.edit().remove(PREFS_KEY_PENDING_EVENTS).apply()

        val queue = JSONArray(raw)
        val drained = mutableListOf<Map<String, Any?>>()
        for (index in 0 until queue.length()) {
            val item = queue.optJSONObject(index) ?: continue
            drained += jsonToMap(item)
        }
        return drained
    }

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
