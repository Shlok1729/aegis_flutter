/// Types of sensors that can be accessed in the background.
enum SensorType { camera, microphone, location }

/// Represents a single sensor access event logged by the system.
class SensorAccessEvent {
  final SensorType sensorType;
  final String appName;
  final String packageName;
  final DateTime timestamp;
  final Duration duration;
  final bool wasInForeground;
  final String accessReason; // e.g. "Background service", "Push notification", etc.

  const SensorAccessEvent({
    required this.sensorType,
    required this.appName,
    required this.packageName,
    required this.timestamp,
    required this.duration,
    required this.wasInForeground,
    this.accessReason = 'Unknown',
  });

  bool get isShadowAccess => !wasInForeground;
}

/// Summary stats for a single sensor type.
class SensorSummary {
  final SensorType sensorType;
  final int totalAccesses;
  final int backgroundAccesses;
  final Duration totalDuration;

  const SensorSummary({
    required this.sensorType,
    required this.totalAccesses,
    required this.backgroundAccesses,
    required this.totalDuration,
  });

  double get shadowPercentage =>
      totalAccesses > 0 ? (backgroundAccesses / totalAccesses) * 100 : 0;
}

/// Complete report for temporal blindness analysis.
class TemporalBlindnessReport {
  final int totalEvents;
  final int totalShadowEvents;
  final List<SensorSummary> sensorSummaries;
  final List<SensorAccessEvent> events;

  const TemporalBlindnessReport({
    required this.totalEvents,
    required this.totalShadowEvents,
    required this.sensorSummaries,
    required this.events,
  });
}

/// Mock data generator for Temporal Blindness Monitor
class TemporalBlindnessMockData {
  static final DateTime _now = DateTime.now();

  static final List<SensorAccessEvent> events = [
    // Camera accesses
    SensorAccessEvent(
      sensorType: SensorType.camera,
      appName: 'FlashlightPro',
      packageName: 'com.xyz.flashlight',
      timestamp: _now.subtract(const Duration(hours: 2, minutes: 14)),
      duration: const Duration(seconds: 45),
      wasInForeground: false,
      accessReason: 'Background service',
    ),
    SensorAccessEvent(
      sensorType: SensorType.camera,
      appName: 'SocialConnect',
      packageName: 'com.social.connect',
      timestamp: _now.subtract(const Duration(hours: 5, minutes: 30)),
      duration: const Duration(minutes: 2, seconds: 10),
      wasInForeground: true,
      accessReason: 'User opened camera',
    ),
    SensorAccessEvent(
      sensorType: SensorType.camera,
      appName: 'FlashlightPro',
      packageName: 'com.xyz.flashlight',
      timestamp: _now.subtract(const Duration(hours: 8, minutes: 45)),
      duration: const Duration(seconds: 12),
      wasInForeground: false,
      accessReason: 'Background analytics SDK',
    ),
    SensorAccessEvent(
      sensorType: SensorType.camera,
      appName: 'FlashlightPro',
      packageName: 'com.xyz.flashlight',
      timestamp: _now.subtract(const Duration(hours: 14, minutes: 20)),
      duration: const Duration(seconds: 8),
      wasInForeground: false,
      accessReason: 'Triggered by push notification',
    ),
    // Microphone accesses
    SensorAccessEvent(
      sensorType: SensorType.microphone,
      appName: 'FlashlightPro',
      packageName: 'com.xyz.flashlight',
      timestamp: _now.subtract(const Duration(hours: 1, minutes: 10)),
      duration: const Duration(minutes: 1, seconds: 32),
      wasInForeground: false,
      accessReason: 'Background service',
    ),
    SensorAccessEvent(
      sensorType: SensorType.microphone,
      appName: 'SocialConnect',
      packageName: 'com.social.connect',
      timestamp: _now.subtract(const Duration(hours: 3, minutes: 55)),
      duration: const Duration(minutes: 5),
      wasInForeground: true,
      accessReason: 'Voice message recording',
    ),
    SensorAccessEvent(
      sensorType: SensorType.microphone,
      appName: 'WeatherNow',
      packageName: 'com.weather.now',
      timestamp: _now.subtract(const Duration(hours: 7, minutes: 12)),
      duration: const Duration(seconds: 22),
      wasInForeground: false,
      accessReason: 'Embedded SDK audio fingerprinting',
    ),
    SensorAccessEvent(
      sensorType: SensorType.microphone,
      appName: 'FlashlightPro',
      packageName: 'com.xyz.flashlight',
      timestamp: _now.subtract(const Duration(hours: 19, minutes: 40)),
      duration: const Duration(seconds: 55),
      wasInForeground: false,
      accessReason: 'Background analytics',
    ),
    // Location accesses
    SensorAccessEvent(
      sensorType: SensorType.location,
      appName: 'WeatherNow',
      packageName: 'com.weather.now',
      timestamp: _now.subtract(const Duration(hours: 0, minutes: 30)),
      duration: const Duration(seconds: 5),
      wasInForeground: true,
      accessReason: 'Weather location update',
    ),
    SensorAccessEvent(
      sensorType: SensorType.location,
      appName: 'FlashlightPro',
      packageName: 'com.xyz.flashlight',
      timestamp: _now.subtract(const Duration(hours: 4, minutes: 15)),
      duration: const Duration(seconds: 18),
      wasInForeground: false,
      accessReason: 'Ad targeting SDK',
    ),
    SensorAccessEvent(
      sensorType: SensorType.location,
      appName: 'QuickNotes',
      packageName: 'com.quick.notes',
      timestamp: _now.subtract(const Duration(hours: 6, minutes: 50)),
      duration: const Duration(seconds: 30),
      wasInForeground: false,
      accessReason: 'Geo-fencing SDK',
    ),
    SensorAccessEvent(
      sensorType: SensorType.location,
      appName: 'BankSecure',
      packageName: 'com.bank.secure',
      timestamp: _now.subtract(const Duration(hours: 10, minutes: 5)),
      duration: const Duration(seconds: 3),
      wasInForeground: true,
      accessReason: 'Branch locator',
    ),
  ];

  static TemporalBlindnessReport get report {
    final shadowEvents = events.where((e) => e.isShadowAccess).toList();
    return TemporalBlindnessReport(
      totalEvents: events.length,
      totalShadowEvents: shadowEvents.length,
      sensorSummaries: [
        SensorSummary(
          sensorType: SensorType.camera,
          totalAccesses: events.where((e) => e.sensorType == SensorType.camera).length,
          backgroundAccesses: events.where((e) => e.sensorType == SensorType.camera && e.isShadowAccess).length,
          totalDuration: const Duration(minutes: 3, seconds: 15),
        ),
        SensorSummary(
          sensorType: SensorType.microphone,
          totalAccesses: events.where((e) => e.sensorType == SensorType.microphone).length,
          backgroundAccesses: events.where((e) => e.sensorType == SensorType.microphone && e.isShadowAccess).length,
          totalDuration: const Duration(minutes: 8, seconds: 49),
        ),
        SensorSummary(
          sensorType: SensorType.location,
          totalAccesses: events.where((e) => e.sensorType == SensorType.location).length,
          backgroundAccesses: events.where((e) => e.sensorType == SensorType.location && e.isShadowAccess).length,
          totalDuration: const Duration(minutes: 0, seconds: 56),
        ),
      ],
      events: events,
    );
  }
}
