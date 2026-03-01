import 'package:flutter/material.dart';
import '../../../core/widgets/top_app_bar.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../farm_context.dart';
import '../services/farm_summary_service.dart';
import '../widgets/summary_card.dart';
import '../../alerts/services/alert_service.dart';
import '../../alerts/pages/alerts_page.dart';
import 'cattle_list_page.dart';
import 'farm_detail_page.dart';
import '../../quickcheck/quick_check_page.dart';
import '../passbook_page.dart';

class IndividualFarmPage extends StatefulWidget {
  final FarmContext farm;

  const IndividualFarmPage({Key? key, required this.farm}) : super(key: key);

  @override
  State<IndividualFarmPage> createState() => _IndividualFarmPageState();
}

class _IndividualFarmPageState extends State<IndividualFarmPage> {
  late Future<Map<String, dynamic>> _summaryFuture;
  late Future<List<Map<String, dynamic>>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _summaryFuture = FarmSummaryService.getSummary(widget.farm.farmId);
    _alertsFuture = AlertService.getAlerts(widget.farm.farmId);
  }

  Future<void> _onRefresh() async {
    setState(() {
      _fetchData();
    });
    await Future.wait([_summaryFuture, _alertsFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GowlokTopBar(title: widget.farm.farmName),
      bottomNavigationBar: GlobalBottomNav.persistent(context),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = snapshot.data ?? {};
          final criticalCount = (summary['critical_count'] as num?)?.toInt() ?? 0;
          final warningCount = (summary['warning_count'] as num?)?.toInt() ?? 0;
          final normalCount = (summary['normal_count'] as num?)?.toInt() ?? 0;
          final unresolvedAlerts = (summary['unresolved_alerts'] as num?)?.toInt() ?? 0;

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 1 — Farm Header
                  Text(
                    widget.farm.farmName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Farm Overview',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // SECTION 2 — Summary Cards
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SummaryCard(
                      title: 'Critical',
                      count: criticalCount,
                      color: const Color(0xFFFF0000),
                    ),
                    SummaryCard(
                      title: 'Warning',
                      count: warningCount,
                      color: Colors.orange,
                    ),
                    SummaryCard(
                      title: 'Healthy',
                      count: normalCount,
                      color: const Color(0xFF37FD12),
                    ),
                    SummaryCard(
                      title: 'Active Alerts',
                      count: unresolvedAlerts,
                      color: const Color(0xFF0000FF),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // SECTION 3 — Recent Alerts Preview
                const Text(
                  'Recent Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _RecentAlerts(alertsFuture: _alertsFuture),
                const SizedBox(height: 24),

                // SECTION 4 — Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CattleListPage()),
                      );
                    },
                    icon: const Icon(Icons.pets),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('View All Cattle'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QuickCheckPage()),
                      );
                    },
                    icon: const Icon(Icons.search),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Quick Check'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PassbookPage()),
                      );
                    },
                    icon: const Icon(Icons.receipt),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Passbook'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FarmDetailPage(farm: widget.farm),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Manage Farm'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }
}

class _RecentAlerts extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> alertsFuture;

  const _RecentAlerts({required this.alertsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: alertsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final allAlerts = snapshot.data ?? [];
        final unresolved = allAlerts.where((a) => a['resolved'] != true).take(2).toList();

        if (unresolved.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No active alerts',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          );
        }

        return Column(
          children: [
            ...unresolved.map((alert) {
              final severity = alert['severity']?.toString() ?? 'normal';
              final message = alert['message']?.toString() ?? '';
              final createdAt = alert['created_at']?.toString() ?? '';

              Color severityColor;
              if (severity == 'critical') {
                severityColor = const Color(0xFFFF0000);
              } else if (severity == 'warning') {
                severityColor = Colors.orange;
              } else {
                severityColor = GowlokColors.primary;
              }

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                title: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  _formatTimestamp(createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AlertsPage(),
                      settings: const RouteSettings(name: AlertsPage.routeName),
                    ),
                  );
                },
                child: const Text('View All Alerts'),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return raw;
    }
  }
}
