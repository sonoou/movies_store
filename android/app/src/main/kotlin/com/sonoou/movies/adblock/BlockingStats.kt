package com.sonoou.movies.adblock

import java.util.concurrent.atomic.AtomicInteger

class BlockingStats {
    val adsBlocked = AtomicInteger(0)
    val trackersBlocked = AtomicInteger(0)
    val popupsBlocked = AtomicInteger(0)
    val redirectsBlocked = AtomicInteger(0)
    val externalIntentsBlocked = AtomicInteger(0)

    fun incrementAds() = adsBlocked.incrementAndGet()
    fun incrementTrackers() = trackersBlocked.incrementAndGet()
    fun incrementPopups() = popupsBlocked.incrementAndGet()
    fun incrementRedirects() = redirectsBlocked.incrementAndGet()
    fun incrementExternalIntents() = externalIntentsBlocked.incrementAndGet()

    fun toMap(): Map<String, Int> {
        return mapOf(
            "ads" to adsBlocked.get(),
            "trackers" to trackersBlocked.get(),
            "popups" to popupsBlocked.get(),
            "redirects" to redirectsBlocked.get(),
            "externalIntents" to externalIntentsBlocked.get()
        )
    }

    fun reset() {
        adsBlocked.set(0)
        trackersBlocked.set(0)
        popupsBlocked.set(0)
        redirectsBlocked.set(0)
        externalIntentsBlocked.set(0)
    }
}
