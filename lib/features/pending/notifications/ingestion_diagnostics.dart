class IngestionDiagnostics {
  const IngestionDiagnostics({
    this.smsReceived = 0,
    this.smsAllowed = 0,
    this.smsBlockedPromotional = 0,
    this.smsBlockedUnknownSender = 0,
    this.smsBlockedNonTransaction = 0,
    this.smsParsedPending = 0,
    this.smsDuplicateSuppressed = 0,
    this.notificationsReceived = 0,
    this.notificationsParsedPending = 0,
    this.notificationsIgnored = 0,
    this.notificationsDuplicateSuppressed = 0,
    this.notificationsNearDuplicateSuppressed = 0,
    this.lastSmsEventAt,
    this.lastSmsSender,
    this.lastSmsResult,
    this.lastNotificationEventAt,
    this.lastNotificationPackage,
    this.lastNotificationResult,
    this.lastError,
  });

  final int smsReceived;
  final int smsAllowed;
  final int smsBlockedPromotional;
  final int smsBlockedUnknownSender;
  final int smsBlockedNonTransaction;
  final int smsParsedPending;
  final int smsDuplicateSuppressed;
  final int notificationsReceived;
  final int notificationsParsedPending;
  final int notificationsIgnored;
  final int notificationsDuplicateSuppressed;
  final int notificationsNearDuplicateSuppressed;
  final DateTime? lastSmsEventAt;
  final String? lastSmsSender;
  final String? lastSmsResult;
  final DateTime? lastNotificationEventAt;
  final String? lastNotificationPackage;
  final String? lastNotificationResult;
  final String? lastError;

  IngestionDiagnostics copyWith({
    int? smsReceived,
    int? smsAllowed,
    int? smsBlockedPromotional,
    int? smsBlockedUnknownSender,
    int? smsBlockedNonTransaction,
    int? smsParsedPending,
    int? smsDuplicateSuppressed,
    int? notificationsReceived,
    int? notificationsParsedPending,
    int? notificationsIgnored,
    int? notificationsDuplicateSuppressed,
    int? notificationsNearDuplicateSuppressed,
    DateTime? lastSmsEventAt,
    String? lastSmsSender,
    String? lastSmsResult,
    DateTime? lastNotificationEventAt,
    String? lastNotificationPackage,
    String? lastNotificationResult,
    String? lastError,
    bool clearLastError = false,
  }) {
    return IngestionDiagnostics(
      smsReceived: smsReceived ?? this.smsReceived,
      smsAllowed: smsAllowed ?? this.smsAllowed,
      smsBlockedPromotional:
          smsBlockedPromotional ?? this.smsBlockedPromotional,
      smsBlockedUnknownSender:
          smsBlockedUnknownSender ?? this.smsBlockedUnknownSender,
      smsBlockedNonTransaction:
          smsBlockedNonTransaction ?? this.smsBlockedNonTransaction,
      smsParsedPending: smsParsedPending ?? this.smsParsedPending,
      smsDuplicateSuppressed:
          smsDuplicateSuppressed ?? this.smsDuplicateSuppressed,
      notificationsReceived:
          notificationsReceived ?? this.notificationsReceived,
      notificationsParsedPending:
          notificationsParsedPending ?? this.notificationsParsedPending,
      notificationsIgnored: notificationsIgnored ?? this.notificationsIgnored,
      notificationsDuplicateSuppressed:
          notificationsDuplicateSuppressed ??
          this.notificationsDuplicateSuppressed,
      notificationsNearDuplicateSuppressed:
          notificationsNearDuplicateSuppressed ??
          this.notificationsNearDuplicateSuppressed,
      lastSmsEventAt: lastSmsEventAt ?? this.lastSmsEventAt,
      lastSmsSender: lastSmsSender ?? this.lastSmsSender,
      lastSmsResult: lastSmsResult ?? this.lastSmsResult,
      lastNotificationEventAt:
          lastNotificationEventAt ?? this.lastNotificationEventAt,
      lastNotificationPackage:
          lastNotificationPackage ?? this.lastNotificationPackage,
      lastNotificationResult:
          lastNotificationResult ?? this.lastNotificationResult,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  static const empty = IngestionDiagnostics();
}
