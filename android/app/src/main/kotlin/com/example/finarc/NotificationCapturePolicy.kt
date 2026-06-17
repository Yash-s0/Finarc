package com.yashsharma.finarc

object NotificationCapturePolicy {
    private val blockedPackages = setOf(
        "com.whatsapp",
        "com.whatsapp.w4b",
        "com.snapchat.android",
        "org.telegram.messenger",
        "org.thunderdog.challegram",
        "com.instagram.android",
        "com.facebook.katana",
        "com.facebook.orca",
        "com.google.android.gm",
        "com.microsoft.office.outlook",
        "com.samsung.android.email.provider",
    )

    private val financialKeywords = listOf(
        "debited",
        "credited",
        "spent",
        "paid",
        "payment",
        "purchase",
        "transaction",
        "txn",
        "upi",
        "imps",
        "neft",
        "refund",
        "cashback",
        "salary",
        "payroll",
        "bill due",
        "amount due",
        "statement",
        "card payment",
        "settlement",
        "account",
        "a/c",
        "available balance",
        "avl bal",
        "withdrawn",
        "received",
        "sent",
        "deposited",
        "transfer",
    )

    private val financialAmountRegex = Regex(
        "(?:INR|Rs\\.?|₹)\\s*[0-9][0-9,]*(?:\\.[0-9]{1,2})?",
        RegexOption.IGNORE_CASE,
    )

    fun shouldIgnorePackage(packageName: String?): Boolean {
        val normalized = packageName?.trim()?.lowercase().orEmpty()
        if (normalized.isEmpty()) return true
        return blockedPackages.contains(normalized)
    }

    fun isLikelyFinancialContent(
        title: String?,
        body: String?,
        bigText: String?,
        subText: String?,
    ): Boolean {
        val combined = listOfNotNull(title, body, bigText, subText)
            .joinToString(" ")
            .trim()
        if (combined.isEmpty()) return false
        val lowered = combined.lowercase()
        val hasKeyword = financialKeywords.any(lowered::contains)
        val hasAmount = financialAmountRegex.containsMatchIn(combined)
        if (hasKeyword && hasAmount) return true
        return lowered.contains("bill due") ||
            lowered.contains("amount due") ||
            lowered.contains("card payment") ||
            lowered.contains("statement due")
    }
}
