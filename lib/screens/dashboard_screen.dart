import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';
import 'timeline_screen.dart';

class DashboardScreen extends StatelessWidget {
  final DashboardState state = MockData.state;

  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project AEGIS'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHealthScoreCard(),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 24),
            Text(
              'Installed Apps (Intent-Based Analysis)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...state.appsList.map((app) => _buildAppItemCard(context, app)),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    Color scoreColor = _getRiskColorForScore(state.privacyHealthScore);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Privacy Health Score',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.privacyHealthScore} / 100',
              style: TextStyle(
                color: scoreColor,
                fontSize: 48,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem('Scanned', state.scannedAppsCount.toString(), AppColors.textPrimary),
        _buildStatItem('Risky Apps', state.riskyAppsCount.toString(), state.riskyAppsCount > 0 ? AppColors.alertRed : AppColors.safeGreen),
        _buildStatItem('Shadow Pings', state.backgroundPingsBlocked.toString(), AppColors.warningYellow),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildAppItemCard(BuildContext context, AppPermissionSummary app) {
    Color riskColor = _getRiskColor(app.riskLevel);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.appName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Intent: ${app.intentCategory}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    app.riskLevel.name.toUpperCase(),
                    style: TextStyle(color: riskColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Permissions: ${app.permissions.join(", ")}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            
            if (app.vulnerabilities.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...app.vulnerabilities.map((vuln) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning, color: AppColors.alertRed, size: 16),
                    const SizedBox(width: 4),
                    Expanded(child: Text(vuln, style: const TextStyle(color: AppColors.alertRed, fontSize: 12))),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.security, size: 18, color: AppColors.darkGray),
                  label: const Text('One-Tap Mitigation', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGray)),
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TimelineScreen()),
                  );
                },
                icon: const Icon(Icons.timeline, size: 18, color: AppColors.neonBlue),
                label: const Text('View Shadow-Timeline', style: TextStyle(color: AppColors.neonBlue)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.neonBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low: return AppColors.safeGreen;
      case RiskLevel.medium: return AppColors.warningYellow;
      case RiskLevel.high: return const Color(0xFFFF9100);
      case RiskLevel.critical: return AppColors.alertRed;
    }
  }

  Color _getRiskColorForScore(int score) {
    if (score >= 90) return AppColors.safeGreen;
    if (score >= 70) return AppColors.warningYellow;
    return AppColors.alertRed;
  }
}
