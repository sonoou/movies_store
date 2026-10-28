package com.sonoou.movies.adblock

import android.util.Log

enum class PopupPolicy {
    BLOCK_ALL_UNREQUESTED,
    ALLOW_USER_GESTURE,
    ALLOW_WHITELISTED,
    ALLOW_ALL
}

class PopupController(
    private val adBlockEngine: AdBlockEngine,
    private val stats: BlockingStats
) {
    private val TAG = "PopupController"
    private val isDebug = true

    // Default to strict BLOCK_ALL_UNREQUESTED
    var currentPolicy: PopupPolicy = PopupPolicy.BLOCK_ALL_UNREQUESTED

    // Configurable Rate Limiting Parameters
    var maxPopupsPerPage: Int = 1
    var maxPopupsIntervalMs: Long = 10000L // 10 seconds
    var maxPopupsPerInterval: Int = 1

    private var userGestureActive: Boolean = false
    private var lastGestureTimestamp: Long = 0L

    private val pagePopupCounts = HashMap<String, Int>()
    private val popupTimestamps = ArrayList<Long>()

    fun onUserInteraction() {
        userGestureActive = true
        lastGestureTimestamp = System.currentTimeMillis()
    }

    fun isUserGestureValid(): Boolean {
        return userGestureActive && (System.currentTimeMillis() - lastGestureTimestamp < 2500L)
    }

    fun resetPageStats(pageDomain: String) {
        pagePopupCounts[pageDomain] = 0
        popupTimestamps.clear()
        userGestureActive = false
    }

    fun evaluatePopup(targetUrl: String, sourceUrl: String): Boolean {
        // STRICT ALLOWLIST CHECK: Popups destination must be in allowlist!
        if (!adBlockEngine.isWhitelisted(targetUrl)) {
            blockPopup(sourceUrl, targetUrl, "NOT_IN_ALLOWLIST")
            return false
        }

        // Must have valid user gesture
        if (!isUserGestureValid()) {
            blockPopup(sourceUrl, targetUrl, "NO_USER_GESTURE")
            return false
        }

        // Ad/Tracker filter check
        if (adBlockEngine.isAdOrTracker(targetUrl, sourceUrl)) {
            blockPopup(sourceUrl, targetUrl, "FILTER_RULE")
            return false
        }

        val currentTime = System.currentTimeMillis()
        popupTimestamps.removeAll { currentTime - it > maxPopupsIntervalMs }
        if (popupTimestamps.size >= maxPopupsPerInterval) {
            blockPopup(sourceUrl, targetUrl, "RATE_LIMIT_EXCEEDED")
            return false
        }

        val sourceDomain = adBlockEngine.extractDomain(sourceUrl) ?: ""
        val countForPage = pagePopupCounts.getOrDefault(sourceDomain, 0)
        if (countForPage >= maxPopupsPerPage) {
            blockPopup(sourceUrl, targetUrl, "MAX_POPUPS_PER_PAGE_EXCEEDED")
            return false
        }

        pagePopupCounts[sourceDomain] = countForPage + 1
        popupTimestamps.add(currentTime)
        userGestureActive = false
        
        if (isDebug) Log.d(TAG, "POPUP ALLOWED: source=$sourceUrl destination=$targetUrl")
        return true
    }

    private fun blockPopup(sourceUrl: String, targetUrl: String, reason: String) {
        stats.incrementPopups()
        if (isDebug) Log.d(TAG, "POPUP BLOCKED source=$sourceUrl destination=$targetUrl reason=$reason")
    }
}
