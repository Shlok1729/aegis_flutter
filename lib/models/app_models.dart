enum RiskLevel { low, medium, high, critical }

class CveEntry {
  final String id;
  final String description;
  final String severity;
  final String publishedDate;

  const CveEntry({
    required this.id,
    required this.description,
    required this.severity,
    required this.publishedDate,
  });
}

class AppPermissionSummary {
  final String appName;
  final String packageName;
  final String intentCategory;
  final RiskLevel riskLevel;
  final List<String> permissions;
  final List<String> vulnerabilities;
  final bool isOutdated;
  final String versionName;
  final DateTime lastUpdate;
  final bool isIgnored;
  final int targetSdkVersion;
  final List<CveEntry> cveMatches;

  const AppPermissionSummary({
    required this.appName,
    required this.packageName,
    required this.intentCategory,
    required this.riskLevel,
    required this.permissions,
    this.vulnerabilities = const [],
    this.isOutdated = false,
    this.versionName = 'Unknown',
    required this.lastUpdate,
    this.isIgnored = false,
    this.targetSdkVersion = 33,
    this.cveMatches = const [],
  });
}

class DashboardState {
  final int privacyHealthScore;
  final int scannedAppsCount;
  final int riskyAppsCount;
  final int backgroundPingsBlocked;
  final int outdatedAppsCount;
  final int cveCount;
  final List<AppPermissionSummary> appsList;

  const DashboardState({
    this.privacyHealthScore = 100,
    this.scannedAppsCount = 0,
    this.riskyAppsCount = 0,
    this.backgroundPingsBlocked = 0,
    this.outdatedAppsCount = 0,
    this.cveCount = 0,
    this.appsList = const [],
  });
}

// Mock Data Provider
class MockData {
  static final state = DashboardState(
    privacyHealthScore: 68,
    scannedAppsCount: 84,
    riskyAppsCount: 1,
    backgroundPingsBlocked: 12,
    appsList: [
       AppPermissionSummary(
        appName: 'FlashlightPro',
        packageName: 'com.xyz.flashlight',
        intentCategory: 'Utility',
        riskLevel: RiskLevel.critical,
        permissions: ['Camera', 'Contacts', 'SMS'],
        vulnerabilities: [
          'Intent Gap: Utility app requesting Social data.',
          'Unreachable code: Outdated Ad SDK (CVE-2023-XXXX)'
        ],
        lastUpdate: DateTime.now().subtract(const Duration(days: 600)), // Over 18 months
        isOutdated: true,
      ),
       AppPermissionSummary(
        appName: 'SocialConnect',
        packageName: 'com.social.connect',
        intentCategory: 'Social',
        riskLevel: RiskLevel.medium,
        permissions: ['Camera', 'Microphone', 'Location'],
        lastUpdate: DateTime.now().subtract(const Duration(days: 30)),
      ),
       AppPermissionSummary(
        appName: 'BankSecure',
        packageName: 'com.bank.secure',
        intentCategory: 'Finance',
        riskLevel: RiskLevel.low,
        permissions: ['Location', 'Network'],
        lastUpdate: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ],
  );
}
