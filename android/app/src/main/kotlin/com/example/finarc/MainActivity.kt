package com.yashsharma.finarc

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
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
        private const val DETECTED_NOTIFICATION_BASE_ID = 100_000
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
        private const val POST_NOTIFICATIONS_PERMISSION_REQUEST_CODE = 7308

        private val launchRouteQueue: ArrayDeque<String> = ArrayDeque()
    }

    private var postNotificationsPermissionResult: MethodChannel.Result? = null
    private val ingestionBridge: IngestionPlatformBridge by lazy {
        createIngestionPlatformBridge(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    NotificationBridge.setEventSink(applicationContext) { payload ->
                        runOnUiThread {
                            events?.success(payload)
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    NotificationBridge.setEventSink(applicationContext, null)
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

                "isNotificationListenerComponentAvailable" -> {
                    result.success(isNotificationListenerComponentAvailable())
                }
                "isNotificationIngestionAvailable" -> {
                    result.success(isNotificationIngestionAvailable())
                }
                "isRealIngestionAvailable" -> {
                    result.success(isRealIngestionAvailable())
                }

                "openNotificationAccessSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(true)
                }

                "isPostNotificationsGranted" -> {
                    result.success(isPostNotificationsGranted())
                }

                "requestPostNotificationsPermission" -> {
                    requestPostNotificationsPermission(result)
                }

                "openAppPermissionSettings" -> {
                    openAppPermissionSettings()
                    result.success(true)
                }

                "drainCapturedNotifications" -> {
                    val drained = NotificationBridge.drainQueue(applicationContext)
                    if (drained.isNotEmpty()) {
                        BackgroundNotificationHelper.cancelCapturedTransactionNotification(applicationContext)
                    }
                    result.success(drained)
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

                else -> {
                    if (!ingestionBridge.handleMethodCall(call, result)) {
                        result.notImplemented()
                    }
                }
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
        if (ingestionBridge.onRequestPermissionsResult(requestCode, permissions, grantResults)) {
            return
        }

        if (requestCode == POST_NOTIFICATIONS_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            postNotificationsPermissionResult?.success(granted)
            postNotificationsPermissionResult = null
        }
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
        if (!isNotificationIngestionAvailable()) return false
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        )

        return enabledListeners?.contains(packageName) == true
    }

    private fun isNotificationListenerComponentAvailable(): Boolean {
        if (!isNotificationIngestionAvailable()) return false
        return rawNotificationListenerComponentAvailable()
    }

    private fun rawNotificationListenerComponentAvailable(): Boolean {
        return try {
            val component = ComponentName(this, FinarcNotificationListenerService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getServiceInfo(component, PackageManager.ComponentInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getServiceInfo(component, 0)
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun isPostNotificationsGranted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestPostNotificationsPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }
        if (isPostNotificationsGranted()) {
            result.success(true)
            return
        }
        if (postNotificationsPermissionResult != null) {
            result.error("permission_in_progress", "Post notifications permission request already in progress", null)
            return
        }
        postNotificationsPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            POST_NOTIFICATIONS_PERMISSION_REQUEST_CODE,
        )
    }

    private fun openAppPermissionSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = android.net.Uri.fromParts("package", packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun isNotificationIngestionAvailable(): Boolean {
        return rawNotificationListenerComponentAvailable()
    }

    private fun isSecondaryIngestionAvailable(): Boolean {
        return ingestionBridge.isIngestionAvailable()
    }

    private fun isRealIngestionAvailable(): Boolean {
        return isNotificationIngestionAvailable() || isSecondaryIngestionAvailable()
    }

    private fun showDetectionNotification(
        title: String,
        body: String,
        route: String,
        pendingId: Int?,
        showActions: Boolean,
    ) {
        if (!isPostNotificationsGranted()) return
        createChannelsIfNeeded()
        BackgroundNotificationHelper.cancelCapturedTransactionNotification(applicationContext)

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

        val notificationId = pendingId?.let { DETECTED_NOTIFICATION_BASE_ID + it }
            ?: (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
        NotificationManagerCompat.from(this).notify(notificationId, notification)
    }

    private fun showReminderNotification(title: String, body: String, route: String) {
        if (!isPostNotificationsGranted()) return
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
        if (!isPostNotificationsGranted()) return
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
                    if (canScheduleExactAlarm(alarmManager)) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            triggerAtMillis,
                            pendingIntent,
                        )
                    } else {
                        alarmManager.setAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            triggerAtMillis,
                            pendingIntent,
                        )
                    }
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

    private fun canScheduleExactAlarm(alarmManager: AlarmManager): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return alarmManager.canScheduleExactAlarms()
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
