import 'package:flutter/material.dart';
import '../models/permission_intelligence_models.dart';
import '../theme/app_theme.dart';

class PermissionIntelligenceScreen extends StatelessWidget {
  const PermissionIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apps = PermissionIntelligenceMockData.apps;
    // Sort by anomaly score descending
    final sortedApps = List<PermissionIntelligenceApp>.from(apps)
      ..sort((a, b) => b.overallAnomalyScore.compareTo(a.overallAnomalyScore));

    final anomalousCount =
        sortedApps.where((a) => a.overallAnomalyScore > 0.5).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Permission Intelligence',
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
            // Concept explanation
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.neonBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.neonBlue.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.psychology,
                      color: AppColors.neonBlue, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Standard permission managers treat all apps equally. '
                      'AEGIS uses contextual intelligence to detect when permissions don\'t match an app\'s stated purpose.',
                      style: TextStyle(
                        color: AppColors.neonBlue.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Apps Analyzed',
                    sortedApps.length.toString(),
                    Icons.app_settings_alt,
                    AppColors.neonBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Anomalies',
                    anomalousCount.toString(),
                    Icons.gpp_bad,
                    AppColors.alertRed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Safe Apps',
                    (sortedApps.length - anomalousCount).toString(),
                    Icons.verified_user,
                    AppColors.safeGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Contextual Analysis Results',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            ...sortedApps.map((app) => _buildAppAnalysisCard(context, app)),
          ],
        ),
      ),
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

  Widget _buildAppAnalysisCard(
      BuildContext context, PermissionIntelligenceApp app) {
    final anomalyColor = _getAnomalyColor(app.overallAnomalyScore);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: anomalyColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              app.overallAnomalyScore > 0.5
                  ? Icons.gpp_bad
                  : Icons.verified_user,
              color: anomalyColor,
              size: 22,
            ),
          ),
          title: Text(
            app.appName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Intent: ${app.intentCategory}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: _buildAnomalyBadge(app.overallAnomalyScore),
          children: [
            // Anomaly score gauge
            _buildAnomalyGauge(app),
            const SizedBox(height: 14),

            // Permission chips
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: app.permissions
                    .map((p) => _buildPermissionChip(p))
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Detailed permission analysis
            ...app.permissions
                .map((p) => _buildPermissionDetail(p)),

            // Analysis note
            if (app.analysisNote.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: anomalyColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: anomalyColor.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.analytics,
                        color: anomalyColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        app.analysisNote,
                        style: TextStyle(
                          color: anomalyColor.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyBadge(double score) {
    final color = _getAnomalyColor(score);
    final label = score >= 0.7
        ? 'HIGH'
        : score >= 0.4
            ? 'MED'
            : 'LOW';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAnomalyGauge(PermissionIntelligenceApp app) {
    final color = _getAnomalyColor(app.overallAnomalyScore);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Anomaly Score',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              '${(app.overallAnomalyScore * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: app.overallAnomalyScore,
            minHeight: 8,
            backgroundColor: AppColors.lightGray,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionChip(PermissionContext perm) {
    Color chipColor;
    switch (perm.justification) {
      case PermissionJustification.justified:
        chipColor = AppColors.safeGreen;
        break;
      case PermissionJustification.questionable:
        chipColor = AppColors.warningYellow;
        break;
      case PermissionJustification.anomalous:
        chipColor = AppColors.alertRed;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            perm.justification == PermissionJustification.justified
                ? Icons.check_circle
                : perm.justification == PermissionJustification.questionable
                    ? Icons.help
                    : Icons.cancel,
            color: chipColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            perm.permissionName,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDetail(PermissionContext perm) {
    Color barColor;
    switch (perm.justification) {
      case PermissionJustification.justified:
        barColor = AppColors.safeGreen;
        break;
      case PermissionJustification.questionable:
        barColor = AppColors.warningYellow;
        break;
      case PermissionJustification.anomalous:
        barColor = AppColors.alertRed;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perm.permissionName,
                  style: TextStyle(
                    color: barColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  perm.reasoning,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAnomalyColor(double score) {
    if (score >= 0.7) return AppColors.alertRed;
    if (score >= 0.4) return AppColors.warningYellow;
    return AppColors.safeGreen;
  }
}
