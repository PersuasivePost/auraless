package com.yourname.devlauncher

import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

class NotificationListener : NotificationListenerService() {
    private val PREFS = "mindful_prefs"
    private val KEY_DIGEST = "notification_digest"
    private val KEY_ESSENTIAL = "essential_packages"

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val pkg = sbn.packageName ?: return
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val essCsv = prefs.getString(KEY_ESSENTIAL, "") ?: ""
        val essentials = essCsv.split(',').map { it.trim() }.filter { it.isNotEmpty() }

        // Cancel if not essential
        if (!essentials.contains(pkg)) {
            try {
                cancelNotification(sbn.key)
            } catch (e: Exception) {
                Log.w("NotifListener", "Failed to cancel notif: ${e.localizedMessage}")
            }
        }

        // Store notification in digest (append, keep last 50)
        try {
            val arrStr = prefs.getString(KEY_DIGEST, "") ?: ""
            val arr = if (arrStr.isNotEmpty()) JSONArray(arrStr) else JSONArray()

            val notif = sbn.notification
            val extras = notif.extras
            val title = extras.getString("android.title") ?: ""
            val text = (extras.getCharSequence("android.text") ?: "").toString()

            val obj = JSONObject()
            obj.put("package", pkg)
            obj.put("title", title)
            obj.put("text", text)
            obj.put("postTime", sbn.postTime)

            arr.put(obj)

            // cap to last 50 entries
            val capped = JSONArray()
            val start = if (arr.length() > 50) arr.length() - 50 else 0
            for (i in start until arr.length()) capped.put(arr.get(i))

            prefs.edit().putString(KEY_DIGEST, capped.toString()).apply()
        } catch (e: Exception) {
            Log.w("NotifListener", "Failed to store notif: ${e.localizedMessage}")
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // No-op
    }
}
