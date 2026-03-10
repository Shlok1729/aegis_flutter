import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../services/app_service.dart';
import '../services/cve_service.dart';
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
  String? _activeFilter;
  String? _activeFilterLabel;

  @override
  void initState() {
    super.initState();
    _loadRealApps();
  }

  Future<void> _loadRealApps() async {
    final apps = await AppService.fetchInstalledApps();
    
    // Fetch CVE data from NVD (non-blocking — app list loads even if this fails)
    List<CveEntry> allCves = [];
    try {
      allCves = await CveService.fetchAndroidCves();
    } catch (e) {
      print('CVE fetch failed in dashboard: $e');
    }
    
    // Match CVEs to each app based on targetSdkVersion
    final List<AppPermissionSummary> appsWithCves = apps.map((app) {
      final matched = CveService.matchCvesToApp(app.targetSdkVersion, allCves, intentCategory: app.intentCategory, packageName: app.packageName);
      if (matched.isEmpty) return app;
      return AppPermissionSummary(
        appName: app.appName,
        packageName: app.packageName,
        intentCategory: app.intentCategory,
        riskLevel: app.riskLevel,
        permissions: app.permissions,
        vulnerabilities: app.vulnerabilities,
        isOutdated: app.isOutdated,
        versionName: app.versionName,
        lastUpdate: app.lastUpdate,
        isIgnored: app.isIgnored,
        targetSdkVersion: app.targetSdkVersion,
        cveMatches: matched,
      );
    }).toList();
    
    int riskyCount = appsWithCves.where((a) => !a.isIgnored && (a.riskLevel == RiskLevel.high || a.riskLevel == RiskLevel.critical)).length;
    int outdatedCount = appsWithCves.where((a) => !a.isIgnored && a.isOutdated).length;
    
    // Count total dangerous permissions across ALL apps (real metric)
    int totalDangerousPerms = 0;
    int totalCves = 0;
    for (final app in appsWithCves) {
      if (!app.isIgnored) {
        totalDangerousPerms += app.permissions.where((p) => AppService.dangerousPermissions.contains(p)).length;
        totalCves += app.cveMatches.length;
      }
    }
    
    // Health score: based on ratio of risky/outdated apps to total apps
    int score;
    if (appsWithCves.isEmpty) {
      score = 100;
    } else {
      double riskyRatio = (riskyCount + (outdatedCount * 0.5)) / appsWithCves.length;
      score = (100 * (1 - riskyRatio * 2)).clamp(0, 100).round();
    }

    setState(() {
      state = DashboardState(
        privacyHealthScore: score,
        scannedAppsCount: appsWithCves.length,
        riskyAppsCount: riskyCount,
        backgroundPingsBlocked: totalDangerousPerms,
        outdatedAppsCount: outdatedCount,
        cveCount: totalCves,
        appsList: appsWithCves,
      );
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Project AEGIS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'by CodeCeption',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() { isLoading = true; });
              _loadRealApps();
            },
          ),
        ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _activeFilter == null ? 'Installed Apps (Intent-Based Analysis)' : 'Filtered Apps',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_activeFilter != null)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _activeFilter = null;
                          _activeFilterLabel = null;
                        }),
                        icon: const Icon(Icons.close, size: 16, color: AppColors.alertRed),
                        label: const Text('Clear Filter', style: TextStyle(color: AppColors.alertRed, fontSize: 13)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: AppColors.alertRed.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                  ],
                ),
                if (_activeFilterLabel != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.neonBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.neonBlue.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Filtering by: $_activeFilterLabel',
                      style: const TextStyle(color: AppColors.neonBlue, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ..._getFilteredApps().map((app) => _buildAppItemCard(context, app)),
              ],
            ),
          ),
    );
  }

  List<AppPermissionSummary> _getFilteredApps() {
    if (_activeFilter == null) return state.appsList;
    
    return state.appsList.where((app) {
      if (_activeFilter == 'outdated') return !app.isIgnored && app.isOutdated;
      if (_activeFilter == 'cve') return !app.isIgnored && app.cveMatches.isNotEmpty;
      return !app.isIgnored && app.vulnerabilities.any((v) => v.contains(_activeFilter!));
    }).toList();
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Outdated', state.outdatedAppsCount.toString(), Icons.update_disabled, state.outdatedAppsCount > 0 ? AppColors.alertRed : AppColors.safeGreen)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('CVEs', state.cveCount.toString(), Icons.bug_report_outlined, state.cveCount > 0 ? AppColors.alertRed : AppColors.safeGreen)),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
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
        gradient: LinearGradient(
          colors: [
            Colors.white,
            color.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
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
      if (app.riskLevel != RiskLevel.low && !app.isIgnored) {
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
          GestureDetector(
            onTap: () => setState(() {
              _activeFilter = 'outdated';
              _activeFilterLabel = 'Security Update Required';
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _activeFilter == 'outdated' ? AppColors.alertRed.withOpacity(0.2) : AppColors.alertRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.alertRed.withOpacity(_activeFilter == 'outdated' ? 0.8 : 0.3)),
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
                  if (_activeFilter == 'outdated') const Icon(Icons.arrow_downward, color: AppColors.alertRed, size: 16),
                ],
              ),
            ),
          ),
        if (state.cveCount > 0)
          GestureDetector(
            onTap: () => setState(() {
              _activeFilter = 'cve';
              _activeFilterLabel = 'CVE Vulnerabilities Detected';
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _activeFilter == 'cve' ? AppColors.alertRed.withOpacity(0.2) : AppColors.alertRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.alertRed.withOpacity(_activeFilter == 'cve' ? 0.8 : 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bug_report, color: AppColors.alertRed, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CVE Vulnerabilities Detected', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('${state.cveCount} known CVEs affect apps on this device.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  if (_activeFilter == 'cve') const Icon(Icons.arrow_downward, color: AppColors.alertRed, size: 16),
                ],
              ),
            ),
          ),
        ...vulnerabilityCounts.entries.take(3).map((entry) {
          final isHighSeverity = entry.key.contains("SMS") || entry.key.contains("Location") || entry.key.contains("Camera");
          final color = isHighSeverity ? AppColors.alertRed : AppColors.warningYellow;
          final icon = isHighSeverity ? Icons.warning_amber_rounded : Icons.info_outline;
          final isSelected = _activeFilter != null && entry.key.contains(_activeFilter!);

          return GestureDetector(
            onTap: () => setState(() {
              // Extract a short identifying keyword for the filter
              _activeFilter = entry.key.split(':').last.trim().split(' ').take(2).join(' ');
              _activeFilterLabel = entry.key;
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : AppColors.lightGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(isSelected ? 0.8 : 0.3)),
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
                  if (isSelected) Icon(Icons.arrow_downward, color: color, size: 16),
                ],
              ),
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
    Color riskColor = app.isIgnored ? AppColors.safeGreen : _getRiskColor(app.riskLevel);

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
                      if (app.cveMatches.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.alertRed.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.alertRed.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bug_report, color: AppColors.alertRed, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  '${app.cveMatches.length} CVE${app.cveMatches.length > 1 ? "s" : ""}',
                                  style: const TextStyle(color: AppColors.alertRed, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
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
                        app.isIgnored ? 'APPROVED' : app.riskLevel.name.toUpperCase(),
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
                  icon: Icon(app.isIgnored ? Icons.settings : Icons.security, color: AppColors.darkGray),
                  label: Text(app.isIgnored ? 'MANAGE APP' : 'ONE-TAP MITIGATION', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: AppColors.darkGray, fontSize: 14)),
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
              icon: app.isIgnored ? Icons.restore : Icons.verified_user_outlined,
              color: app.isIgnored ? AppColors.warningYellow : AppColors.neonBlue,
              title: app.isIgnored ? 'Revoke Approval' : 'Ignore Warnings',
              subtitle: app.isIgnored ? 'Restore risk warnings for this app' : 'Mark this app as safe manually',
              onTap: () async {
                Navigator.pop(ctx);
                if (app.isIgnored) {
                  await AppService.unignoreApp(app.packageName);
                } else {
                  await AppService.ignoreApp(app.packageName, app.versionName);
                }
                setState(() => isLoading = true);
                _loadRealApps();
              },
            ),
            const SizedBox(height: 12),
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
