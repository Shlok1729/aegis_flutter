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
