package com.yashsharma.finarc

import android.Manifest
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Telephony
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PersonalDebugIngestionPlatformBridge(
    private val activity: FlutterActivity,
) : IngestionPlatformBridge {
    companion object {
        private const val SMS_PERMISSION_REQUEST_CODE = 7307
    }

    private var smsPermissionResult: MethodChannel.Result? = null

    override fun isIngestionAvailable(): Boolean {
        return isReceiverComponentAvailableRaw()
    }

    override fun isPermissionGranted(): Boolean {
        if (!isIngestionAvailable()) return false
        return isReadPermissionGranted() && isReceivePermissionGranted()
    }

    override fun isReadPermissionGranted(): Boolean {
        if (!isIngestionAvailable()) return false
        return ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.READ_SMS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    override fun isReceivePermissionGranted(): Boolean {
        if (!isIngestionAvailable()) return false
        return ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.RECEIVE_SMS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    override fun shouldShowPermissionRationale(): Boolean {
        if (!isIngestionAvailable()) return false
        return activity.shouldShowRequestPermissionRationale(Manifest.permission.READ_SMS) ||
            activity.shouldShowRequestPermissionRationale(Manifest.permission.RECEIVE_SMS)
    }

    override fun isReceiverComponentAvailable(): Boolean {
        if (!isIngestionAvailable()) return false
        return isReceiverComponentAvailableRaw()
    }

    override fun isReceiverComponentEnabled(): Boolean {
        if (!isIngestionAvailable()) return false
        return try {
            val component = ComponentName(activity, FinarcSmsReceiver::class.java)
            val state = activity.packageManager.getComponentEnabledSetting(component)
            state == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT ||
                state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        } catch (_: Exception) {
            false
        }
    }

    override fun getReceiverDiagnostics(): Map<String, Any?> {
        val prefs = activity.getSharedPreferences(FinarcSmsReceiver.DIAGNOSTICS_PREFS, Context.MODE_PRIVATE)
        return mapOf(
            "readSmsGranted" to isReadPermissionGranted(),
            "receiveSmsGranted" to isReceivePermissionGranted(),
            "smsPermissionGranted" to isPermissionGranted(),
            "receiverDeclared" to isReceiverComponentAvailable(),
            "receiverEnabled" to isReceiverComponentEnabled(),
            "lastReceivedAtMillis" to prefs.getLong(FinarcSmsReceiver.KEY_LAST_RECEIVED_AT_MILLIS, 0L),
            "lastSender" to prefs.getString(FinarcSmsReceiver.KEY_LAST_SENDER, null),
            "lastCallbackSuccessAtMillis" to prefs.getLong(FinarcSmsReceiver.KEY_LAST_CALLBACK_SUCCESS_AT_MILLIS, 0L),
            "lastError" to prefs.getString(FinarcSmsReceiver.KEY_LAST_ERROR, null),
            "realIngestionAvailable" to true,
        )
    }

    override fun requestPermission(result: MethodChannel.Result) {
        if (!isIngestionAvailable()) {
            result.success(false)
            return
        }
        if (isPermissionGranted()) {
            result.success(true)
            return
        }
        if (smsPermissionResult != null) {
            result.error("permission_in_progress", "SMS permission request already in progress", null)
            return
        }

        smsPermissionResult = result
        activity.requestPermissions(
            arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS),
            SMS_PERMISSION_REQUEST_CODE,
        )
    }

    private fun scanRecentSms(days: Int): Int {
        if (!isIngestionAvailable()) return 0
        if (!isPermissionGranted()) return 0

        val boundedDays = days.coerceIn(1, 30)
        val sinceMillis = System.currentTimeMillis() - boundedDays * 24L * 60L * 60L * 1000L
        val uri = Telephony.Sms.Inbox.CONTENT_URI
        val projection = arrayOf(
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
        )
        val selection = "${Telephony.Sms.DATE} >= ?"
        val selectionArgs = arrayOf(sinceMillis.toString())
        val sortOrder = "${Telephony.Sms.DATE} DESC"

        var count = 0
        activity.contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
            val addressIdx = cursor.getColumnIndex(Telephony.Sms.ADDRESS)
            val bodyIdx = cursor.getColumnIndex(Telephony.Sms.BODY)
            val dateIdx = cursor.getColumnIndex(Telephony.Sms.DATE)

            while (cursor.moveToNext()) {
                val sender = if (addressIdx >= 0) cursor.getString(addressIdx).orEmpty() else ""
                val body = if (bodyIdx >= 0) cursor.getString(bodyIdx).orEmpty() else ""
                val date = if (dateIdx >= 0) cursor.getLong(dateIdx) else System.currentTimeMillis()
                if (body.isBlank()) continue

                val payload = mapOf(
                    "packageName" to "android.sms",
                    "appName" to "SMS",
                    "sender" to sender.trim(),
                    "title" to sender.trim(),
                    "body" to body.trim(),
                    "bigText" to null,
                    "subText" to null,
                    "receivedAt" to date,
                    "sourceType" to "sms",
                    "isOngoing" to false,
                    "category" to "sms",
                )
                NotificationBridge.publish(payload)
                count += 1
            }
        }
        return count
    }

    override fun handleMethodCall(call: MethodCall, result: MethodChannel.Result): Boolean {
        return when (call.method) {
            "isSmsIngestionAvailable" -> {
                result.success(isIngestionAvailable())
                true
            }
            "isSmsPermissionGranted" -> {
                result.success(isPermissionGranted())
                true
            }
            "isReadSmsPermissionGranted" -> {
                result.success(isReadPermissionGranted())
                true
            }
            "isReceiveSmsPermissionGranted" -> {
                result.success(isReceivePermissionGranted())
                true
            }
            "shouldShowSmsPermissionRationale" -> {
                result.success(shouldShowPermissionRationale())
                true
            }
            "isSmsReceiverComponentAvailable" -> {
                result.success(isReceiverComponentAvailable())
                true
            }
            "isSmsReceiverComponentEnabled" -> {
                result.success(isReceiverComponentEnabled())
                true
            }
            "getSmsReceiverDiagnostics" -> {
                result.success(getReceiverDiagnostics())
                true
            }
            "requestSmsPermission" -> {
                requestPermission(result)
                true
            }
            "scanRecentSms" -> {
                val days = call.argument<Int>("days") ?: 7
                result.success(scanRecentSms(days))
                true
            }
            else -> false
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != SMS_PERMISSION_REQUEST_CODE) {
            return false
        }

        val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        Log.d("FinarcMainActivity", "SMS permission result granted=$granted")
        smsPermissionResult?.success(granted)
        smsPermissionResult = null
        return true
    }

    private fun isReceiverComponentAvailableRaw(): Boolean {
        return try {
            val component = ComponentName(activity, FinarcSmsReceiver::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.packageManager.getReceiverInfo(component, PackageManager.ComponentInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                activity.packageManager.getReceiverInfo(component, 0)
            }
            true
        } catch (_: Exception) {
            false
        }
    }
}
