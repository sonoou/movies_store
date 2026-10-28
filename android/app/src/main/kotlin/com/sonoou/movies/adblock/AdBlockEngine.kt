package com.sonoou.movies.adblock

import android.net.Uri
import android.util.Log

class AdBlockEngine(private val stats: BlockingStats) {
    private val TAG = "AdBlockEngine"
    private val isDebug = true // Debug build logging enabled

    // Known ad & tracking domains
    private val adDomains = HashSet<String>().apply {
        addAll(listOf(
            "doubleclick.net",
            "googleadservices.com",
            "googlesyndication.com",
            "google-analytics.com",
            "adservice.google.com",
            "facebook.com/tr",
            "connect.facebook.net",
            "adnxs.com",
            "adsrvr.org",
            "amazon-adsystem.com",
            "scorecardresearch.com",
            "outbrain.com",
            "taboola.com",
            "criteo.com",
            "casalemedia.com",
            "rubiconproject.com",
            "pubmatic.com",
            "adzerk.net",
            "adform.net",
            "adsafeprotected.com",
            "moatads.com",
            "openx.net",
            "indexexchange.com",
            "improvedigital.com",
            "sovrn.com",
            "yieldmo.com",
            "bidswitch.net",
            "popcash.net",
            "popads.net",
            "propellerads.com",
            "exoclick.com",
            "juicyads.com",
            "adsterra.com",
            "hilltopads.com",
            "clkmg.com",
            "ad-delivery.net"
        ))
    }

    // URL path patterns indicating ads/trackers/popups
    private val adUrlPatterns = listOf(
        "/ad/", "/ads/", "/banner/", "/sponsored/", "/promo/",
        "/tracking/", "/analytics/", "?ad=", "&ad=", "utm_",
        "/pop/", "/popup/", "/popunder/", "/direct/link/"
    )

    // Exception / whitelist rules
    private val whitelistDomains = HashSet<String>()

    fun setWhitelist(domains: List<String>) {
        whitelistDomains.clear()
        domains.forEach { domain ->
            val clean = domain.lowercase().trim().removePrefix("https://").removePrefix("http://").removePrefix("www.")
            if (clean.isNotEmpty()) {
                whitelistDomains.add(clean)
                val host = extractDomain(domain)
                if (host != null && host.isNotEmpty()) {
                    whitelistDomains.add(host)
                }
            }
        }
    }

    fun isWhitelisted(url: String): Boolean {
        if (url.isBlank()) return false
        val domain = extractDomain(url)
        val cleanUrl = url.lowercase().trim().removePrefix("https://").removePrefix("http://").removePrefix("www.")
        return (domain != null && (whitelistDomains.contains(domain) || whitelistDomains.any { domain.endsWith(".$it") })) ||
               whitelistDomains.any { cleanUrl.startsWith(it) || it.startsWith(cleanUrl) }
    }

    fun isAdOrTracker(url: String, sourceUrl: String? = null): Boolean {
        if (url.isBlank() || url.startsWith("data:") || url.startsWith("blob:") || url.startsWith("javascript:")) return false

        // Check Whitelist Exceptions
        if (isWhitelisted(url)) return false
        if (sourceUrl != null && isWhitelisted(sourceUrl)) {
            val lower = url.lowercase()
            // Allow essential stylesheets, fonts, and assets from whitelisted source sites
            if (lower.endsWith(".css") || lower.endsWith(".woff") || lower.endsWith(".woff2") || lower.endsWith(".ttf") || lower.endsWith(".svg") || lower.endsWith(".png") || lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".webp") || lower.endsWith(".ico")) {
                return false
            }
        }

        val targetDomain = extractDomain(url) ?: ""

        // 1. Check Known Ad/Tracker Domains
        for (adDomain in adDomains) {
            if (targetDomain.equals(adDomain, ignoreCase = true) || targetDomain.endsWith(".$adDomain", ignoreCase = true)) {
                stats.incrementAds()
                if (isDebug) Log.d(TAG, "AD/TRACKER BLOCKED: source=$sourceUrl destination=$url reason=AD_DOMAIN")
                return true
            }
        }

        // 2. Check URL Patterns
        val lowerUrl = url.lowercase()
        for (pattern in adUrlPatterns) {
            if (lowerUrl.contains(pattern)) {
                // Do not block essential stylesheets or fonts
                if (lowerUrl.endsWith(".css") || lowerUrl.endsWith(".woff") || lowerUrl.endsWith(".woff2") || lowerUrl.endsWith(".ttf")) {
                    continue
                }
                stats.incrementTrackers()
                if (isDebug) Log.d(TAG, "AD/TRACKER BLOCKED: source=$sourceUrl destination=$url reason=URL_PATTERN")
                return true
            }
        }

        return false
    }

    fun extractDomain(url: String): String? {
        return try {
            val formattedUrl = if (!url.contains("://")) "https://$url" else url
            val uri = Uri.parse(formattedUrl)
            var host = uri.host?.lowercase() ?: return null
            if (host.startsWith("www.")) {
                host = host.substring(4)
            }
            host
        } catch (e: Exception) {
            null
        }
    }
}
