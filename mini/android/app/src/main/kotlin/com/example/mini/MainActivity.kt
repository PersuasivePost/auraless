package com.example.mini

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.SystemClock
import android.util.Base64
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

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

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

		// placeholders for future channels
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_CHANNEL).setMethodCallHandler { _, r -> r.notImplemented() }
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GRAYSCALE_CHANNEL).setMethodCallHandler { _, r -> r.notImplemented() }
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTACTS_CHANNEL).setMethodCallHandler { _, r -> r.notImplemented() }
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
