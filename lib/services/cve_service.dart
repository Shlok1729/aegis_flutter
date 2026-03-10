import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';

class CveService {
  static const String _baseUrl = 'https://services.nvd.nist.gov/rest/json/cves/2.0';

  /// Mapping from Android API level to Android version number string.
  static const Map<int, String> _sdkToAndroidVersion = {
    21: '5.0', 22: '5.1',
    23: '6.0',
    24: '7.0', 25: '7.1',
    26: '8.0', 27: '8.1',
    28: '9',
    29: '10',
    30: '11',
    31: '12', 32: '12',
    33: '13',
    34: '14',
    35: '15',
  };

  /// Fetch RECENT Android CVEs from NIST NVD.
  /// Uses lastModStartDate to get recently modified/published CVEs.
  static Future<List<CveEntry>> fetchAndroidCves() async {
    try {
      // Use lastModStartDate with proper ISO 8601 format the NVD API accepts
      final now = DateTime.now().toUtc();
      final past = now.subtract(const Duration(days: 120));
      
      // NVD API requires format: yyyy-MM-ddTHH:mm:ss.SSS
      final lastModStart = '${past.toIso8601String().split('.').first}.000';
      final lastModEnd = '${now.toIso8601String().split('.').first}.000';

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'keywordSearch': 'android',
        'lastModStartDate': lastModStart,
        'lastModEndDate': lastModEnd,
        'resultsPerPage': '50',
      });

      print('CVE API URL: $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        print('NVD API returned status ${response.statusCode}');
        // Fallback: try without date filtering
        return _fetchFallback();
      }

