package com.sonoou.movies.adblock

import android.net.Uri

class RedirectCompatibilityManager {

    // Universal authentication & payment destination domains that are legitimate redirects
    private val globalAuthDomains = HashSet<String>().apply {
        addAll(listOf(
            "accounts.google.com",
            "appleid.apple.com",
            "login.microsoftonline.com",
            "facebook.com/dialog/oauth",
            "github.com/login/oauth",
            "auth0.com",
            "paypal.com",
            "checkout.stripe.com",
            "razorpay.com",
            "paytm.com",
            "recaptcha.net",
            "google.com/recaptcha"
        ))
    }

    // Site-specific redirect allowance maps
    private val siteSpecificRules = HashMap<String, HashSet<String>>()

    init {
        // Pre-configure standard site compatibility rules
        addSiteRule("onlyflix.to", listOf("accounts.google.com", "cdn.onlyflix.to", "stream.onlyflix.to"))
    }

    fun addSiteRule(sourceDomain: String, allowedDestinations: List<String>) {
        val cleanSource = sourceDomain.lowercase().trim().removePrefix("www.")
        val set = siteSpecificRules.getOrPut(cleanSource) { HashSet() }
        allowedDestinations.forEach { dest ->
            val cleanDest = dest.lowercase().trim().removePrefix("www.")
            set.add(cleanDest)
        }
    }

    fun isLegitimateRedirect(sourceUrl: String, destinationUrl: String): Boolean {
        val sourceDomain = extractDomain(sourceUrl) ?: return false
        val destDomain = extractDomain(destinationUrl) ?: return false

        // 1. Same-site redirect (or subdomain)
        if (sourceDomain == destDomain || sourceDomain.endsWith(".$destDomain") || destDomain.endsWith(".$sourceDomain")) {
            return true
        }

        // 2. Global Auth & Payment Destinations
        for (authDomain in globalAuthDomains) {
            if (destDomain == authDomain || destDomain.endsWith(".$authDomain")) {
                return true
            }
        }

        // 3. Site-specific rules check
        val allowedSet = siteSpecificRules[sourceDomain]
        if (allowedSet != null) {
            for (allowed in allowedSet) {
                if (destDomain == allowed || destDomain.endsWith(".$allowed")) {
                    return true
                }
            }
        }

        return false
    }

    private fun extractDomain(url: String): String? {
        return try {
            val uri = Uri.parse(url)
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
