import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import 'package:gowlok/core/widgets/top_app_bar.dart';
import 'package:gowlok/core/theme/health_status_colors.dart';
import 'package:gowlok/core/theme/app_theme.dart';
import '../../../core/locale/app_translations.dart';
import '../farm_context.dart';
import 'cattle_full_details_page.dart';
import 'cattle_edit_page.dart';

class CattleHealthDetailPage extends StatefulWidget {
  final String cattleId;
  final String tagNumber;

  const CattleHealthDetailPage(
      {Key? key, required this.cattleId, required this.tagNumber})
      : super(key: key);

  @override
  State<CattleHealthDetailPage> createState() =>
      _CattleHealthDetailPageState();
}

class _CattleHealthDetailPageState extends State<CattleHealthDetailPage> {
  late Future<Map<String, dynamic>?> _cattleFuture;
  late Future<Map<String, dynamic>?> _healthFuture;
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _cattleFuture = _fetchCattleIdentity();
    _healthFuture = _fetchLatestHealth();
    _historyFuture = _fetchHealthHistory();
  }

  Future<List<Map<String, dynamic>>> _fetchHealthHistory() async {
    final client = Supabase.instance.client;
    try {
      final resp = await client
          .from('cattle_health_readings')
          .select('status, body_temperature, heart_rate, recorded_at')
          .eq('cattle_id', widget.cattleId)
          .order('recorded_at', ascending: false)
          .limit(5);

      if (resp.isEmpty) return [];
      final list = resp as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchCattleIdentity() async {
    final client = Supabase.instance.client;
    try {
      final resp = await client
          .from('cattle')
          .select(
              'name, tag_number, breed, gender, date_of_birth, is_active, primary_image_url')
          .eq('id', widget.cattleId);

      if ((resp as List).isEmpty) return null;
      return Map<String, dynamic>.from(resp[0] as Map);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchLatestHealth() async {
    final client = Supabase.instance.client;
    try {
      final resp = await client
          .from('cattle_health_readings')
          .select(
              'body_temperature, heart_rate, activity_level, rumination_minutes, status, recorded_at')
          .eq('cattle_id', widget.cattleId)
          .order('recorded_at', ascending: false)
          .limit(1);

      if ((resp as List).isEmpty) return null;
      return Map<String, dynamic>.from(resp[0] as Map);
    } catch (e) {
      return null;
    }
  }

  int _calculateAge(String? dobString) {
    if (dobString == null) return 0;
    try {
      final dob = DateTime.parse(dobString);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  String _formatTimestamp(dynamic raw) {
    if (raw == null) return 'Unknown';
    DateTime? dt;
    if (raw is DateTime) dt = raw;
    if (raw is String) dt = DateTime.tryParse(raw);
    if (dt == null) return raw.toString();
    final local = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GowlokTopBar(
        title: tr(context, 'cattle_details'),
        extraActions: [
          if (FarmContext.activeFarm?.role.toLowerCase() == 'admin')
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Cattle',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CattleEditPage(
                      cattleId: widget.cattleId,
                      tagNumber: widget.tagNumber,
                    ),
                  ),
                );
                // Refresh data after edit
                if (mounted) {
                  setState(() => _loadData());
                }
              },
            ),
        ],
      ),
      bottomNavigationBar: GlobalBottomNav.persistent(context),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _cattleFuture,
        builder: (context, cattleSnapshot) {
          if (cattleSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cattleSnapshot.hasError) {
            return Center(child: Text('Error: ${cattleSnapshot.error}'));
          }

          final cattleData = cattleSnapshot.data;
          if (cattleData == null || cattleData.isEmpty) {
            return const Center(child: Text('Cattle details not available'));
          }

          final name = cattleData['name']?.toString();
          final breed = cattleData['breed']?.toString() ?? 'Unknown';
          final gender = cattleData['gender']?.toString() ?? '—';
          final dateOfBirth = cattleData['date_of_birth']?.toString();
          final age = _calculateAge(dateOfBirth);
          final imageUrl = cattleData['primary_image_url']?.toString();

          return FutureBuilder<Map<String, dynamic>?>(
            future: _healthFuture,
            builder: (context, healthSnapshot) {
              if (healthSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final healthData = healthSnapshot.data;
              final status = healthData?['status']?.toString();
              final bodyTemp = healthData?['body_temperature'];
              final heartRate = healthData?['heart_rate'];
              final activity = healthData?['activity_level'];
              final rumination = healthData?['rumination_minutes'];
              final recordedAt = healthData?['recorded_at'];

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(GowlokSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── CATTLE INFO CARD (IMAGE + DETAILS) ──
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(GowlokSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? GowlokColors.neutral700
                                      : GowlokColors.neutral200,
                                ),
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          width: 90,
                                          height: 90,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.pets, size: 40),
                                        ),
                                      )
                                    : const Icon(Icons.pets, size: 40),
                              ),
                              const SizedBox(width: GowlokSpacing.md),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (name != null && name.isNotEmpty)
                                      Text(
                                        name,
                                        style: GowlokTextStyles.headline1,
                                      ),
                                    Text(
                                      widget.tagNumber,
                                      style: name != null && name.isNotEmpty
                                          ? GowlokTextStyles.headline3
                                          : GowlokTextStyles.headline1,
                                    ),
                                    const SizedBox(height: GowlokSpacing.xs),
                                    Text(
                                      breed,
                                      style: GowlokTextStyles.bodyMedium
                                          .copyWith(
                                        color: GowlokColors.neutral600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$gender • $age years old',
                                      style: GowlokTextStyles.bodySmall
                                          .copyWith(
                                        color: GowlokColors.neutral600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── VIEW FULL DETAILS BUTTON ──
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: GowlokSpacing.sm,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CattleFullDetailsPage(
                                    cattleId: widget.cattleId,
                                    tagNumber: widget.tagNumber,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.info_outline, size: 18),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text('View Full Details'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: GowlokSpacing.sm),

                      // Health alert banners
                      if (healthData != null && healthData.isNotEmpty) ...[
                        if (status == 'critical')
                          _alertBanner(
                            icon: Icons.emergency,
                            color: GowlokColors.critical,
                            message: 'Immediate attention required',
                          ),
                        if (status == 'warning')
                          _alertBanner(
                            icon: Icons.warning,
                            color: const Color(0xFFFFA500),
                            message: 'Monitor health closely',
                          ),
                        const SizedBox(height: GowlokSpacing.md),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(GowlokSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tr(context, 'health_status'),
                                      style: GowlokTextStyles.headline3,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: GowlokSpacing.sm,
                                        vertical: GowlokSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: getHealthStatusColor(status),
                                        borderRadius: BorderRadius.circular(
                                          GowlokTheme.chipRadius,
                                        ),
                                      ),
                                      child: Text(
                                        (status ?? 'NORMAL').toUpperCase(),
                                        style: GowlokTextStyles.labelSmall
                                            .copyWith(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: GowlokSpacing.md),
                                _metricRow(
                                  tr(context, 'body_temp'),
                                  bodyTemp != null
                                      ? '${bodyTemp.toString()} °C'
                                      : '—',
                                ),
                                const SizedBox(height: GowlokSpacing.sm),
                                _metricRow(
                                  tr(context, 'heart_rate'),
                                  heartRate != null
                                      ? '${heartRate.toString()} bpm'
                                      : '—',
                                ),
                                const SizedBox(height: GowlokSpacing.sm),
                                _metricRow(
                                  tr(context, 'activity_level'),
                                  activity != null
                                      ? '${activity.toString()} %'
                                      : '—',
                                ),
                                const SizedBox(height: GowlokSpacing.sm),
                                _metricRow(
                                  tr(context, 'rumination'),
                                  rumination != null
                                      ? '${rumination.toString()} min/day'
                                      : '—',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(GowlokSpacing.md),
                            child: SizedBox(
                              width: double.infinity,
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.health_and_safety,
                                      size: 48,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? GowlokColors.neutral600
                                          : GowlokColors.neutral400,
                                    ),
                                    const SizedBox(height: GowlokSpacing.md),
                                    Text(
                                      tr(context, 'no_health_data'),
                                      style: GowlokTextStyles.bodyMedium
                                          .copyWith(
                                        color: GowlokColors.neutral600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: GowlokSpacing.md),
                      if (recordedAt != null)
                        Text(
                          'Last updated: ${_formatTimestamp(recordedAt)}',
                          style: GowlokTextStyles.bodySmall.copyWith(
                            color: GowlokColors.neutral600,
                          ),
                        ),
                      const SizedBox(height: GowlokSpacing.lg),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _historyFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return const SizedBox.shrink();
                          }

                          final items = snapshot.data ?? [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(context, 'recent_history'),
                                style: GowlokTextStyles.headline3,
                              ),
                              const SizedBox(height: GowlokSpacing.md),
                              if (items.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: GowlokSpacing.md,
                                  ),
                                  child: Center(
                                    child: Text(
                                      tr(context, 'no_history'),
                                      style: GowlokTextStyles.bodyMedium
                                          .copyWith(
                                        color: GowlokColors.neutral600,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...items.map((reading) {
                                  final s = reading['status']?.toString();
                                  final bt = reading['body_temperature'];
                                  final hr = reading['heart_rate'];
                                  final ra = reading['recorded_at'];
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: GowlokSpacing.sm,
                                    ),
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                            GowlokSpacing.md),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color:
                                                    getHealthStatusColor(s),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: GowlokSpacing.md,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    bt != null
                                                        ? '${bt.toString()} °C'
                                                        : '—',
                                                    style: GowlokTextStyles
                                                        .bodyMedium
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: GowlokSpacing.xs,
                                                  ),
                                                  Text(
                                                    hr != null
                                                        ? '${hr.toString()} bpm'
                                                        : '—',
                                                    style: GowlokTextStyles
                                                        .bodySmall
                                                        .copyWith(
                                                      color: GowlokColors
                                                          .neutral600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              _formatTimestamp(ra),
                                              style: GowlokTextStyles
                                                  .bodySmall
                                                  .copyWith(
                                                color:
                                                    GowlokColors.neutral600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _alertBanner({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GowlokSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(GowlokTheme.cardRadius),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: GowlokSpacing.md),
          Text(
            message,
            style: GowlokTextStyles.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GowlokTextStyles.bodyMedium),
        Text(
          value,
          style: GowlokTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
