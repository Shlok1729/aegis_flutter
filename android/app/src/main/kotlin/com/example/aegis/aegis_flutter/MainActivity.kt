package com.example.aegis.aegis_flutter

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val APPS_CHANNEL = "com.aegis.dev/apps"
    private val USAGE_CHANNEL = "com.aegis.dev/usage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Channel for installed apps + mitigation actions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APPS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    val apps = getInstalledApps()
                    result.success(apps)
                }
                "openAppSettings" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        intent.data = android.net.Uri.parse("package:$pkg")
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARG", "packageName required", null)
                    }
                }
                "openBatterySettings" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            intent.data = android.net.Uri.parse("package:$pkg")
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                        } catch (e: Exception) {
                            // Fallback to general battery settings
                            val intent = Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                        }
                        result.success(true)
                    } else {
                        result.error("INVALID_ARG", "packageName required", null)
                    }
                }
                "uninstallApp" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        val intent = Intent(Intent.ACTION_DELETE)
                        intent.data = android.net.Uri.parse("package:$pkg")
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARG", "packageName required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Channel for usage stats
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsagePermission" -> {
                    result.success(checkUsagePermission())
                }
                "openUsageSettings" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "getAppUsageStats" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val stats = getAppUsageStats(packageName)
                        result.success(stats)
                    } else {
                        result.error("INVALID_ARG", "packageName required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkUsagePermission(): Boolean {
        try {
            // Method 1: AppOpsManager — accept BOTH MODE_ALLOWED and MODE_DEFAULT
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    packageName
                )
            }
            if (mode == AppOpsManager.MODE_ALLOWED || mode == AppOpsManager.MODE_DEFAULT) return true

            // Method 2: Try querying over 7 days (wider window to avoid false negatives)
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val cal = Calendar.getInstance()
            val end = cal.timeInMillis
            cal.add(Calendar.DAY_OF_YEAR, -7)
            val start = cal.timeInMillis
            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_WEEKLY, start, end)
            return stats != null && stats.isNotEmpty()
        } catch (e: Exception) {
            return false
        }
    }

    private fun getAppUsageStats(targetPackage: String): Map<String, Any> {
        try {
            // Always try to query — skip unreliable permission checks
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val calendar = Calendar.getInstance()
            val endTime = calendar.timeInMillis
            calendar.add(Calendar.HOUR_OF_DAY, -24)
            val startTime = calendar.timeInMillis

            val events = usm.queryEvents(startTime, endTime)
            val hourlyCount = mutableMapOf<Int, Int>()

            for (i in 0..23) {
                hourlyCount[i] = 0
            }

            val event = UsageEvents.Event()
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.packageName == targetPackage) {
                    if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                        event.eventType == UsageEvents.Event.MOVE_TO_BACKGROUND) {
                        val eventCal = Calendar.getInstance()
                        eventCal.timeInMillis = event.timeStamp
                        val hour = eventCal.get(Calendar.HOUR_OF_DAY)
                        hourlyCount[hour] = (hourlyCount[hour] ?: 0) + 1
                    }
                }
            }

            return mapOf(
                "hasPermission" to true,
                "hourlyEvents" to hourlyCount
            )
        } catch (e: SecurityException) {
            return mapOf("hasPermission" to false, "hourlyEvents" to emptyMap<String, Int>())
        } catch (e: Exception) {
            return mapOf("hasPermission" to false, "hourlyEvents" to emptyMap<String, Int>())
        }
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val packages = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        val appList = mutableListOf<Map<String, Any>>()

        for (packageInfo in packages) {
            val isSystemApp = (packageInfo.applicationInfo?.flags ?: 0) and ApplicationInfo.FLAG_SYSTEM != 0
            val isUpdatedSystemApp = (packageInfo.applicationInfo?.flags ?: 0) and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP != 0
            
            if (isSystemApp && !isUpdatedSystemApp) {
                continue
            }

            val appName = packageInfo.applicationInfo?.loadLabel(pm).toString()
            val packageName = packageInfo.packageName
            val permissions = packageInfo.requestedPermissions?.toList() ?: emptyList<String>()

            val map = mapOf(
                "appName" to appName,
                "packageName" to packageName,
                "permissions" to permissions
            )
            appList.add(map)
        }
        return appList
    }
}
