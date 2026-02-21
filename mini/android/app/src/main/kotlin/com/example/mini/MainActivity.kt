package com.example.mini

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.content.ComponentName
import android.view.accessibility.AccessibilityManager
import android.accessibilityservice.AccessibilityServiceInfo
import androidx.core.app.NotificationManagerCompat
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.SystemClock
import android.util.Base64
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.app.AppOpsManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.RandomAccessFile

class MainActivity : FlutterActivity() {
	private val APP_CHANNEL = "app_channel"
	private val SYS_CHANNEL = "system_info_channel"
	private val USAGE_CHANNEL = "usage_stats_channel"
	private val GRAYSCALE_CHANNEL = "grayscale_channel"
	private val CONTACTS_CHANNEL = "contacts_channel"
	private val BLOCKED_CHANNEL = "blocked_apps_channel"
	private val NOTIF_CHANNEL = "notification_channel"

	private val PACKAGE_CHANNEL = "package_channel"
	private val BATTERY_CHANNEL = "battery_channel"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		// Package channel - forwards install/uninstall/replace events
		val packageChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PACKAGE_CHANNEL)

		// Register a local receiver to pick up internal broadcasts from PackageChangeReceiver
		val br = object : android.content.BroadcastReceiver() {
			override fun onReceive(context: android.content.Context?, intent: android.content.Intent?) {
				try {
					val ev = intent?.getStringExtra("event") ?: return
					val pkg = intent.getStringExtra("packageName") ?: return
					val args = mapOf("event" to ev, "packageName" to pkg)
					packageChannel.invokeMethod("onPackageChanged", args)
				} catch (e: Exception) { }
			}
		}
		registerReceiver(br, android.content.IntentFilter("com.example.mini.PACKAGE_CHANGED_INTERNAL"))

		// If there is a pending event saved by the receiver before Flutter was ready, forward it now
		try {
			val prefs = getSharedPreferences("mindful_prefs", Context.MODE_PRIVATE)
			val pending = prefs.getString("pending_package_event", "") ?: ""
			if (pending.isNotEmpty()) {
				// parse crude json: {"event":"added","packageName":"pkg"}
				val ev = Regex("\"event\":\"(.*?)\"").find(pending)?.groups?.get(1)?.value ?: ""
				val pkg = Regex("\"packageName\":\"(.*?)\"").find(pending)?.groups?.get(1)?.value ?: ""
				if (ev.isNotEmpty() && pkg.isNotEmpty()) {
					val args = mapOf("event" to ev, "packageName" to pkg)
					packageChannel.invokeMethod("onPackageChanged", args)
				}
				prefs.edit().remove("pending_package_event").apply()
			}
		} catch (e: Exception) { }

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"getInstalledApps" -> {
					try {
						val apps = getInstalledApps()
						result.success(apps)
					} catch (e: Exception) {
						result.error("ERROR", e.localizedMessage, null)
					}
				}
				"openHomePicker" -> {
					try {
						val intent = Intent(Intent.ACTION_MAIN)
						intent.addCategory(Intent.CATEGORY_HOME)
						intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						startActivity(intent)
						result.success(null)
					} catch (e: Exception) {
						result.error("ERROR", e.localizedMessage, null)
					}
				}
				"launchApp" -> {
					val packageName = call.arguments as? String
					if (packageName != null) {
						val ok = launchApp(packageName)
						result.success(ok)
					} else {
						result.error("INVALID_ARGS", "packageName missing", null)
					}
				}
				else -> result.notImplemented()
			}
		}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"isIgnoringBatteryOptimizations" -> {
					try {
						val pm = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
						val ignoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) pm.isIgnoringBatteryOptimizations(applicationContext.packageName) else true
						result.success(ignoring)
					} catch (e: Exception) { result.error("ERROR", e.localizedMessage, null) }
				}
				"openBatteryOptimizationSettings" -> {
					try {
						val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
						intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						startActivity(intent)
						result.success(null)
					} catch (e: Exception) { result.error("ERROR", e.localizedMessage, null) }
				}
				else -> result.notImplemented()
			}
		}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYS_CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"getSystemInfo" -> {
					try {
						val info = getSystemInfoMap()
						result.success(info)
					} catch (e: Exception) {
						result.error("ERROR", e.localizedMessage, null)
					}
				}
				else -> result.notImplemented()
			}
		}

		// Usage stats channel
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"hasUsagePermission" -> {
					try {
						val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
						val mode = appOps.checkOpNoThrow(
							AppOpsManager.OPSTR_GET_USAGE_STATS,
							android.os.Process.myUid(),
							packageName
						)
						result.success(mode == AppOpsManager.MODE_ALLOWED)
					} catch (e: Exception) {
						result.error("ERROR", e.localizedMessage, null)
					}
				}
				"getUsageStats" -> {
					try {
						val args = call.arguments as? Map<*, *>
						val start = (args?.get("start") as? Number)?.toLong() ?: 0L
						val end = (args?.get("end") as? Number)?.toLong() ?: System.currentTimeMillis()

						val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
						val stats: List<UsageStats> = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)

						val mapped = stats.map { s ->
							mapOf(
								"packageName" to s.packageName,
								"totalTimeInForeground" to s.totalTimeInForeground
							)
						}
						result.success(mapped)
					} catch (e: Exception) {
						result.error("ERROR", e.localizedMessage, null)
					}
				}
				"requestUsagePermission" -> {
					try {
						val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
						intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						startActivity(intent)
						result.success(null)
					} catch (e: Exception) {
						result.error("ERROR", e.localizedMessage, null)
					}
				}
				else -> result.notImplemented()
			}
		}

		// Grayscale channel: enable/disable monochrome display (requires WRITE_SECURE_SETTINGS)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GRAYSCALE_CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"enableGrayscale" -> {
					try {
						val ok1 = Settings.Secure.putString(contentResolver, "accessibility_display_daltonizer_enabled", "1")
						val ok2 = Settings.Secure.putString(contentResolver, "accessibility_display_daltonizer", "0")
						result.success(ok1 && ok2)
					} catch (se: SecurityException) {
						result.error("PERMISSION_DENIED", se.localizedMessage, null)
					} catch (e: Exception) {
						result.error("ERROR", e.localizedMessage, null)
					}
				}
					"isGrayscaleEnabled" -> {
						try {
							val enabled = Settings.Secure.getInt(contentResolver, "accessibility_display_daltonizer_enabled", 0) == 1
							val daltonizer = Settings.Secure.getString(contentResolver, "accessibility_display_daltonizer")
							result.success(enabled && daltonizer == "0")
						} catch (e: Exception) {
							result.error("ERROR", e.localizedMessage, null)
						}
					}
				"disableGrayscale" -> {
					try {
						val ok = Settings.Secure.putString(contentResolver, "accessibility_display_daltonizer_enabled", "0")
						result.success(ok)
					} catch (se: SecurityException) {
						result.error("PERMISSION_DENIED", se.localizedMessage, null)
					} catch (e: Exception) {
						result.error("ERROR", e.localizedMessage, null)
					}
				}
				else -> result.notImplemented()
			}
		}
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTACTS_CHANNEL).setMethodCallHandler { _, r -> r.notImplemented() }

		// Blocked apps channel - uses SharedPreferences to maintain comma-separated list
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLOCKED_CHANNEL).setMethodCallHandler { call, result ->
			try {
				val prefs = getSharedPreferences("mindful_prefs", Context.MODE_PRIVATE)
				val key = "blocked_packages"
				when (call.method) {
					"addBlockedApp" -> {
						val pkg = call.arguments as? String
						if (pkg != null) {
							val csv = prefs.getString(key, "") ?: ""
							val set = csv.split(',').map { it.trim() }.filter { it.isNotEmpty() }.toMutableList()
							if (!set.contains(pkg)) {
								set.add(pkg)
								prefs.edit().putString(key, set.joinToString(",")).apply()
							}
							result.success(null)
						} else {
							result.error("INVALID_ARGS", "packageName missing", null)
						}
					}

				// Accessibility check channel
				MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "accessibility_check_channel").setMethodCallHandler { call, result ->
					when (call.method) {
								"isAccessibilityServiceEnabled" -> {
									try {
										val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
										val list = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
										// Be flexible: match by declared service class name or package + class
										val present = list.any { si ->
											val ri = si.resolveInfo ?: return@any false
											val pkg = ri.serviceInfo.packageName ?: ""
											val name = ri.serviceInfo.name ?: ""
											// Match if the class name matches our listener class or the package matches this app
											name.endsWith("MindfulAccessibilityService") || pkg == applicationContext.packageName && name.contains("MindfulAccessibilityService")
										}
										result.success(present)
									} catch (e: Exception) {
										result.error("ERROR", e.localizedMessage, null)
									}
								}
						else -> result.notImplemented()
					}
				}

				// Notification listener check channel
				MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "notification_listener_check_channel").setMethodCallHandler { call, result ->
					when (call.method) {
						"isNotificationListenerEnabled" -> {
								try {
									// Check via NotificationManagerCompat for enabled packages
									val enabledViaCompat = NotificationManagerCompat.getEnabledListenerPackages(this).contains(applicationContext.packageName)
									// Also check enabled_notification_listeners secure setting as a fallback
									val enabledSetting = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: ""
									val presentInSettings = enabledSetting.contains(applicationContext.packageName)
									result.success(enabledViaCompat || presentInSettings)
								} catch (e: Exception) {
									result.error("ERROR", e.localizedMessage, null)
								}
							}
						else -> result.notImplemented()
					}
				}
					"removeBlockedApp" -> {
						val pkg = call.arguments as? String
						if (pkg != null) {
							val csv = prefs.getString(key, "") ?: ""
							val set = csv.split(',').map { it.trim() }.filter { it.isNotEmpty() }.toMutableList()
							if (set.contains(pkg)) {
								set.remove(pkg)
								prefs.edit().putString(key, set.joinToString(",")).apply()
							}
							result.success(null)
						} else {
							result.error("INVALID_ARGS", "packageName missing", null)
						}
					}
					"getBlockedApps" -> {
						val csv = prefs.getString(key, "") ?: ""
						val list = csv.split(',').map { it.trim() }.filter { it.isNotEmpty() }
						result.success(list)
					}
					"isAccessibilityServiceEnabled" -> {
						// Check enabled accessibility services string for our service by package or class name
						try {
							val enabled = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
							val serviceComponent = "${applicationContext.packageName}/.MindfulAccessibilityService"
							val present = enabled?.contains(serviceComponent) == true || enabled?.contains("MindfulAccessibilityService") == true
							result.success(present)
						} catch (e: Exception) {
							result.error("ERROR", e.localizedMessage, null)
						}
					}
					"openAccessibilitySettings" -> {
						try {
							val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
							intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
							startActivity(intent)
							result.success(null)
						} catch (e: Exception) {
							result.error("ERROR", e.localizedMessage, null)
						}
					}
					"setMindfulDelaySeconds" -> {
						val v = (call.arguments as? Number)?.toInt() ?: 30
						prefs.edit().putInt("mindful_delay_seconds", v).apply()
						result.success(null)
					}
					"getMindfulDelaySeconds" -> {
						val v = prefs.getInt("mindful_delay_seconds", 30)
						result.success(v)
					}
					else -> result.notImplemented()
				}
			} catch (e: Exception) {
				result.error("ERROR", e.localizedMessage, null)
			}
		}

		// Notification channel - digest storage and essential whitelist
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIF_CHANNEL).setMethodCallHandler { call, result ->
			try {
				val prefs = getSharedPreferences("mindful_prefs", Context.MODE_PRIVATE)
				val digestKey = "notification_digest"
				val essentialKey = "essential_packages"
				when (call.method) {
					"getNotificationDigest" -> {
						val json = prefs.getString(digestKey, "") ?: ""
						if (json.isEmpty()) result.success(listOf<Map<String, Any>>()) else result.success(org.json.JSONArray(json).let { arr ->
							val out = mutableListOf<Map<String, Any>>()
							for (i in 0 until arr.length()) {
								val o = arr.getJSONObject(i)
								val map = mapOf(
									"package" to o.optString("package"),
									"title" to o.optString("title"),
									"text" to o.optString("text"),
									"postTime" to o.optLong("postTime")
								)
								out.add(map)
							}
							out
						})
				}
					"clearNotificationDigest" -> {
						prefs.edit().putString(digestKey, "").apply()
						result.success(null)
					}
					"addEssentialPackage" -> {
						val pkg = call.arguments as? String
						if (pkg != null) {
							val csv = prefs.getString(essentialKey, "") ?: ""
							val set = csv.split(',').map { it.trim() }.filter { it.isNotEmpty() }.toMutableList()
							if (!set.contains(pkg)) {
								set.add(pkg)
								prefs.edit().putString(essentialKey, set.joinToString(",")).apply()
							}
							result.success(null)
						} else result.error("INVALID_ARGS", "packageName missing", null)
					}
					"removeEssentialPackage" -> {
						val pkg = call.arguments as? String
						if (pkg != null) {
							val csv = prefs.getString(essentialKey, "") ?: ""
							val set = csv.split(',').map { it.trim() }.filter { it.isNotEmpty() }.toMutableList()
							if (set.contains(pkg)) {
								set.remove(pkg)
								prefs.edit().putString(essentialKey, set.joinToString(",")).apply()
							}
							result.success(null)
						} else result.error("INVALID_ARGS", "packageName missing", null)
					}
					"getEssentialPackages" -> {
						val csv = prefs.getString(essentialKey, "") ?: ""
						val list = csv.split(',').map { it.trim() }.filter { it.isNotEmpty() }
						result.success(list)
					}
							"openNotificationListenerSettings" -> {
								try {
									val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
									intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
									startActivity(intent)
									result.success(null)
								} catch (e: Exception) {
									result.error("ERROR", e.localizedMessage, null)
								}
							}
							"isNotificationListenerEnabled" -> {
								try {
									val enabled = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: ""
									val present = enabled.contains(applicationContext.packageName)
									result.success(present)
								} catch (e: Exception) {
									result.error("ERROR", e.localizedMessage, null)
								}
							}
					else -> result.notImplemented()
				}
			} catch (e: Exception) {
				result.error("ERROR", e.localizedMessage, null)
			}
		}
	}

	private fun getInstalledApps(): List<Map<String, Any?>> {
		val pm = packageManager
		val apps = mutableListOf<Map<String, Any?>>()
		val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
		val myPackage = applicationContext.packageName
		for (app in packages) {
			// only include launchable apps
			val launchIntent = pm.getLaunchIntentForPackage(app.packageName)
			if (launchIntent != null && app.packageName != myPackage) {
				val label = pm.getApplicationLabel(app).toString()
				// icon conversion to byte[] is optional; return null for now
				apps.add(mapOf("name" to label, "packageName" to app.packageName, "icon" to null))
			}
		}
		// sort by name
		apps.sortBy { (it["name"] as? String) ?: "" }
		return apps
	}

	private fun launchApp(pkg: String): Boolean {
		val pm = packageManager
		val intent = pm.getLaunchIntentForPackage(pkg)
		return if (intent != null) {
			intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			startActivity(intent)
			true
		} else false
	}

	private fun getSystemInfoMap(): Map<String, Any?> {
		val battery = getBatteryPercent()
		val ram = getRamInfo()
		val storage = getStorageInfo()
		val network = getNetworkType()
		val kernel = getKernelVersion()
		val uptimeMinutes = SystemClock.elapsedRealtime() / 60000

		return mapOf(
			"model" to Build.MODEL,
			"manufacturer" to Build.MANUFACTURER,
			"androidVersion" to Build.VERSION.RELEASE,
			"apiLevel" to Build.VERSION.SDK_INT,
			"kernelVersion" to kernel,
			"uptimeMinutes" to uptimeMinutes,
			"batteryPercent" to battery,
			"ramUsed" to ram["used"],
			"ramTotal" to ram["total"],
			"storageUsed" to storage["used"],
			"storageTotal" to storage["total"],
			"networkType" to network
		)
	}

	private fun getBatteryPercent(): Int? {
		return try {
			val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
			val level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
			if (level >= 0) level else null
		} catch (e: Exception) {
			null
		}
	}

	private fun getRamInfo(): Map<String, Long> {
		val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
		val mi = ActivityManager.MemoryInfo()
		am.getMemoryInfo(mi)
		val total = mi.totalMem
		val avail = mi.availMem
		val used = total - avail
		return mapOf("total" to total, "used" to used)
	}

	private fun getStorageInfo(): Map<String, Long> {
		return try {
			val path: File = Environment.getDataDirectory()
			val stat = StatFs(path.path)
			val blockSize = stat.blockSizeLong
			val totalBlocks = stat.blockCountLong
			val availableBlocks = stat.availableBlocksLong
			val total = totalBlocks * blockSize
			val available = availableBlocks * blockSize
			val used = total - available
			mapOf("total" to total, "used" to used)
		} catch (e: Exception) {
			mapOf("total" to 0L, "used" to 0L)
		}
	}

	private fun getNetworkType(): String? {
		return try {
			val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
			val nw = cm.activeNetwork ?: return null
			val caps = cm.getNetworkCapabilities(nw) ?: return null
			when {
				caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "WIFI"
				caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "CELLULAR"
				caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ETHERNET"
				else -> "UNKNOWN"
			}
		} catch (e: Exception) {
			null
		}
	}

	private fun getKernelVersion(): String? {
		return try {
			// Attempt to read /proc/version
			val f = RandomAccessFile("/proc/version", "r")
			val line = f.readLine()
			f.close()
			line
		} catch (e: Exception) {
			System.getProperty("os.version")
		}
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		setIntent(intent)
	}
}
