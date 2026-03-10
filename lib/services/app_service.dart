import 'package:flutter/services.dart';
import '../models/app_models.dart';

class AppService {
  static const MethodChannel _channel = MethodChannel('com.aegis.dev/apps');

  static Future<List<AppPermissionSummary>> fetchInstalledApps() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getInstalledApps');
      
      return result.map((app) {
        final Map<String, dynamic> appMap = Map<String, dynamic>.from(app);
        final String appName = appMap['appName'] ?? 'Unknown App';
        final String packageName = appMap['packageName'] ?? 'unknown.package';
        final List<String> rawPermissions = (appMap['permissions'] as List<dynamic>?)?.cast<String>() ?? [];
        
        // Clean up permissions (remove 'android.permission.' prefix for readability)
        final List<String> permissions = rawPermissions.map((p) {
          return p.replaceFirst('android.permission.', '');
        }).toList();

        final int targetSdkVersion = appMap['targetSdkVersion'] ?? 33;
        // Android 11 (API 30) introduced mandatory scoped storage and background location limits.
        // Targeting < 30 means bypassing modern security boundaries.
        final bool isOutdated = targetSdkVersion < 30;

        // Basic heuristic for intent & risk level
        String intentCategory = _determineIntent(packageName, permissions);
        RiskLevel riskLevel = _determineRisk(intentCategory, permissions, isOutdated);
        List<String> vulnerabilities = _detectVulnerabilities(intentCategory, permissions, isOutdated);

        return AppPermissionSummary(
          appName: appName,
          packageName: packageName,
          intentCategory: intentCategory,
          riskLevel: riskLevel,
          permissions: permissions,
          vulnerabilities: vulnerabilities,
          isOutdated: isOutdated,
        );
      }).toList();
    } catch (e) {
      print('Failed to get installed apps: $e');
      return [];
    }
  }

  // Dangerous permissions that indicate real privacy risk
  static const Set<String> dangerousPermissions = {
    'READ_SMS', 'SEND_SMS', 'RECEIVE_SMS',
    'READ_CALL_LOG', 'WRITE_CALL_LOG', 'PROCESS_OUTGOING_CALLS',
    'READ_CONTACTS', 'WRITE_CONTACTS',
    'CAMERA', 'RECORD_AUDIO',
    'ACCESS_FINE_LOCATION', 'ACCESS_BACKGROUND_LOCATION',
    'READ_PHONE_STATE', 'READ_PHONE_NUMBERS',
    'SYSTEM_ALERT_WINDOW',
    'READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE',
    'MANAGE_EXTERNAL_STORAGE',
  };

  static String _determineIntent(String packageName, List<String> permissions) {
    packageName = packageName.toLowerCase();
    if (packageName.contains('whatsapp') || packageName.contains('telegram') ||
        packageName.contains('msg') || packageName.contains('messenger') ||
        packageName.contains('chat') || packageName.contains('signal')) {
      return 'Communication';
    } else if (packageName.contains('facebook') || packageName.contains('instagram') ||
        packageName.contains('twitter') || packageName.contains('tiktok') ||
        packageName.contains('snapchat') || packageName.contains('social') ||
        packageName.contains('reddit')) {
      return 'Social';
    } else if (packageName.contains('bank') || packageName.contains('pay') ||
        packageName.contains('gpay') || packageName.contains('upi') ||
        packageName.contains('paytm') || packageName.contains('phonepe') ||
        packageName.contains('finance') || packageName.contains('wallet')) {
      return 'Finance';
    } else if (packageName.contains('game') || packageName.contains('play') ||
        packageName.contains('puzzle') || packageName.contains('racing')) {
      return 'Game';
    } else if (packageName.contains('camera') || packageName.contains('photo') ||
        packageName.contains('gallery') || packageName.contains('video') ||
        packageName.contains('music') || packageName.contains('player')) {
      return 'Media';
    } else if (packageName.contains('shop') || packageName.contains('amazon') ||
        packageName.contains('flipkart') || packageName.contains('myntra') ||
        packageName.contains('swiggy') || packageName.contains('zomato')) {
      return 'Shopping';
    } else if (packageName.contains('google') || packageName.contains('samsung') ||
        packageName.contains('oneui') || packageName.contains('android')) {
      return 'System';
    }
    return 'Utility';
  }

  static RiskLevel _determineRisk(String intentCategory, List<String> permissions, bool isOutdated) {
    // Count how many truly dangerous permissions this app requests
    int dangerousCount = permissions.where((p) => dangerousPermissions.contains(p)).length;

    // System/Communication/Social apps legitimately need more permissions
    bool isTrustedCategory = intentCategory == 'System' || 
        intentCategory == 'Communication' || intentCategory == 'Finance';

    // Check for especially suspicious combos
    bool hasSmsAccess = permissions.contains('READ_SMS') || permissions.contains('SEND_SMS');
    bool hasCallLogAccess = permissions.contains('READ_CALL_LOG');
    bool hasBackgroundLocation = permissions.contains('ACCESS_BACKGROUND_LOCATION');
    bool hasSystemAlert = permissions.contains('SYSTEM_ALERT_WINDOW');

    if (isTrustedCategory) {
      // Trusted category apps: only flag if they have extreme permission sets
      if (dangerousCount >= 10) return RiskLevel.high;
      if (dangerousCount >= 6) return RiskLevel.medium;
      return RiskLevel.low;
    }

    // For games/utilities/media — suspicious if they request SMS, call logs, etc.
    int suspicionScore = 0;
    if (hasSmsAccess) suspicionScore += 3;
    if (hasCallLogAccess) suspicionScore += 3;
    if (hasBackgroundLocation) suspicionScore += 2;
    if (hasSystemAlert) suspicionScore += 2;
    suspicionScore += (dangerousCount > 3 ? dangerousCount - 3 : 0); // extra danger past 3

    if (suspicionScore >= 6) return RiskLevel.critical;
    if (suspicionScore >= 4) return RiskLevel.high;
    if (suspicionScore >= 2 || isOutdated) return RiskLevel.medium;
    return RiskLevel.low;
  }

  static List<String> _detectVulnerabilities(String intent, List<String> permissions, bool isOutdated) {
    List<String> vulns = [];
    if (isOutdated) {
      vulns.add('Outdated App: Targeting old Android SDK. High risk of unpatched exploits.');
    }
    if ((intent == 'Utility' || intent == 'Game' || intent == 'Media') &&
        (permissions.contains('READ_SMS') || permissions.contains('SEND_SMS'))) {
      vulns.add('Intent Mismatch: $intent app can read/send SMS messages.');
    }
    if ((intent == 'Game' || intent == 'Utility') && permissions.contains('ACCESS_BACKGROUND_LOCATION')) {
      vulns.add('Background location tracking is suspicious for a $intent app.');
    }
    if (intent == 'Game' && permissions.contains('READ_CONTACTS')) {
      vulns.add('$intent app is accessing your contact list.');
    }
    if (permissions.contains('SYSTEM_ALERT_WINDOW') && intent != 'System') {
      vulns.add('Can draw overlays on other apps (potential screen capture risk).');
    }
    if (permissions.contains('READ_CALL_LOG') && intent != 'Communication' && intent != 'System') {
      vulns.add('Reading call logs without clear need — potential data harvesting.');
    }
    return vulns;
  }
}
