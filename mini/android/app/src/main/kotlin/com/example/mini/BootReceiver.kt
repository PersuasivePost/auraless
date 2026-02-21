package com.auraless.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
                // No-op for now. App is a launcher and will start when user interacts.
                Log.d("BootReceiver", "BOOT_COMPLETED received - no action taken")
            }
        } catch (e: Exception) {
            Log.w("BootReceiver", "Error handling boot: ${e.localizedMessage}")
        }
    }
}
