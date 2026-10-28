package com.sonoou.movies

import android.media.audiofx.LoudnessEnhancer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Display
import android.view.OrientationEventListener
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import com.sonoou.movies.adblock.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sonoou.movies/adblock"
    private var methodChannel: MethodChannel? = null
    private var loudnessEnhancer: LoudnessEnhancer? = null

    private val blockingStats = BlockingStats()
    private val adBlockEngine = AdBlockEngine(blockingStats)
    private val popupController = PopupController(adBlockEngine, blockingStats)
    private val redirectCompatibilityManager = RedirectCompatibilityManager()
    private val externalNavigationController by lazy { ExternalNavigationController(applicationContext, blockingStats) }
    private val navigationController by lazy {
        NavigationController(
            applicationContext,
            adBlockEngine,
            popupController,
            redirectCompatibilityManager,
            externalNavigationController,
            blockingStats
        )
    }

    private var orientationEventListener: OrientationEventListener? = null
    private var lastPhysicalBucket = -1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Force maximum display refresh rate natively on launch (120Hz / 90Hz / 144Hz)
        setRefreshRate("MAX")

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getBlockedStats" -> {
                    result.success(blockingStats.toMap())
                }

                "evaluateNavigation" -> {
                    val targetUrl = call.argument<String>("targetUrl") ?: ""
                    val isMainFrame = call.argument<Boolean>("isMainFrame") ?: true
                    val isUserGesture = call.argument<Boolean>("isUserGesture") ?: false

                    val decision = navigationController.evaluateNavigation(targetUrl, isMainFrame, isUserGesture)
                    result.success(mapOf(
                        "allowed" to decision.allowed,
                        "reason" to decision.reason,
                        "action" to decision.action.name
                    ))
                }

                "evaluatePopup" -> {
                    val targetUrl = call.argument<String>("targetUrl") ?: ""
                    val sourceUrl = call.argument<String>("sourceUrl") ?: ""

                    val allowed = popupController.evaluatePopup(targetUrl, sourceUrl)
                    result.success(mapOf(
                        "allowed" to allowed,
                        "reason" to if (allowed) "ALLOWED" else "BLOCKED"
                    ))
                }

                "registerUserGesture" -> {
                    popupController.onUserInteraction()
                    result.success(true)
                }

                "setPopupPolicy" -> {
                    val policyStr = call.argument<String>("policy") ?: "ALLOW_USER_GESTURE"
                    try {
                        popupController.currentPolicy = PopupPolicy.valueOf(policyStr)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INVALID_POLICY", "Unknown popup policy $policyStr", null)
                    }
                }

                "updateWhitelist" -> {
                    val domains = call.argument<List<String>>("domains") ?: emptyList()
                    adBlockEngine.setWhitelist(domains)
                    result.success(true)
                }

                "resetStats" -> {
                    blockingStats.reset()
                    result.success(true)
                }

                "onMainPageLoaded" -> {
                    val url = call.argument<String>("url") ?: ""
                    navigationController.onMainPageLoaded(url)
                    result.success(true)
                }

                "enableImmersiveMode" -> {
                    enableImmersiveMode()
                    result.success(true)
                }

                "disableImmersiveMode" -> {
                    disableImmersiveMode()
                    result.success(true)
                }

                "setRefreshRate" -> {
                    val fps = call.argument<String>("fps") ?: "MAX"
                    setRefreshRate(fps)
                    result.success(true)
                }

                "setVolumeBoost" -> {
                    val boostPercent = call.argument<Int>("boostPercent") ?: 100
                    // Convert 100%..400% into millibels (0..3000 mB / 0..+30dB max gain)
                    val targetGainMb = ((boostPercent - 100) * 10).coerceIn(0, 3000)
                    setVolumeBoostGain(targetGainMb)
                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        // Enable 4-way physical accelerometer orientation tilt listener
        setupOrientationListener()
    }

    private fun setVolumeBoostGain(gainMb: Int) {
        runOnUiThread {
            try {
                if (loudnessEnhancer == null) {
                    loudnessEnhancer = LoudnessEnhancer(0)
                }
                loudnessEnhancer?.enabled = false
                if (gainMb > 0) {
                    loudnessEnhancer?.setTargetGain(gainMb)
                    loudnessEnhancer?.enabled = true
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun setupOrientationListener() {
        try {
            orientationEventListener = object : OrientationEventListener(applicationContext) {
                override fun onOrientationChanged(orientation: Int) {
                    if (orientation == ORIENTATION_UNKNOWN) return

                    // Map accelerometer tilt to 4 distinct physical directions (0, 90, 180, 270 degrees)
                    val currentBucket = when (orientation) {
                        in 45..135 -> 1   // Landscape Right / Reverse Landscape (90 deg)
                        in 135..225 -> 2  // Portrait Down / Reverse Portrait - Upside Down (180 deg)
                        in 225..315 -> 3  // Landscape Left (270 deg)
                        else -> 0         // Portrait Up (0 deg)
                    }

                    if (lastPhysicalBucket != -1 && lastPhysicalBucket != currentBucket) {
                        val targetStr = when (currentBucket) {
                            1 -> "LANDSCAPE_RIGHT"
                            2 -> "PORTRAIT_DOWN"
                            3 -> "LANDSCAPE_LEFT"
                            else -> "PORTRAIT_UP"
                        }

                        runOnUiThread {
                            methodChannel?.invokeMethod(
                                "onPhysicalTilt",
                                mapOf("targetOrientation" to targetStr)
                            )
                        }
                    }
                    lastPhysicalBucket = currentBucket
                }
            }
            if (orientationEventListener?.canDetectOrientation() == true) {
                orientationEventListener?.enable()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun setRefreshRate(fps: String) {
        runOnUiThread {
            try {
                val display: Display? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    display
                } else {
                    @Suppress("DEPRECATION")
                    windowManager.defaultDisplay
                }

                val modes = display?.supportedModes ?: emptyArray()
                var maxHz = 60f
                for (mode in modes) {
                    if (mode.refreshRate > maxHz) {
                        maxHz = mode.refreshRate
                    }
                }

                val targetHz = if (fps == "MAX" || fps == "AUTO") {
                    maxHz
                } else {
                    fps.toFloatOrNull() ?: maxHz
                }

                val params = window.attributes

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    var targetMode: Display.Mode? = null
                    var minDiff = Float.MAX_VALUE
                    for (mode in modes) {
                        val diff = Math.abs(mode.refreshRate - targetHz)
                        if (diff < minDiff) {
                            minDiff = diff
                            targetMode = mode
                        }
                    }
                    if (targetMode != null) {
                        params.preferredDisplayModeId = targetMode.modeId
                    }
                    params.preferredRefreshRate = targetHz
                }

                try {
                    val setMinMethod = params.javaClass.getMethod("setPreferredMinDisplayRefreshRate", Float::class.javaPrimitiveType)
                    setMinMethod.invoke(params, targetHz)
                } catch (e: Exception) {}

                try {
                    val setMaxMethod = params.javaClass.getMethod("setPreferredMaxDisplayRefreshRate", Float::class.javaPrimitiveType)
                    setMaxMethod.invoke(params, targetHz)
                } catch (e: Exception) {}

                window.attributes = params
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun enableImmersiveMode() {
        runOnUiThread {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    val controller = window.insetsController
                    if (controller != null) {
                        controller.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                        controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                    } else {
                        window.decorView.post {
                            try {
                                window.insetsController?.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                                window.insetsController?.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                            } catch (e: Exception) {}
                        }
                    }
                } else {
                    @Suppress("DEPRECATION")
                    window.decorView.systemUiVisibility = (
                        View.SYSTEM_UI_FLAG_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    )
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun disableImmersiveMode() {
        runOnUiThread {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    window.insetsController?.show(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                } else {
                    @Suppress("DEPRECATION")
                    window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onDestroy() {
        try {
            loudnessEnhancer?.release()
            loudnessEnhancer = null
        } catch (e: Exception) {}
        orientationEventListener?.disable()
        super.onDestroy()
    }
}
