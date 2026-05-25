package com.example.finarc

import java.util.concurrent.ConcurrentLinkedQueue

object NotificationBridge {
    private val queue: ConcurrentLinkedQueue<Map<String, Any?>> = ConcurrentLinkedQueue()

    @Volatile
    private var sinkRef: ((Map<String, Any?>) -> Unit)? = null

    @Synchronized
    fun publish(payload: Map<String, Any?>) {
        queue.add(payload)
        sinkRef?.invoke(payload)
    }

    @Synchronized
    fun setEventSink(sink: ((Map<String, Any?>) -> Unit)?) {
        sinkRef = sink
        if (sink != null) {
            while (true) {
                val item = queue.poll() ?: break
                sink(item)
            }
        }
    }

    @Synchronized
    fun drainQueue(): List<Map<String, Any?>> {
        val drained = mutableListOf<Map<String, Any?>>()
        while (true) {
            val item = queue.poll() ?: break
            drained.add(item)
        }
        return drained
    }
}
