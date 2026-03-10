import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';

class TimelineScreen extends StatefulWidget {
  final AppPermissionSummary app;

  const TimelineScreen({super.key, required this.app});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.aegis.dev/usage');

  bool _isLoading = true;
  Map<int, int> _hourlyEvents = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-fetch when user returns from Settings
    if (state == AppLifecycleState.resumed) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    try {
      final dynamic rawResult = await _channel.invokeMethod('getAppUsageStats', {
        'packageName': widget.app.packageName,
      });

      if (rawResult == null) {
        setState(() {
          _isLoading = false;
          _error = 'No data returned';
        });
        return;
      }

      final Map<Object?, Object?> result = rawResult as Map<Object?, Object?>;
      final Map<int, int> events = {};

      final hourlyRaw = result['hourlyEvents'];
      if (hourlyRaw != null && hourlyRaw is Map) {
        hourlyRaw.forEach((key, value) {
          final int hour = key is int ? key : int.tryParse(key.toString()) ?? 0;
          final int count = value is int ? value : int.tryParse(value.toString()) ?? 0;
          events[hour] = count;
        });
      }

      // Ensure all 24 hours exist
      for (int i = 0; i < 24; i++) {
        events.putIfAbsent(i, () => 0);
      }

      setState(() {
        _hourlyEvents = events;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openUsageSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (_) {}
  }

  String _hourLabel(int hour) {
    if (hour == 0) return '12A';
    if (hour < 12) return '${hour}A';
    if (hour == 12) return '12P';
    return '${hour - 12}P';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.app.appName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonBlue))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final int maxCount = _hourlyEvents.values.fold(0, (a, b) => a > b ? a : b);
    final bool hasActivity = maxCount > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neonBlue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '24-Hour Activity: ${widget.app.appName}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(widget.app.packageName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _legendDot(AppColors.neonBlue, 'Normal Activity'),
                    _legendDot(Colors.grey.shade800, 'Idle'),
                    _legendDot(
                      widget.app.riskLevel == RiskLevel.critical || widget.app.riskLevel == RiskLevel.high ? AppColors.alertRed : AppColors.warningYellow,
                      'High Frequency',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Context & Risk Analysis
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.app.riskLevel == RiskLevel.critical || widget.app.riskLevel == RiskLevel.high
                    ? AppColors.alertRed.withOpacity(0.3)
                    : AppColors.safeGreen.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Context Analysis', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('App Intent', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(widget.app.intentCategory, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Risk Level', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            widget.app.riskLevel.name.toUpperCase(),
                            style: TextStyle(
                              color: widget.app.riskLevel == RiskLevel.critical || widget.app.riskLevel == RiskLevel.high
                                  ? AppColors.alertRed
                                  : (widget.app.riskLevel == RiskLevel.medium ? AppColors.warningYellow : AppColors.safeGreen),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.app.vulnerabilities.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: AppColors.textSecondary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  const Text('Detected Mismatches', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  ...widget.app.vulnerabilities.map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.alertRed, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(v, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4))),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // CVE Vulnerabilities Section
          if (widget.app.cveMatches.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.alertRed.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bug_report, color: AppColors.alertRed, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Known CVE Vulnerabilities (${widget.app.cveMatches.length})',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on target SDK ${widget.app.targetSdkVersion} • Source: NIST NVD',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  ...widget.app.cveMatches.map((cve) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.darkGray,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cve.severity == 'CRITICAL'
                            ? AppColors.alertRed.withOpacity(0.4)
                            : AppColors.warningYellow.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              cve.id,
                              style: const TextStyle(
                                color: AppColors.neonBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: cve.severity == 'CRITICAL'
                                    ? AppColors.alertRed.withOpacity(0.15)
                                    : AppColors.warningYellow.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cve.severity,
                                style: TextStyle(
                                  color: cve.severity == 'CRITICAL' ? AppColors.alertRed : AppColors.warningYellow,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cve.publishedDate,
                          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 10),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cve.description.length > 200
                              ? '${cve.description.substring(0, 200)}...'
                              : cve.description,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        // Remediation / Solution box
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.safeGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.safeGreen.withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.shield, color: AppColors.safeGreen, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Recommended Action',
                                      style: TextStyle(color: AppColors.safeGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getCveRemediation(cve, widget.app.targetSdkVersion),
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Heatmap (always shown)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: CustomPaint(
                    painter: _HeatmapPainter(hourlyEvents: _hourlyEvents, maxCount: maxCount, riskLevel: widget.app.riskLevel),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [0, 4, 8, 12, 16, 20, 23]
                      .map((h) => Text(_hourLabel(h), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (!hasActivity) ...[
            // No activity — offer settings link + refresh
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.safeGreen, size: 48),
                  const SizedBox(height: 16),
                  const Text('No background activity in the last 24 hours.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 16),
                  const Text('If results seem empty, ensure Usage Access is enabled.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children: [
                      TextButton.icon(
                        onPressed: _openUsageSettings,
                        icon: const Icon(Icons.settings, size: 18, color: AppColors.neonBlue),
                        label: const Text('Usage Settings', style: TextStyle(color: AppColors.neonBlue, fontSize: 13)),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _fetchData();
                        },
                        icon: const Icon(Icons.refresh, size: 18, color: AppColors.safeGreen),
                        label: const Text('Refresh', style: TextStyle(color: AppColors.safeGreen, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Hourly breakdown
            const Text('Hourly Breakdown', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...(_hourlyEvents.entries.where((e) => e.value > 0).toList()..sort((a, b) => a.key.compareTo(b.key))).map((entry) {
              final bool isHighFreq = entry.value >= 3;
              final bool isRisky = isHighFreq && (widget.app.riskLevel == RiskLevel.high || widget.app.riskLevel == RiskLevel.critical);
              final Color itemColor = !isHighFreq ? AppColors.neonBlue : (isRisky ? AppColors.alertRed : AppColors.warningYellow);
              final IconData itemIcon = !isHighFreq ? Icons.access_time : (isRisky ? Icons.warning_amber_rounded : Icons.sync);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: itemColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(itemIcon, color: itemColor, size: 20),
                    const SizedBox(width: 12),
                    Text(_hourLabel(entry.key), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${entry.value} event${entry.value > 1 ? "s" : ""}', style: TextStyle(color: itemColor, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (widget.app.riskLevel == RiskLevel.critical || widget.app.riskLevel == RiskLevel.high ? AppColors.alertRed : AppColors.safeGreen).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (widget.app.riskLevel == RiskLevel.critical || widget.app.riskLevel == RiskLevel.high ? AppColors.alertRed : AppColors.safeGreen).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.app.riskLevel == RiskLevel.critical || widget.app.riskLevel == RiskLevel.high ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: widget.app.riskLevel == RiskLevel.critical || widget.app.riskLevel == RiskLevel.high ? AppColors.alertRed : AppColors.safeGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (widget.app.intentCategory == 'System' || widget.app.intentCategory == 'Communication' || widget.app.intentCategory == 'Finance')
                          ? "As a ${widget.app.intentCategory} app, frequent background events are normal for delivering notifications and syncing data. Mitigation is usually not required."
                          : "High-frequency background events in a ${widget.app.intentCategory} app may indicate 'Shadow Access' tracking. Consider mitigating if this app doesn't need background access.",
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  String _getCveRemediation(CveEntry cve, int targetSdk) {
    final d = cve.description.toLowerCase();

    // Kernel vulnerability
    if (d.contains('kernel') || d.contains('linux kernel')) {
      return '• Go to Settings → System → Software Update and install the latest Android security patch.\n'
          '• Kernel patches are delivered via monthly security updates from your device manufacturer.';
    }

    // Remote code execution
    if (d.contains('remote code execution') || d.contains('rce')) {
      return '• Update this app to the latest version from Play Store immediately.\n'
          '• Avoid clicking unknown links or opening untrusted files until patched.\n'
          '• Check Settings → System → Security Update to ensure your device is up to date.';
    }

    // Privilege escalation
    if (d.contains('privilege escalation') || d.contains('escalation of privilege')) {
      return '• Install the latest Android security patch from Settings → System → Software Update.\n'
          '• Review this app\'s permissions and revoke any unnecessary ones.\n'
          '• Avoid sideloading apps from untrusted sources.';
    }

    // Buffer overflow / memory corruption
    if (d.contains('buffer overflow') || d.contains('heap') || d.contains('memory corruption') || d.contains('use-after-free')) {
      return '• Update both the app and Android OS to their latest versions.\n'
          '• These vulnerabilities are typically fixed in monthly security patches.\n'
          '• Avoid visiting untrusted websites while unpatched.';
    }

    // Information disclosure
    if (d.contains('information disclosure') || d.contains('data leak') || d.contains('sensitive')) {
      return '• Update this app from the Play Store to get the security fix.\n'
          '• Review the app\'s data access permissions in Settings → Apps.\n'
          '• Consider using a VPN for sensitive activities until patched.';
    }

    // Third-party app specific CVE
    if (d.contains('before ') && (d.contains('version') || RegExp(r'before \d+\.\d+').hasMatch(d))) {
      return '• Update this app to the latest version from the Play Store.\n'
          '• The vulnerability affects older versions and is likely already patched.\n'
          '• Enable auto-updates: Play Store → Settings → Auto-update apps.';
    }

    // Outdated SDK general advice
    if (targetSdk < 33) {
      return '• This app targets an outdated Android SDK ($targetSdk). Ask the developer to update.\n'
          '• Consider switching to an alternative app that targets a newer SDK.\n'
          '• Keep your Android OS updated to mitigate impact.';
    }

    // General fallback
    return '• Keep your Android OS and all apps updated to the latest versions.\n'
        '• Check Settings → System → Software Update for pending security patches.\n'
        '• Enable auto-updates in the Play Store to stay protected.';
  }
}

class _HeatmapPainter extends CustomPainter {
  final Map<int, int> hourlyEvents;
  final int maxCount;
  final RiskLevel riskLevel;

  _HeatmapPainter({required this.hourlyEvents, required this.maxCount, required this.riskLevel});

  @override
  void paint(Canvas canvas, Size size) {
    const int bars = 24;
    final double barTotalW = size.width / bars;
    final double barW = barTotalW * 0.65;
    final double gap = barTotalW * 0.35;

    for (int i = 0; i < bars; i++) {
      final int count = hourlyEvents[i] ?? 0;
      final double frac = maxCount > 0 ? count / maxCount : 0;
      final double h = count > 0 ? (size.height * 0.2) + (size.height * 0.7 * frac) : size.height * 0.12;

      final bool isHighFreq = count >= 3;
      final bool isRisky = isHighFreq && (riskLevel == RiskLevel.high || riskLevel == RiskLevel.critical);

      final Color c = count == 0
          ? Colors.grey.shade800
          : !isHighFreq
              ? AppColors.neonBlue
              : isRisky
                  ? AppColors.alertRed
                  : AppColors.warningYellow;

      final double x = i * barTotalW + (gap / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, barW, h), const Radius.circular(4)),
        Paint()..color = c,
      );
    }

    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), Paint()..color = AppColors.lightGray..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
