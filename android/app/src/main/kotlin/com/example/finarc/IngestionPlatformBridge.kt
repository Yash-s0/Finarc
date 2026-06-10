package com.yashsharma.finarc

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

interface IngestionPlatformBridge {
    fun isIngestionAvailable(): Boolean
    fun isPermissionGranted(): Boolean
    fun isReadPermissionGranted(): Boolean
    fun isReceivePermissionGranted(): Boolean
    fun shouldShowPermissionRationale(): Boolean
    fun isReceiverComponentAvailable(): Boolean
    fun isReceiverComponentEnabled(): Boolean
    fun getReceiverDiagnostics(): Map<String, Any?>
    fun requestPermission(result: MethodChannel.Result)
    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result): Boolean
    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean
}

private class NoOpIngestionPlatformBridge : IngestionPlatformBridge {
    override fun isIngestionAvailable(): Boolean = false

    override fun isPermissionGranted(): Boolean = false

    override fun isReadPermissionGranted(): Boolean = false

    override fun isReceivePermissionGranted(): Boolean = false

    override fun shouldShowPermissionRationale(): Boolean = false

    override fun isReceiverComponentAvailable(): Boolean = false

    override fun isReceiverComponentEnabled(): Boolean = false

    override fun getReceiverDiagnostics(): Map<String, Any?> = emptyMap()

    override fun requestPermission(result: MethodChannel.Result) {
        result.success(false)
    }

    override fun handleMethodCall(call: MethodCall, result: MethodChannel.Result): Boolean = false

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean = false
}

fun createIngestionPlatformBridge(activity: FlutterActivity): IngestionPlatformBridge {
    return try {
        val clazz = Class.forName("com.yashsharma.finarc.PersonalDebugIngestionPlatformBridge")
        val ctor = clazz.getConstructor(FlutterActivity::class.java)
        ctor.newInstance(activity) as IngestionPlatformBridge
    } catch (_: Throwable) {
        NoOpIngestionPlatformBridge()
    }
}
