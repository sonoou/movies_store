package com.sonoou.movies.adblock

import android.content.Context
import android.util.Log

data class NavigationDecision(
    val allowed: Boolean,
    val reason: String,
    val action: SchemeAction = SchemeAction.ALLOW_IN_WEBVIEW
)

class NavigationController(
    private val context: Context,
    val adBlockEngine: AdBlockEngine,
    val popupController: PopupController,
    val redirectCompatibilityManager: RedirectCompatibilityManager,
    val externalNavigationController: ExternalNavigationController,
    val stats: BlockingStats
) {
    private val TAG = "NavigationController"
    private val isDebug = true

    // Redirect Chain Tracking
    private var previousUrl: String = ""
    private var redirectCount: Int = 0
    private var redirectDepth: Int = 0
    private var lastNavigationTimestamp: Long = 0L
    private val navigationChain = ArrayList<String>()

    fun onMainPageLoaded(url: String) {
        previousUrl = url
        redirectCount = 0
        redirectDepth = 0
        navigationChain.clear()
        navigationChain.add(url)
        lastNavigationTimestamp = System.currentTimeMillis()
        
        val domain = adBlockEngine.extractDomain(url) ?: ""
        popupController.resetPageStats(domain)
    }

    fun evaluateNavigation(
        targetUrl: String,
        isMainFrame: Boolean,
        isUserGesture: Boolean
    ): NavigationDecision {
        val now = System.currentTimeMillis()

        // 1. Check URL Scheme Protection
        val schemeAction = externalNavigationController.evaluateScheme(targetUrl, isUserGesture)
        if (schemeAction == SchemeAction.BLOCK) {
            return NavigationDecision(false, "SCHEME_BLOCKED", schemeAction)
        } else if (schemeAction == SchemeAction.HANDLED_EXTERNAL) {
            return NavigationDecision(false, "HANDLED_EXTERNAL", schemeAction)
        }

        // Allow internal blank / data / blob schemes
        if (targetUrl.startsWith("about:") || targetUrl.startsWith("data:") || targetUrl.startsWith("blob:")) {
            return NavigationDecision(true, "INTERNAL")
        }

        // 2. EXTREME ALLOWLIST ENFORCEMENT: ONLY sites in allowlist can EVER open!
        if (!adBlockEngine.isWhitelisted(targetUrl)) {
            stats.incrementRedirects()
            if (isDebug) Log.w(TAG, "STRICT ALLOWLIST BLOCKED: source=$previousUrl destination=$targetUrl reason=NOT_IN_ALLOWLIST")
            return NavigationDecision(false, "NOT_IN_ALLOWLIST")
        }

        // 3. Redirect Loop Protection
        if (isMainFrame) {
            if (detectRedirectLoop(targetUrl, now)) {
                stats.incrementRedirects()
                if (isDebug) Log.w(TAG, "REDIRECT BLOCKED: source=$previousUrl destination=$targetUrl reason=REDIRECT_LOOP")
                return NavigationDecision(false, "REDIRECT_LOOP")
            }

            // Update navigation chain
            navigationChain.add(targetUrl)
            if (navigationChain.size > 10) {
                navigationChain.removeAt(0)
            }
            redirectCount++
            redirectDepth++
        }

        // 4. Filter Rule Check (Ads/Trackers)
        if (adBlockEngine.isAdOrTracker(targetUrl, previousUrl)) {
            if (isMainFrame) stats.incrementRedirects() else stats.incrementAds()
            if (isDebug) Log.w(TAG, "NAVIGATION BLOCKED: source=$previousUrl destination=$targetUrl reason=FILTER_RULE")
            return NavigationDecision(false, "FILTER_RULE")
        }

        // Navigation approved
        if (isMainFrame) {
            previousUrl = targetUrl
            lastNavigationTimestamp = now
        }
        return NavigationDecision(true, "ALLOWED")
    }

    private fun detectRedirectLoop(url: String, timestamp: Long): Boolean {
        val recentCount = navigationChain.count { it == url }
        if (recentCount >= 2 && (timestamp - lastNavigationTimestamp) < 3000L) {
            return true
        }

        if (navigationChain.size >= 4) {
            val len = navigationChain.size
            if (navigationChain[len - 1] == navigationChain[len - 3] &&
                navigationChain[len - 2] == url) {
                return true
            }
        }

        return false
    }
}
