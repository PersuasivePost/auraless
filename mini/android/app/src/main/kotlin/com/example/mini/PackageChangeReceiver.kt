package com.auraless.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log

class PackageChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val action = intent.action ?: return
            val data = intent.dataString ?: ""
            // data is like "package:com.example.app"
            val pkg = if (data.startsWith("package:")) data.substringAfter("package:") else data
            val eventType = when (action) {
                Intent.ACTION_PACKAGE_ADDED -> "added"
                Intent.ACTION_PACKAGE_REMOVED -> "removed"
                Intent.ACTION_PACKAGE_REPLACED -> "replaced"
                else -> "unknown"
            }

            // Store pending event in shared prefs so activity can pick it up if needed
            val prefs: SharedPreferences = context.getSharedPreferences("mindful_prefs", Context.MODE_PRIVATE)
            val json = "{\"event\":\"$eventType\",\"packageName\":\"$pkg\"}"
            prefs.edit().putString("pending_package_event", json).apply()

            // Broadcast an internal intent so MainActivity (if running) can forward immediately
            val i = Intent("com.auraless.app.PACKAGE_CHANGED_INTERNAL")
            i.putExtra("event", eventType)
            i.putExtra("packageName", pkg)
            context.sendBroadcast(i)
        } catch (e: Exception) {
            Log.w("PkgReceiver", "Failed to handle package change: ${e.localizedMessage}")
        }
    }
}
