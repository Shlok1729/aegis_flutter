import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../services/app_service.dart';
import 'timeline_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardState state = const DashboardState();
  bool isLoading = true;
  final Set<String> _expandedApps = {};

  @override
  void initState() {
    super.initState();
    _loadRealApps();
  }

  Future<void> _loadRealApps() async {
    final apps = await AppService.fetchInstalledApps();
    
    int riskyCount = apps.where((a) => a.riskLevel == RiskLevel.high || a.riskLevel == RiskLevel.critical).length;
    int outdatedCount = apps.where((a) => a.isOutdated).length;
    
    // Count total dangerous permissions across ALL apps (real metric)
    int totalDangerousPerms = 0;
    for (final app in apps) {
      totalDangerousPerms += app.permissions.where((p) => AppService.dangerousPermissions.contains(p)).length;
    }
    
    // Health score: based on ratio of risky/outdated apps to total apps
    int score;
    if (apps.isEmpty) {
      score = 100;
    } else {
      double riskyRatio = (riskyCount + (outdatedCount * 0.5)) / apps.length;
      score = (100 * (1 - riskyRatio * 2)).clamp(0, 100).round();
    }

    setState(() {
      state = DashboardState(
        privacyHealthScore: score,
        scannedAppsCount: apps.length,
        riskyAppsCount: riskyCount,
        backgroundPingsBlocked: totalDangerousPerms,
        outdatedAppsCount: outdatedCount,
        appsList: apps,
      );
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project AEGIS'),
      ),
      body: isLoading 
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.neonBlue),
          )
        : SingleChildScrollView(
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
                if (state.appsList.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No apps found or permission denied.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                else
                  ...state.appsList.map((app) => _buildAppItemCard(context, app)),
              ],
            ),
          ),
    );
  }

  Widget _buildHealthScoreCard() {
    Color scoreColor = _getRiskColorForScore(state.privacyHealthScore);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.15),
            blurRadius: 32,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: AppColors.darkGray.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'PRIVACY HEALTH SCORE',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: state.privacyHealthScore / 100),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 14,
                      backgroundColor: AppColors.darkGray,
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${state.privacyHealthScore}',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '/ 100',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              state.privacyHealthScore >= 90 ? 'Your device is highly secure.' :
              state.privacyHealthScore >= 70 ? 'Some privacy risks detected.' :
              'Critical privacy risks found.',
              style: TextStyle(color: scoreColor, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Scanned', state.scannedAppsCount.toString(), Icons.shield_outlined, AppColors.neonBlue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Risky', state.riskyAppsCount.toString(), Icons.warning_amber_rounded, state.riskyAppsCount > 0 ? AppColors.alertRed : AppColors.safeGreen)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Flagged', state.backgroundPingsBlocked.toString(), Icons.flag_outlined, AppColors.warningYellow)),
          ],
        ),
        const SizedBox(height: 24),
        _buildVulnerabilitiesReport(),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildVulnerabilitiesReport() {
    // Map of vulnerability text to the number of apps that have it
    final Map<String, int> vulnerabilityCounts = {};
    for (var app in state.appsList) {
      if (app.riskLevel != RiskLevel.low) {
        for (var v in app.vulnerabilities) {
          vulnerabilityCounts[v] = (vulnerabilityCounts[v] ?? 0) + 1;
        }
      }
    }

    if (vulnerabilityCounts.isEmpty && state.outdatedAppsCount == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.safeGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.safeGreen.withOpacity(0.3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.safeGreen, size: 48),
            SizedBox(height: 16),
            Text('No Critical Risks Found', style: TextStyle(color: AppColors.safeGreen, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Your device is in a secure state with no severe intent mismatches detected.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Key Risk Factors Detected', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (state.outdatedAppsCount > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.alertRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.alertRed.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.update_disabled, color: AppColors.alertRed, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Security Update Required', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${state.outdatedAppsCount} apps are targeting outdated Android security layers.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ...vulnerabilityCounts.entries.take(3).map((entry) {
          final isHighSeverity = entry.key.contains("SMS") || entry.key.contains("Location") || entry.key.contains("Camera");
          final color = isHighSeverity ? AppColors.alertRed : AppColors.warningYellow;
          final icon = isHighSeverity ? Icons.warning_amber_rounded : Icons.info_outline;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 4),
                      Text('Found in ${entry.value} app${entry.value > 1 ? "s" : ""}', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  IconData _getIntentIcon(String intent) {
    switch (intent.toLowerCase()) {
      case 'utility': return Icons.build_circle_outlined;
      case 'social': return Icons.groups_outlined;
      case 'finance': return Icons.account_balance_wallet_outlined;
      case 'communication': return Icons.chat_bubble_outline;
      default: return Icons.apps_outlined;
    }
  }

  Widget _buildAppItemCard(BuildContext context, AppPermissionSummary app) {
    Color riskColor = _getRiskColor(app.riskLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: riskColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkGray,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
                  ),
                  child: Icon(_getIntentIcon(app.intentCategory), color: AppColors.neonBlue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              app.appName,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (app.isOutdated)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.sync_problem, color: AppColors.alertRed, size: 16),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Intent: ${app.intentCategory}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        'v${app.versionName} • Updated: ${app.lastUpdate.day}/${app.lastUpdate.month}/${app.lastUpdate.year}',
                        style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: riskColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: riskColor, size: 8),
                      const SizedBox(width: 6),
                      Text(
                        app.riskLevel.name.toUpperCase(),
                        style: TextStyle(color: riskColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_expandedApps.contains(app.packageName)) {
                    _expandedApps.remove(app.packageName);
                  } else {
                    _expandedApps.add(app.packageName);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.darkGray,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, color: AppColors.neonBlue, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${app.permissions.length} Permissions Requested',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Icon(
                      _expandedApps.contains(app.packageName) ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            if (_expandedApps.contains(app.packageName)) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: app.permissions.map((p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.darkGray,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.textSecondary.withOpacity(0.15)),
                  ),
                  child: Text(p, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                )).toList(),
              ),
            ],
            
            if (app.vulnerabilities.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.alertRed.withOpacity(0.3)),
                ),
                child: Column(
                  children: app.vulnerabilities.map((vuln) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          vuln.contains('Abandoned') || vuln.contains('Outdated') 
                            ? Icons.system_update_alt 
                            : Icons.warning_amber_rounded,
                          color: AppColors.alertRed, 
                          size: 20
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(vuln, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _showMitigationSheet(context, app),
                  icon: const Icon(Icons.security, color: AppColors.darkGray),
                  label: const Text('ONE-TAP MITIGATION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: AppColors.darkGray, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safeGreen,
                    elevation: 6,
                    shadowColor: AppColors.safeGreen.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            
            if (app.vulnerabilities.isEmpty) const SizedBox(height: 8),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TimelineScreen(app: app)),
                  );
                },
                icon: const Icon(Icons.timeline, size: 22, color: AppColors.neonBlue),
                label: const Text('VIEW SHADOW TIMELINE', style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.neonBlue, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _showMitigationSheet(BuildContext context, AppPermissionSummary app) {
    const channel = MethodChannel('com.aegis.dev/apps');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Mitigate: ${app.appName}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose an action to reduce this app\'s risk.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            if (app.isOutdated) ...[
              _mitigationTile(
                icon: Icons.update,
                color: AppColors.safeGreen,
                title: 'Update via Play Store',
                subtitle: 'Install latest version with security patches',
                onTap: () {
                  Navigator.pop(ctx);
                  channel.invokeMethod('openPlayStore', {'packageName': app.packageName});
                },
              ),
              const SizedBox(height: 12),
            ],
            _mitigationTile(
              icon: Icons.shield_outlined,
              color: AppColors.neonBlue,
              title: 'Revoke Permissions',
              subtitle: 'Open app settings to remove dangerous permissions',
              onTap: () {
                Navigator.pop(ctx);
                channel.invokeMethod('openAppSettings', {'packageName': app.packageName});
              },
            ),
            const SizedBox(height: 12),
            _mitigationTile(
              icon: Icons.battery_saver,
              color: AppColors.warningYellow,
              title: 'Restrict Background',
              subtitle: 'Limit background activity and battery usage',
              onTap: () {
                Navigator.pop(ctx);
                channel.invokeMethod('openBatterySettings', {'packageName': app.packageName});
              },
            ),
            const SizedBox(height: 12),
            _mitigationTile(
              icon: Icons.delete_forever,
              color: AppColors.alertRed,
              title: 'Uninstall App',
              subtitle: 'Completely remove this app from your device',
              onTap: () {
                Navigator.pop(ctx);
                channel.invokeMethod('uninstallApp', {'packageName': app.packageName});
              },
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _mitigationTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}
