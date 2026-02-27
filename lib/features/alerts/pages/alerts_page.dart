import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../services/alert_realtime_service.dart';
import '../../farm/farm_context.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/top_app_bar.dart';

class AlertsPage extends StatefulWidget {
  static const routeName = '/alerts';
  const AlertsPage({Key? key}) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late Future<List<Map<String, dynamic>>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    final activeFarm = FarmContext.activeFarm;
    if (activeFarm != null) {
      AlertRealtimeService().subscribe(activeFarm.farmId);
    }
    _refreshAlerts();
  }

  @override
  void dispose() {
    AlertRealtimeService().unsubscribe();
    super.dispose();
  }

  void _refreshAlerts() {
    final activeFarm = FarmContext.activeFarm;
    _alertsFuture = activeFarm != null
        ? AlertService.getAlerts(activeFarm.farmId)
        : Future.value([]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GowlokTopBar(title: 'Alerts'),
      body: StreamBuilder<void>(
        stream: AlertRealtimeService().alertStream,
        builder: (context, streamSnapshot) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _alertsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final alerts = snapshot.data ?? [];

              if (alerts.isEmpty) {
                return const Center(
                  child: Text('No alerts'),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(GowlokSpacing.md),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  final severity = alert['severity']?.toString() ?? 'normal';
                  final message = alert['message']?.toString() ?? '';
                  final resolved = alert['resolved'] as bool? ?? false;
                  final createdAt = alert['created_at']?.toString() ?? '';
                  final alertId = alert['id']?.toString() ?? '';

                  Color bgColor;
                  if (severity == 'critical') {
                    bgColor = GowlokColors.critical.withValues(alpha: 0.1);
                  } else if (severity == 'warning') {
                    bgColor = const Color(0xFFFFA500).withValues(alpha: 0.1);
                  } else {
                    bgColor = Colors.transparent;
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: GowlokSpacing.md),
                    child: Card(
                      color: bgColor,
                      child: Padding(
                        padding: EdgeInsets.all(GowlokSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    message,
                                    style: GowlokTextStyles.bodyLarge,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: GowlokSpacing.sm,
                                    vertical: GowlokSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: severity == 'critical'
                                        ? GowlokColors.critical
                                        : severity == 'warning'
                                            ? const Color(0xFFFFA500)
                                            : GowlokColors.primary,
                                    borderRadius: BorderRadius.circular(
                                      GowlokTheme.chipRadius,
                                    ),
                                  ),
                                  child: Text(
                                    severity.toUpperCase(),
                                    style: GowlokTextStyles.labelSmall.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: GowlokSpacing.sm),
                            Text(
                              _formatTimestamp(createdAt),
                              style: GowlokTextStyles.bodySmall.copyWith(
                                color: GowlokColors.neutral600,
                              ),
                            ),
                            if (!resolved) ...[
                              const SizedBox(height: GowlokSpacing.md),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                                    try {
                                      await AlertService.resolveAlert(alertId);
                                      if (mounted) {
                                        _refreshAlerts();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Resolve'),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return 'Unknown';
    try {
      final dt = DateTime.parse(raw);
      final local = dt.toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
    } catch (_) {
      return raw;
    }
  }
}
