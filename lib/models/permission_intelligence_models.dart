import 'app_models.dart';

/// Whether a permission is contextually justified for the app's intent category.
enum PermissionJustification { justified, questionable, anomalous }

/// A single permission analyzed contextually against the app's stated purpose.
class PermissionContext {
  final String permissionName;
  final PermissionJustification justification;
  final double anomalyScore; // 0.0 (normal) to 1.0 (highly anomalous)
  final String reasoning;

  const PermissionContext({
    required this.permissionName,
    required this.justification,
    required this.anomalyScore,
    required this.reasoning,
  });
}

/// An app analyzed for contextual permission intelligence.
class PermissionIntelligenceApp {
  final String appName;
  final String packageName;
  final String intentCategory;
  final double overallAnomalyScore; // 0.0 to 1.0
  final RiskLevel riskLevel;
  final List<PermissionContext> permissions;
  final String analysisNote;

  const PermissionIntelligenceApp({
    required this.appName,
    required this.packageName,
    required this.intentCategory,
    required this.overallAnomalyScore,
    required this.riskLevel,
    required this.permissions,
    this.analysisNote = '',
  });
}

/// Mock data for Contextual Permission Intelligence
class PermissionIntelligenceMockData {
  static const List<PermissionIntelligenceApp> apps = [
    // HIGH ANOMALY: Calculator asking for GPS, Contacts, Mic
    PermissionIntelligenceApp(
      appName: 'CalcMaster Pro',
      packageName: 'com.calcmaster.pro',
      intentCategory: 'Utility / Calculator',
      overallAnomalyScore: 0.92,
      riskLevel: RiskLevel.critical,
      analysisNote:
          'A calculator app should only need basic storage access. Requesting GPS, Contacts, and Microphone strongly suggests data harvesting behavior.',
      permissions: [
        PermissionContext(
          permissionName: 'GPS / Location',
          justification: PermissionJustification.anomalous,
          anomalyScore: 0.98,
          reasoning:
              'No contextual justification for a calculator app to access location data.',
        ),
        PermissionContext(
          permissionName: 'Contacts',
          justification: PermissionJustification.anomalous,
          anomalyScore: 0.95,
          reasoning:
              'Contact access is never needed for mathematical computation.',
        ),
        PermissionContext(
          permissionName: 'Microphone',
          justification: PermissionJustification.anomalous,
          anomalyScore: 0.90,
          reasoning:
              'Microphone access in a calculator app indicates potential audio surveillance.',
        ),
        PermissionContext(
          permissionName: 'Storage',
          justification: PermissionJustification.justified,
          anomalyScore: 0.05,
          reasoning: 'Storage is reasonable for saving calculation history.',
        ),
      ],
    ),

    // MEDIUM ANOMALY: Flashlight app with Contacts + SMS
    PermissionIntelligenceApp(
      appName: 'FlashlightPro',
      packageName: 'com.xyz.flashlight',
      intentCategory: 'Utility / Flashlight',
      overallAnomalyScore: 0.78,
      riskLevel: RiskLevel.high,
      analysisNote:
          'Flashlight utility is requesting social-graph data (Contacts, SMS) inconsistent with its stated purpose.',
      permissions: [
        PermissionContext(
          permissionName: 'Camera',
          justification: PermissionJustification.justified,
          anomalyScore: 0.05,
          reasoning: 'Camera access is required to control the flashlight LED.',
        ),
        PermissionContext(
          permissionName: 'Contacts',
          justification: PermissionJustification.anomalous,
          anomalyScore: 0.92,
          reasoning: 'No contextual justification for flashlight to read contacts.',
        ),
        PermissionContext(
          permissionName: 'SMS',
          justification: PermissionJustification.anomalous,
          anomalyScore: 0.95,
          reasoning:
              'SMS access in a flashlight app is a strong indicator of premium SMS fraud or data theft.',
        ),
      ],
    ),

    // LOW ANOMALY: Maps app with Location
    PermissionIntelligenceApp(
      appName: 'MapNavigator',
      packageName: 'com.map.navigator',
      intentCategory: 'Navigation / Maps',
      overallAnomalyScore: 0.08,
      riskLevel: RiskLevel.low,
      analysisNote:
          'All permissions are contextually justified for a navigation application.',
      permissions: [
        PermissionContext(
          permissionName: 'GPS / Location',
          justification: PermissionJustification.justified,
          anomalyScore: 0.02,
          reasoning: 'Location is essential for navigation and map rendering.',
        ),
        PermissionContext(
          permissionName: 'Network',
          justification: PermissionJustification.justified,
          anomalyScore: 0.01,
          reasoning:
              'Network access needed to download map tiles and route data.',
        ),
        PermissionContext(
          permissionName: 'Storage',
          justification: PermissionJustification.justified,
          anomalyScore: 0.03,
          reasoning: 'Storage for offline map caching is standard.',
        ),
      ],
    ),

    // QUESTIONABLE: Weather app with unusual permissions
    PermissionIntelligenceApp(
      appName: 'WeatherNow',
      packageName: 'com.weather.now',
      intentCategory: 'Weather / Utility',
      overallAnomalyScore: 0.55,
      riskLevel: RiskLevel.medium,
      analysisNote:
          'Location is justified for weather, but microphone access is unusual and warrants investigation.',
      permissions: [
        PermissionContext(
          permissionName: 'GPS / Location',
          justification: PermissionJustification.justified,
          anomalyScore: 0.05,
          reasoning: 'Location needed to provide local weather data.',
        ),
        PermissionContext(
          permissionName: 'Microphone',
          justification: PermissionJustification.questionable,
          anomalyScore: 0.72,
          reasoning:
              'Microphone access in a weather app is unusual. May be used for cross-device audio beacon tracking by an embedded SDK.',
        ),
        PermissionContext(
          permissionName: 'Network',
          justification: PermissionJustification.justified,
          anomalyScore: 0.02,
          reasoning: 'Network needed to fetch weather data from APIs.',
        ),
      ],
    ),

    // SAFE: Banking app
    PermissionIntelligenceApp(
      appName: 'BankSecure',
      packageName: 'com.bank.secure',
      intentCategory: 'Finance / Banking',
      overallAnomalyScore: 0.05,
      riskLevel: RiskLevel.low,
      analysisNote:
          'All permissions are contextually appropriate for a banking application.',
      permissions: [
        PermissionContext(
          permissionName: 'Location',
          justification: PermissionJustification.justified,
          anomalyScore: 0.08,
          reasoning:
              'Location used for branch/ATM finder and fraud detection.',
        ),
        PermissionContext(
          permissionName: 'Network',
          justification: PermissionJustification.justified,
          anomalyScore: 0.01,
          reasoning: 'Network essential for banking transactions.',
        ),
        PermissionContext(
          permissionName: 'Biometrics',
          justification: PermissionJustification.justified,
          anomalyScore: 0.02,
          reasoning:
              'Biometrics used for secure authentication, standard for banking.',
        ),
      ],
    ),
  ];
}