      return _parseCves(response.body);
    } catch (e) {
      print('CVE fetch error: $e');
      return _fetchFallback();
    }
  }

  /// Fallback fetch without date parameters
  static Future<List<CveEntry>> _fetchFallback() async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'keywordSearch': 'android vulnerability',
        'resultsPerPage': '40',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      return _parseCves(response.body);
    } catch (e) {
      print('CVE fallback fetch error: $e');
      return [];
    }
  }

  /// Parse CVE response JSON into CveEntry list.
  /// Filters to only CVEs with CVSS v3 scores (modern CVEs from ~2016+)
  /// and only HIGH/CRITICAL severity.
  static List<CveEntry> _parseCves(String body) {
    final Map<String, dynamic> data = json.decode(body);
    final List<dynamic> vulnerabilities = data['vulnerabilities'] ?? [];

    final List<CveEntry> entries = [];

    for (final item in vulnerabilities) {
      final cve = item['cve'] as Map<String, dynamic>;
      final String id = cve['id'] ?? 'Unknown';
      
      // Get severity from CVSS v3.1 or v3.0 metrics
      final metrics = cve['metrics'] as Map<String, dynamic>? ?? {};
      final cvssV31 = metrics['cvssMetricV31'] as List<dynamic>?;
      final cvssV30 = metrics['cvssMetricV30'] as List<dynamic>?;
      final cvssMetrics = cvssV31 ?? cvssV30;
      
      // Skip CVEs without CVSS v3 — these are ancient and irrelevant
      if (cvssMetrics == null || cvssMetrics.isEmpty) continue;
      
      final String severity = (cvssMetrics[0]['cvssData']?['baseSeverity'] ?? 'MEDIUM').toString().toUpperCase();
      
      // Only keep HIGH and CRITICAL severity
      if (severity != 'HIGH' && severity != 'CRITICAL') continue;

      final List<dynamic> descriptions = cve['descriptions'] ?? [];
      String description = 'No description available.';
      for (final desc in descriptions) {
        if (desc['lang'] == 'en') {
          description = desc['value'] ?? description;
          break;
        }
      }

      final String published = cve['published'] ?? '';
      String publishedDate = '';
      if (published.isNotEmpty) {
        try {
          final dt = DateTime.parse(published);
          publishedDate = '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}';
        } catch (_) {
          publishedDate = published.split('T').first;
        }
      }

      entries.add(CveEntry(
        id: id,
        description: description,
        severity: severity,
        publishedDate: publishedDate,
      ));
    }

    // Sort newest first
    entries.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
    return entries;
  }

  /// Match CVEs to an app based on its targetSdkVersion.
  /// Filters out CVEs about unrelated third-party apps.
  static List<CveEntry> matchCvesToApp(int targetSdkVersion, List<CveEntry> allCves, {String intentCategory = '', String packageName = ''}) {
    if (allCves.isEmpty) return [];

    final List<CveEntry> matched = [];
    final String? appAndroidVersion = _sdkToAndroidVersion[targetSdkVersion];
    final String pkgLower = packageName.toLowerCase();

    for (final cve in allCves) {
      final descLower = cve.description.toLowerCase();

      // STEP 1: Check if this CVE is about a SPECIFIC third-party app
      // (not the Android OS/framework itself)
      final bool isThirdPartyAppCve = _isThirdPartyAppCve(descLower);
      
      if (isThirdPartyAppCve) {
        // Only match if the CVE mentions something related to THIS app's package name
        // e.g., CVE about "AnyDesk" should only match com.anydesk.anydeskandroid
        final pkgParts = pkgLower.split('.');
        final bool mentionsThisApp = pkgParts.any((part) => 
          part.length > 3 && descLower.contains(part)
        );
        if (mentionsThisApp) {
          matched.add(cve);
        }
        continue; // Skip generic matching for third-party app CVEs
      }

      // STEP 2: This is an Android platform/framework CVE — match based on SDK
      bool isMatch = false;

      if (cve.severity == 'CRITICAL') {
        // CRITICAL platform CVEs affect all apps
        isMatch = true;
      } else if (targetSdkVersion < 30) {
        isMatch = true;
      } else if (targetSdkVersion < 33) {
        isMatch = descLower.contains('privilege escalation') ||
            descLower.contains('remote code execution') ||
            descLower.contains('information disclosure') ||
            descLower.contains('denial of service') ||
            descLower.contains('framework') ||
            descLower.contains('kernel');
      } else {
        // SDK 33+ — only severe system-level CVEs
        isMatch = descLower.contains('remote code execution') ||
            descLower.contains('privilege escalation') ||
            descLower.contains('kernel') ||
            descLower.contains('zero-day') ||
            descLower.contains('actively exploited');
      }

      // Match by specific Android version mentioned in description
      if (!isMatch && appAndroidVersion != null) {
        isMatch = descLower.contains('android $appAndroidVersion') ||
            descLower.contains('android ${appAndroidVersion}.0');
      }

      if (isMatch) {
        matched.add(cve);
      }
    }

    // Cap at 10, prioritize CRITICAL then by recency
    matched.sort((a, b) {
      if (a.severity == 'CRITICAL' && b.severity != 'CRITICAL') return -1;
      if (b.severity == 'CRITICAL' && a.severity != 'CRITICAL') return 1;
      return b.publishedDate.compareTo(a.publishedDate);
    });

    return matched.take(10).toList();
  }

  /// Detect if a CVE description is about a specific third-party app
  /// rather than the Android OS/framework itself.
  /// Returns true if it mentions a specific app/product name.
  static bool _isThirdPartyAppCve(String descLower) {
    // CVEs about the Android OS contain these markers
    final platformMarkers = [
      'android framework',
      'android system',
      'android kernel',
      'android runtime',
      'android media',
      'aosp',              // Android Open Source Project
      'android security bulletin',
      'google android',
      'qualcomm',          // chipset vendors
      'mediatek',
      'samsung mobile',
    ];
    
    for (final marker in platformMarkers) {
      if (descLower.contains(marker)) return false; // It's a platform CVE
    }

    // If description mentions a specific product/app name pattern,
    // it's likely about a third-party app
    final thirdPartyPatterns = [
      RegExp(r'\b\w+\s+(for android|for ios|for windows|for linux|for macos)'),  // "AppName for Android"
      RegExp(r'\b\w+\s+android app\b'),           // "AppName Android app"
      RegExp(r'\b\w+\s+mobile (app|application)\b'), // "AppName mobile app"
      RegExp(r'in the \w+ application\b'),         // "in the X application"
      RegExp(r'\b\w+ before \d+\.\d+'),            // "AppName before 9.0.5" (version ranges)
    ];

    for (final pattern in thirdPartyPatterns) {
      if (pattern.hasMatch(descLower)) return true;
    }

    return false;
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
