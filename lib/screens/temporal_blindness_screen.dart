import 'package:flutter/material.dart';
import '../models/temporal_blindness_models.dart';
import '../theme/app_theme.dart';

class TemporalBlindnessScreen extends StatefulWidget {
  const TemporalBlindnessScreen({super.key});

  @override
  State<TemporalBlindnessScreen> createState() =>
      _TemporalBlindnessScreenState();
}

class _TemporalBlindnessScreenState extends State<TemporalBlindnessScreen>
    with SingleTickerProviderStateMixin {
  SensorType? _selectedFilter;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = TemporalBlindnessMockData.report;
    final filteredEvents = _selectedFilter == null
        ? List<SensorAccessEvent>.from(report.events)
        : report.events
            .where((e) => e.sensorType == _selectedFilter)
            .toList();

    // Sort by most recent
    filteredEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Temporal Blindness Monitor',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live monitoring indicator
            _buildLiveIndicator(),
            const SizedBox(height: 16),

            // Overview stats
            _buildOverviewRow(report),
            const SizedBox(height: 20),

            // 24-hour heatmap
            Text(
              '24-Hour Sensor Access Heatmap',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildHeatmap(report.events),
            const SizedBox(height: 6),
            _buildHeatmapLegend(),
            const SizedBox(height: 24),

            // Sensor breakdown cards
            Text(
              'Sensor Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...report.sensorSummaries
                .map((s) => _buildSensorBreakdownCard(s)),
            const SizedBox(height: 24),

            // Filter chips
            Text(
              'Access Event Log',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildFilterChips(),
            const SizedBox(height: 12),

            // Events list
            ...filteredEvents.map((e) => _buildEventCard(e)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.safeGreen
                .withOpacity(0.05 + _pulseController.value * 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  AppColors.safeGreen.withOpacity(0.3 + _pulseController.value * 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.safeGreen
                      .withOpacity(0.5 + _pulseController.value * 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.safeGreen
                          .withOpacity(_pulseController.value * 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'LIVE MONITORING ACTIVE',
                style: TextStyle(
                  color: AppColors.safeGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                'Last 24h',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewRow(TemporalBlindnessReport report) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Events',
            report.totalEvents.toString(),
            Icons.sensors,
            AppColors.neonBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            'Shadow Access',
            report.totalShadowEvents.toString(),
            Icons.visibility_off,
            AppColors.alertRed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            'Shadow %',
            '${((report.totalShadowEvents / report.totalEvents) * 100).toStringAsFixed(0)}%',
            Icons.warning_amber,
            AppColors.warningYellow,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap(List<SensorAccessEvent> events) {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: CustomPaint(
        painter: _TemporalHeatmapPainter(events),
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(AppColors.safeGreen, 'Foreground'),
        const SizedBox(width: 16),
        _legendDot(AppColors.alertRed, 'Background (Shadow)'),
        const SizedBox(width: 16),
        _legendDot(Colors.grey.shade700, 'No Activity'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSensorBreakdownCard(SensorSummary summary) {
    final icon = _getSensorIcon(summary.sensorType);
    final color = summary.backgroundAccesses > 0
        ? AppColors.alertRed
        : AppColors.safeGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.sensorType.name.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.totalAccesses} total • ${summary.backgroundAccesses} shadow',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${summary.shadowPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'shadow rate',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('All', null),
          const SizedBox(width: 8),
          _filterChip('Camera', SensorType.camera),
          const SizedBox(width: 8),
          _filterChip('Microphone', SensorType.microphone),
          const SizedBox(width: 8),
          _filterChip('Location', SensorType.location),
        ],
      ),
    );
  }

  Widget _filterChip(String label, SensorType? type) {
    final isSelected = _selectedFilter == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.neonBlue.withOpacity(0.2)
              : AppColors.lightGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.neonBlue
                : AppColors.lightGray,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(SensorAccessEvent event) {
    final sensorIcon = _getSensorIcon(event.sensorType);
    final statusColor =
        event.isShadowAccess ? AppColors.alertRed : AppColors.safeGreen;
    final statusLabel = event.isShadowAccess ? 'SHADOW' : 'NORMAL';
    final timeAgo = _formatTimeAgo(event.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(sensorIcon, color: statusColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.appName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event.sensorType.name.toUpperCase()} • ${event.duration.inSeconds}s • $timeAgo',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.accessReason,
                    style: TextStyle(
                      color: event.isShadowAccess
                          ? AppColors.alertRed.withOpacity(0.7)
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSensorIcon(SensorType type) {
    switch (type) {
      case SensorType.camera:
        return Icons.camera_alt;
      case SensorType.microphone:
        return Icons.mic;
      case SensorType.location:
        return Icons.location_on;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Custom painter for the 24-hour heatmap with foreground / background distinction.
class _TemporalHeatmapPainter extends CustomPainter {
  final List<SensorAccessEvent> events;

  _TemporalHeatmapPainter(this.events);

  @override
  void paint(Canvas canvas, Size size) {
    const int totalSlots = 24;
    final double slotWidth = size.width / totalSlots;
    final double barWidth = slotWidth * 0.6;
    final double gap = slotWidth * 0.2;

    // Categorize events by hour
    final Map<int, List<SensorAccessEvent>> hourlyEvents = {};
    for (final event in events) {
      final hoursAgo = DateTime.now().difference(event.timestamp).inHours;
      if (hoursAgo >= 0 && hoursAgo < 24) {
        hourlyEvents.putIfAbsent(hoursAgo, () => []);
        hourlyEvents[hoursAgo]!.add(event);
      }
    }

    final Paint emptyPaint = Paint()..color = Colors.grey.shade800;

    for (int i = 0; i < totalSlots; i++) {
      final x = i * slotWidth + gap;
      final eventsInHour = hourlyEvents[23 - i]; // 0 = 24h ago, 23 = now

      if (eventsInHour == null || eventsInHour.isEmpty) {
        // No activity
        final rect =
            Rect.fromLTWH(x, size.height - size.height * 0.15, barWidth, size.height * 0.15);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          emptyPaint,
        );
      } else {
        final hasShadow = eventsInHour.any((e) => e.isShadowAccess);
        final color =
            hasShadow ? AppColors.alertRed : AppColors.safeGreen;
        final height = size.height *
            (0.3 + (eventsInHour.length / 4.0).clamp(0.0, 0.7));

        final paint = Paint()..color = color;
        final rect =
            Rect.fromLTWH(x, size.height - height, barWidth, height);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          paint,
        );

        // Glow effect for shadow access
        if (hasShadow) {
          final glowPaint = Paint()
            ..color = AppColors.alertRed.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(3)),
            glowPaint,
          );
        }
      }
    }

    // Draw time labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i < totalSlots; i += 6) {
      textPainter.text = TextSpan(
        text: '${(24 - i)}h',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(i * slotWidth + gap, size.height + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
