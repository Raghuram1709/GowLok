import 'dart:async';
import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../services/alert_realtime_service.dart';
import '../../farm/farm_context.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/top_app_bar.dart';
import '../../../core/locale/app_translations.dart';

class AlertsPage extends StatefulWidget {
  static const routeName = '/alerts';
  const AlertsPage({Key? key}) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late Future<List<List<Map<String, dynamic>>>> _alertsFuture;
  StreamSubscription<void>? _alertSub;

  @override
  void initState() {
    super.initState();
    final activeFarm = FarmContext.activeFarm;
    if (activeFarm != null) {
      AlertRealtimeService().subscribe(activeFarm.farmId);
      _alertsFuture = _fetchAlerts(activeFarm.farmId);
      _alertSub = AlertRealtimeService().alertStream.listen((_) {
        _onPullToRefresh();
      });
    } else {
      _alertsFuture = Future.value([[], []]);
    }
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    AlertRealtimeService().unsubscribe();
    super.dispose();
  }

  Future<List<List<Map<String, dynamic>>>> _fetchAlerts(String farmId) {
    return Future.wait([
      AlertService.getAlerts(farmId),
      AlertService.getPendingApprovals(farmId),
    ]);
  }

  Future<void> _onPullToRefresh() async {
    final activeFarm = FarmContext.activeFarm;
    if (activeFarm != null) {
      final newAlerts = await _fetchAlerts(activeFarm.farmId);
      if (mounted) {
        setState(() {
          _alertsFuture = Future.value(newAlerts);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final farm = FarmContext.activeFarm;
    if (farm == null) {
      return Scaffold(
        appBar: GowlokTopBar(title: tr(context, 'alerts')),
        bottomNavigationBar: GlobalBottomNav.persistent(context),
        body: const Center(child: Text('No active farm selected.')),
      );
    }

    return Scaffold(
      appBar: GowlokTopBar(title: tr(context, 'alerts')),
      bottomNavigationBar: GlobalBottomNav.persistent(context),
      body: FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: _alertsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final alerts = snapshot.data?[0] ?? [];
          final approvals = snapshot.data?[1] ?? [];

          return RefreshIndicator(
            onRefresh: _onPullToRefresh,
            child: (alerts.isEmpty && approvals.isEmpty)
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(child: Text(tr(context, 'no_alerts'))),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(GowlokSpacing.md),
                    children: [
                      if (approvals.isNotEmpty) ...[
                        Text('Pending Approvals', style: GowlokTextStyles.headline3),
                        const SizedBox(height: GowlokSpacing.sm),
                        ...approvals.map((approval) => _buildApprovalCard(approval, farm.role)),
                        const SizedBox(height: GowlokSpacing.lg),
                      ],
                      if (alerts.isNotEmpty) ...[
                        Text('Alerts', style: GowlokTextStyles.headline3),
                        const SizedBox(height: GowlokSpacing.sm),
                        ...alerts.map((alert) => _buildAlertCard(alert, farm.role)),
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> approval, String role) {
    final cattle = approval['cattle'] as Map<String, dynamic>? ?? {};
    final tagNumber = cattle['tag_number']?.toString() ?? 'Unknown';
    final action = approval['action']?.toString().toUpperCase() ?? 'ACTION';
    final createdAt = approval['created_at']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: GowlokSpacing.md),
      child: Card(
        color: GowlokColors.primary.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: GowlokColors.primary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(GowlokSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Pending $action: Cattle $tagNumber',
                      style: GowlokTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: GowlokSpacing.sm, vertical: GowlokSpacing.xs),
                    decoration: BoxDecoration(
                      color: GowlokColors.primary,
                      borderRadius: BorderRadius.circular(GowlokTheme.chipRadius),
                    ),
                    child: Text(
                      'APPROVAL',
                      style: GowlokTextStyles.labelSmall.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GowlokSpacing.sm),
              Text(
                _formatTimestamp(createdAt),
                style: GowlokTextStyles.bodySmall.copyWith(color: GowlokColors.neutral600),
              ),
              if (role.toLowerCase() == 'admin') ...[
                const SizedBox(height: GowlokSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showReviewDialog(approval),
                    child: const Text('Review'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, String role) {
    final severity = alert['severity']?.toString() ?? 'normal';
    final message = alert['message']?.toString() ?? '';
    final resolved = alert['resolved'] as bool? ?? false;
    final createdAt = alert['created_at']?.toString() ?? '';
    final alertId = alert['id']?.toString() ?? '';

    Color bgColor = Colors.transparent;
    if (severity == 'critical') {
      bgColor = GowlokColors.critical.withValues(alpha: 0.1);
    } else if (severity == 'warning') {
      bgColor = const Color(0xFFFFA500).withValues(alpha: 0.1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: GowlokSpacing.md),
      child: Card(
        color: bgColor,
        child: Padding(
          padding: const EdgeInsets.all(GowlokSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(message, style: GowlokTextStyles.bodyLarge),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: GowlokSpacing.sm, vertical: GowlokSpacing.xs),
                    decoration: BoxDecoration(
                      color: severity == 'critical'
                          ? GowlokColors.critical
                          : severity == 'warning'
                              ? const Color(0xFFFFA500)
                              : GowlokColors.primary,
                      borderRadius: BorderRadius.circular(GowlokTheme.chipRadius),
                    ),
                    child: Text(
                      severity.toUpperCase(),
                      style: GowlokTextStyles.labelSmall.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GowlokSpacing.sm),
              Text(
                _formatTimestamp(createdAt),
                style: GowlokTextStyles.bodySmall.copyWith(color: GowlokColors.neutral600),
              ),
              if (!resolved && role.toLowerCase() == 'admin') ...[
                const SizedBox(height: GowlokSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await AlertService.resolveAlert(alertId);
                        if (mounted) setState(() {});
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
  }

  void _showReviewDialog(Map<String, dynamic> approval) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ApprovalReviewSheet(
        approval: approval,
        onReviewed: () {
          if (mounted) setState(() {});
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

class _ApprovalReviewSheet extends StatefulWidget {
  final Map<String, dynamic> approval;
  final VoidCallback onReviewed;

  const _ApprovalReviewSheet({required this.approval, required this.onReviewed});

  @override
  State<_ApprovalReviewSheet> createState() => _ApprovalReviewSheetState();
}

class _ApprovalReviewSheetState extends State<_ApprovalReviewSheet> {
  final _remarksController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _processApproval(String status) async {
    setState(() => _isProcessing = true);
    try {
      await AlertService.reviewApproval(
        approvalId: widget.approval['id'],
        status: status,
        remarks: _remarksController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onReviewed();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cattle $status successfully'),
          backgroundColor: status == 'approved' ? Colors.green[600] : Colors.red[600],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red[600]),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cattle = widget.approval['cattle'] as Map<String, dynamic>? ?? {};
    final imageUrl = cattle['primary_image_url']?.toString();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: GowlokSpacing.md,
        right: GowlokSpacing.md,
        top: GowlokSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review Registration', style: GowlokTextStyles.headline3),
          const SizedBox(height: GowlokSpacing.md),
          
          if (imageUrl != null && imageUrl.isNotEmpty)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                ),
              ),
            ),
          
          const SizedBox(height: GowlokSpacing.md),
          _detailRow('Tag Number', cattle['tag_number']?.toString() ?? 'N/A'),
          _detailRow('Name', cattle['name']?.toString() ?? 'None'),
          _detailRow('Breed', cattle['breed']?.toString() ?? 'N/A'),
          _detailRow('Gender', cattle['gender']?.toString().toUpperCase() ?? 'N/A'),
          _detailRow('Date of Birth', cattle['date_of_birth']?.toString() ?? 'N/A'),
          
          const SizedBox(height: GowlokSpacing.md),
          TextField(
            controller: _remarksController,
            decoration: const InputDecoration(
              labelText: 'Remarks (Optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          
          const SizedBox(height: GowlokSpacing.lg),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _processApproval('rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GowlokColors.critical,
                      side: const BorderSide(color: GowlokColors.critical),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: GowlokSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _processApproval('approved'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: GowlokSpacing.lg),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
