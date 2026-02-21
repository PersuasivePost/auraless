package com.auraless.app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class MindfulAccessibilityService : AccessibilityService() {
    private val PREFS = "mindful_prefs"
    private val KEY_BLOCKED = "blocked_packages"

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val pkg = event.packageName?.toString()
            if (pkg.isNullOrEmpty()) return

            try {
                val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                val csv = prefs.getString(KEY_BLOCKED, "") ?: ""
                val blocked = csv.split(',').map { it.trim() }.filter { it.isNotEmpty() }
                if (blocked.contains(pkg)) {
                    Log.d("MindfulAS", "Blocked package detected: $pkg")
                    // Launch the MindfulDelayActivity with the package name
                    val prefs2 = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                    val delay = prefs2.getInt("mindful_delay_seconds", 30)
                    val i = Intent(this, Class.forName("com.auraless.app.MindfulDelayActivity"))
                    i.putExtra("packageName", pkg)
                    i.putExtra("mindful_delay_seconds", delay)
                    i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(i)

                    // Vibrate briefly if available
                    try {
                        val v = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                        if (v != null) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                v.vibrate(VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE))
                            } else {
                                @Suppress("DEPRECATION")
                                v.vibrate(200)
                            }
                        }
                    } catch (e: Exception) {
                        // ignore vibrator failures
                    }
                }
            } catch (e: Exception) {
                Log.w("MindfulAS", "Error checking blocked list: ${e.localizedMessage}")
            }
        }
    }

    override fun onInterrupt() {
        // No-op
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        // Configure to listen to window state changes
        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.notificationTimeout = 100
        serviceInfo = info
    }
}
