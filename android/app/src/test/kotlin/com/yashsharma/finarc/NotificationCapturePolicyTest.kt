package com.yashsharma.finarc

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NotificationCapturePolicyTest {
    @Test
    fun `blocked social and email packages are ignored`() {
        assertTrue(NotificationCapturePolicy.shouldIgnorePackage("com.whatsapp"))
        assertTrue(NotificationCapturePolicy.shouldIgnorePackage("com.snapchat.android"))
        assertTrue(NotificationCapturePolicy.shouldIgnorePackage("org.telegram.messenger"))
        assertTrue(NotificationCapturePolicy.shouldIgnorePackage("com.instagram.android"))
        assertTrue(NotificationCapturePolicy.shouldIgnorePackage("com.facebook.katana"))
        assertTrue(NotificationCapturePolicy.shouldIgnorePackage("com.facebook.orca"))
        assertTrue(NotificationCapturePolicy.shouldIgnorePackage("com.google.android.gm"))
        assertTrue(NotificationCapturePolicy.shouldIgnorePackage("com.microsoft.office.outlook"))
    }

    @Test
    fun `social message with money text is not treated as capturable by package policy`() {
        assertTrue(NotificationCapturePolicy.shouldIgnorePackage("com.whatsapp"))
    }

    @Test
    fun `financial content heuristic only accepts likely financial notifications`() {
        assertTrue(
            NotificationCapturePolicy.isLikelyFinancialContent(
                title = "HDFC Bank",
                body = "INR 2,499 spent at SWIGGY on your card ending 1234",
                bigText = null,
                subText = null,
            ),
        )
        assertTrue(
            NotificationCapturePolicy.isLikelyFinancialContent(
                title = "ICICI Bank",
                body = "Total amount due is INR 17,027.10 on card ending 9000",
                bigText = null,
                subText = null,
            ),
        )
        assertFalse(
            NotificationCapturePolicy.isLikelyFinancialContent(
                title = "WhatsApp",
                body = "Mumma liked your status",
                bigText = null,
                subText = null,
            ),
        )
        assertFalse(
            NotificationCapturePolicy.isLikelyFinancialContent(
                title = "Snapchat",
                body = "Swapnil Bhaiya sent you a Snap",
                bigText = null,
                subText = null,
            ),
        )
    }
}
