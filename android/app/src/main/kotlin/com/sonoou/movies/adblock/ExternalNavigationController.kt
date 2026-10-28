package com.sonoou.movies.adblock

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log

enum class SchemeAction {
    ALLOW_IN_WEBVIEW,
    HANDLED_EXTERNAL,
    BLOCK
}

class ExternalNavigationController(
    private val context: Context,
    private val stats: BlockingStats
) {
    private val TAG = "ExternalNavController"
    private val isDebug = true

    fun evaluateScheme(url: String, isUserGesture: Boolean): SchemeAction {
        if (url.isBlank()) return SchemeAction.BLOCK

        val lowerUrl = url.trim().lowercase()

        // Standard HTTP / HTTPS
        if (lowerUrl.startsWith("http://") || lowerUrl.startsWith("https://")) {
            return SchemeAction.ALLOW_IN_WEBVIEW
        }

        // Data and Blob URLs
        if (lowerUrl.startsWith("data:") || lowerUrl.startsWith("blob:")) {
            return SchemeAction.ALLOW_IN_WEBVIEW
        }

        // File Scheme protection - block local file system access by default
        if (lowerUrl.startsWith("file://")) {
            if (isDebug) Log.w(TAG, "EXTERNAL INTENT BLOCKED: scheme=file reason=FILE_ACCESS_RESTRICTED")
            stats.incrementExternalIntents()
            return SchemeAction.BLOCK
        }

        // Mailto, Tel, SMS - Allowed only with user gesture
        if (lowerUrl.startsWith("mailto:") || lowerUrl.startsWith("tel:") || lowerUrl.startsWith("sms:")) {
            if (isUserGesture) {
                launchExternalIntent(url)
                return SchemeAction.HANDLED_EXTERNAL
            } else {
                if (isDebug) Log.w(TAG, "EXTERNAL INTENT BLOCKED: scheme=${lowerUrl.substringBefore(":")} reason=NO_USER_GESTURE")
                stats.incrementExternalIntents()
                return SchemeAction.BLOCK
            }
        }

        // Intent:// and Market:// schemes - Strict validation & user gesture required
        if (lowerUrl.startsWith("intent://") || lowerUrl.startsWith("market://")) {
            if (!isUserGesture) {
                if (isDebug) Log.w(TAG, "EXTERNAL INTENT BLOCKED: scheme=intent reason=NO_USER_GESTURE")
                stats.incrementExternalIntents()
                return SchemeAction.BLOCK
            }

            return try {
                val intent = Intent.parseUri(url, Intent.URI_INTENT_SCHEME)
                intent.addCategory(Intent.CATEGORY_BROWSABLE)
                intent.component = null
                intent.selector = null

                if (context.packageManager.resolveActivity(intent, 0) != null) {
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    context.startActivity(intent)
                    SchemeAction.HANDLED_EXTERNAL
                } else {
                    // Fallback URL if specified in intent
                    val fallbackUrl = intent.getStringExtra("browser_fallback_url")
                    if (!fallbackUrl.isNullOrBlank() && (fallbackUrl?.startsWith("http://") == true || fallbackUrl?.startsWith("https://") == true)) {
                        SchemeAction.ALLOW_IN_WEBVIEW
                    } else {
                        stats.incrementExternalIntents()
                        SchemeAction.BLOCK
                    }
                }
            } catch (e: Exception) {
                if (isDebug) Log.e(TAG, "Error handling external intent: ${e.message}")
                stats.incrementExternalIntents()
                SchemeAction.BLOCK
            }
        }

        // Unknown / unsupported scheme
        stats.incrementExternalIntents()
        return SchemeAction.BLOCK
    }

    private fun launchExternalIntent(url: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch intent for $url", e)
        }
    }

    private fun String?.isNull_or_blank(): Boolean {
        return this == null || this.trim().isEmpty()
    }
}
