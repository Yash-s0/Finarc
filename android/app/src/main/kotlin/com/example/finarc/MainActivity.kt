package com.example.finarc

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.provider.Telephony
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val EVENTS_CHANNEL = "finarc/notification_events"
        private const val METHOD_CHANNEL = "finarc/notification_control"
        private const val DETECTED_CHANNEL_ID = "finarc_detected_txn"
        private const val DETECTED_CHANNEL_NAME = "Detected Transactions"
        private const val REMINDER_CHANNEL_ID = "finarc_reminders"
        private const val REMINDER_CHANNEL_NAME = "Finarc Reminders"
        private const val ALERTS_CHANNEL_ID = "finarc_alerts"
        private const val ALERTS_CHANNEL_NAME = "Finarc Alerts"
        private const val TRANSACTIONS_CHANNEL_ID = "finarc_transactions"
        private const val TRANSACTIONS_CHANNEL_NAME = "Transactions"
        private const val BILLS_CHANNEL_ID = "finarc_bills"
        private const val BILLS_CHANNEL_NAME = "Bills"
        private const val EMIS_CHANNEL_ID = "finarc_emis"
        private const val EMIS_CHANNEL_NAME = "EMIs"
        private const val SPLITS_CHANNEL_ID = "finarc_splits"
        private const val SPLITS_CHANNEL_NAME = "Splits"
        private const val ANALYTICS_CHANNEL_ID = "finarc_analytics"
        private const val ANALYTICS_CHANNEL_NAME = "Analytics"
        private const val SUMMARIES_CHANNEL_ID = "finarc_summaries"
        private const val SUMMARIES_CHANNEL_NAME = "Summaries"
        private const val EXTRA_ROUTE = "finarc_route"
        private const val SMS_PERMISSION_REQUEST_CODE = 7307

        private val launchRouteQueue: ArrayDeque<String> = ArrayDeque()
    }

    private var smsPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    NotificationBridge.setEventSink { payload ->
                        runOnUiThread {
                            events?.success(payload)
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    NotificationBridge.setEventSink(null)
                }
            },
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler {
                call,
                result,
            ->
            when (call.method) {
                "isNotificationAccessEnabled" -> {
                    result.success(isNotificationAccessEnabled())
                }

                "openNotificationAccessSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(true)
                }

                "isSmsPermissionGranted" -> {
                    result.success(isSmsPermissionGranted())
                }

                "requestSmsPermission" -> {
                    requestSmsPermission(result)
                }

                "openAppPermissionSettings" -> {
                    openAppPermissionSettings()
                    result.success(true)
                }

                "scanRecentSms" -> {
                    val days = call.argument<Int>("days") ?: 7
                    val count = scanRecentSms(days)
                    result.success(count)
                }

                "drainCapturedNotifications" -> {
                    result.success(NotificationBridge.drainQueue())
                }

                "showDetectionNotification" -> {
                    val title = call.argument<String>("title") ?: "Transaction detected"
                    val body = call.argument<String>("body") ?: "Open pending transactions"
                    val route = call.argument<String>("route") ?: "/pending"
                    val pendingId = call.argument<Int>("pendingId")
                    val showActions = call.argument<Boolean>("showActions") ?: true
                    showDetectionNotification(title, body, route, pendingId, showActions)
                    result.success(true)
                }

                "showReminderNotification" -> {
                    val title = call.argument<String>("title") ?: "Finarc Reminder"
                    val body = call.argument<String>("body") ?: "Open Finarc"
                    val route = call.argument<String>("route") ?: "/"
                    showReminderNotification(title, body, route)
                    result.success(true)
                }

                "showAlertNotification" -> {
                    val title = call.argument<String>("title") ?: "Finarc Alert"
                    val body = call.argument<String>("body") ?: "Open Finarc"
                    val route = call.argument<String>("route") ?: "/alerts"
                    val channelType = call.argument<String>("channelType") ?: "alerts"
                    showAlertNotification(title, body, route, channelType)
                    result.success(true)
                }

                "scheduleReminderNotification" -> {
                    val reminderId = call.argument<Int>("reminderId")
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis")
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val route = call.argument<String>("route")
                    val repeatDaily = call.argument<Boolean>("repeatDaily") ?: false
                    val repeatWeekly = call.argument<Boolean>("repeatWeekly") ?: false
                    if (reminderId == null || triggerAtMillis == null || title == null || body == null || route == null) {
                        result.error("invalid_args", "Missing reminder scheduling arguments", null)
                    } else {
                        scheduleReminder(reminderId, triggerAtMillis, title, body, route, repeatDaily, repeatWeekly)
                        result.success(true)
                    }
                }

                "cancelReminderNotification" -> {
                    val reminderId = call.argument<Int>("reminderId")
                    if (reminderId == null) {
                        result.error("invalid_args", "Missing reminderId", null)
                    } else {
                        cancelReminder(reminderId)
                        result.success(true)
                    }
                }

                "consumeLaunchRoute" -> {
                    result.success(consumeLaunchRoute())
                }

                else -> result.notImplemented()
            }
        }

        enqueueRouteFromIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        enqueueRouteFromIntent(intent)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != SMS_PERMISSION_REQUEST_CODE) return

        val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        smsPermissionResult?.success(granted)
        smsPermissionResult = null
    }

    private fun enqueueRouteFromIntent(intent: Intent?) {
        val route = intent?.getStringExtra(EXTRA_ROUTE)
        if (!route.isNullOrBlank()) {
            launchRouteQueue.addLast(route)
        }
    }

    private fun consumeLaunchRoute(): String? {
        return if (launchRouteQueue.isEmpty()) null else launchRouteQueue.removeFirst()
    }

    private fun isNotificationAccessEnabled(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        )

        return enabledListeners?.contains(packageName) == true
    }

    private fun isSmsPermissionGranted(): Boolean {
        val readGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_SMS,
        ) == PackageManager.PERMISSION_GRANTED
        return readGranted
    }

    private fun requestSmsPermission(result: MethodChannel.Result) {
        if (isSmsPermissionGranted()) {
            result.success(true)
            return
        }
        if (smsPermissionResult != null) {
            result.error("permission_in_progress", "SMS permission request already in progress", null)
            return
        }

        smsPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS),
            SMS_PERMISSION_REQUEST_CODE,
        )
    }

    private fun openAppPermissionSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = android.net.Uri.fromParts("package", packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun scanRecentSms(days: Int): Int {
        if (!isSmsPermissionGranted()) return 0
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
        contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
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

    private fun showDetectionNotification(
        title: String,
        body: String,
        route: String,
        pendingId: Int?,
        showActions: Boolean,
    ) {
        createChannelsIfNeeded()

        val builder = NotificationCompat.Builder(this, DETECTED_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(createRoutePendingIntent(route, route.hashCode()))

        if (showActions && pendingId != null) {
            val confirmRoute = "/pending?action=confirm&pendingId=$pendingId"
            val editRoute = "/pending/edit/$pendingId"
            val ignoreRoute = "/pending?action=ignore&pendingId=$pendingId"

            builder.addAction(
                NotificationCompat.Action.Builder(
                    android.R.drawable.ic_menu_edit,
                    "Confirm",
                    createRoutePendingIntent(confirmRoute, confirmRoute.hashCode()),
                ).build(),
            )
            builder.addAction(
                NotificationCompat.Action.Builder(
                    android.R.drawable.ic_menu_manage,
                    "Edit",
                    createRoutePendingIntent(editRoute, editRoute.hashCode()),
                ).build(),
            )
            builder.addAction(
                NotificationCompat.Action.Builder(
                    android.R.drawable.ic_menu_close_clear_cancel,
                    "Ignore",
                    createRoutePendingIntent(ignoreRoute, ignoreRoute.hashCode()),
                ).build(),
            )
        }

        val notification = builder.build()

        NotificationManagerCompat.from(this).notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), notification)
    }

    private fun showReminderNotification(title: String, body: String, route: String) {
        createChannelsIfNeeded()
        val notification = NotificationCompat.Builder(this, REMINDER_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(createRoutePendingIntent(route, route.hashCode()))
            .build()
        NotificationManagerCompat.from(this).notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), notification)
    }

    private fun showAlertNotification(title: String, body: String, route: String, channelType: String) {
        createChannelsIfNeeded()
        val channelId = when (channelType) {
            "transactions" -> TRANSACTIONS_CHANNEL_ID
            "bills" -> BILLS_CHANNEL_ID
            "emis" -> EMIS_CHANNEL_ID
            "splits" -> SPLITS_CHANNEL_ID
            "analytics" -> ANALYTICS_CHANNEL_ID
            "summaries" -> SUMMARIES_CHANNEL_ID
            "alerts" -> ALERTS_CHANNEL_ID
            else -> ALERTS_CHANNEL_ID
        }
        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(createRoutePendingIntent(route, "$route:$channelType".hashCode()))
            .build()
        NotificationManagerCompat.from(this).notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), notification)
    }

    private fun scheduleReminder(
        reminderId: Int,
        triggerAtMillis: Long,
        title: String,
        body: String,
        route: String,
        repeatDaily: Boolean,
        repeatWeekly: Boolean,
    ) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val receiverIntent = Intent(this, FinarcReminderReceiver::class.java).apply {
            putExtra("reminder_id", reminderId)
            putExtra("title", title)
            putExtra("body", body)
            putExtra(EXTRA_ROUTE, route)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            reminderId,
            receiverIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        alarmManager.cancel(pendingIntent)

        when {
            repeatDaily -> {
                alarmManager.setInexactRepeating(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    AlarmManager.INTERVAL_DAY,
                    pendingIntent,
                )
            }

            repeatWeekly -> {
                alarmManager.setInexactRepeating(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    AlarmManager.INTERVAL_DAY * 7,
                    pendingIntent,
                )
            }

            else -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent,
                    )
                } else {
                    alarmManager.setExact(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent,
                    )
                }
            }
        }
    }

    private fun cancelReminder(reminderId: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val receiverIntent = Intent(this, FinarcReminderReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            reminderId,
            receiverIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.cancel(pendingIntent)
        NotificationManagerCompat.from(this).cancel(reminderId)
    }

    private fun createRoutePendingIntent(route: String, requestCode: Int): PendingIntent {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_ROUTE, route)
        }
        return PendingIntent.getActivity(
            this,
            requestCode,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun createChannelsIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java) ?: return
        val detectedChannel = NotificationChannel(
            DETECTED_CHANNEL_ID,
            DETECTED_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Alerts for detected transaction notifications"
        }
        manager.createNotificationChannel(detectedChannel)

        val reminderChannel = NotificationChannel(
            REMINDER_CHANNEL_ID,
            REMINDER_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Finance reminders from Finarc"
        }
        manager.createNotificationChannel(reminderChannel)

        val alertsChannel = NotificationChannel(
            ALERTS_CHANNEL_ID,
            ALERTS_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "General financial alerts"
        }
        manager.createNotificationChannel(alertsChannel)

        manager.createNotificationChannel(
            NotificationChannel(
                TRANSACTIONS_CHANNEL_ID,
                TRANSACTIONS_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT,
            ),
        )
        manager.createNotificationChannel(
            NotificationChannel(
                BILLS_CHANNEL_ID,
                BILLS_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH,
            ),
        )
        manager.createNotificationChannel(
            NotificationChannel(
                EMIS_CHANNEL_ID,
                EMIS_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH,
            ),
        )
        manager.createNotificationChannel(
            NotificationChannel(
                SPLITS_CHANNEL_ID,
                SPLITS_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT,
            ),
        )
        manager.createNotificationChannel(
            NotificationChannel(
                ANALYTICS_CHANNEL_ID,
                ANALYTICS_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
        manager.createNotificationChannel(
            NotificationChannel(
                SUMMARIES_CHANNEL_ID,
                SUMMARIES_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
    }
}
