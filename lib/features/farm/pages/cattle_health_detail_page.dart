import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gowlok/core/widgets/top_app_bar.dart';
import 'package:gowlok/core/theme/health_status_colors.dart';
import 'package:gowlok/core/theme/app_theme.dart';

class CattleHealthDetailPage extends StatefulWidget {
  final String cattleId;
  final String tagNumber;

  const CattleHealthDetailPage({Key? key, required this.cattleId, required this.tagNumber}) : super(key: key);

  @override
  State<CattleHealthDetailPage> createState() => _CattleHealthDetailPageState();
}

class _CattleHealthDetailPageState extends State<CattleHealthDetailPage> {
  late Future<Map<String, dynamic>?> _cattleFuture;
  late Future<Map<String, dynamic>?> _healthFuture;
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
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
          .select('tag_number, breed, gender, date_of_birth, is_active')
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
          .select('body_temperature, heart_rate, activity_level, rumination_minutes, status, recorded_at')
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
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
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
      appBar: GowlokTopBar(title: 'Cattle Details'),
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

          final breed = cattleData['breed']?.toString() ?? 'Unknown';
          final gender = cattleData['gender']?.toString() ?? '—';
          final dateOfBirth = cattleData['date_of_birth']?.toString();
          final age = _calculateAge(dateOfBirth);

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
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(GowlokSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                breed,
                                style: GowlokTextStyles.headline1,
                              ),
                              const SizedBox(height: GowlokSpacing.xs),
                              Text(
                                widget.tagNumber,
                                style: GowlokTextStyles.headline3,
                              ),
                              const SizedBox(height: GowlokSpacing.sm),
                              Text(
                                '$gender • $age years old',
                                style: GowlokTextStyles.bodySmall.copyWith(
                                  color: GowlokColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: GowlokSpacing.lg),
                      if (healthData != null && healthData.isNotEmpty) ...[
                        if (status == 'critical')
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(GowlokSpacing.md),
                            decoration: BoxDecoration(
                              color: GowlokColors.critical.withValues(alpha: 0.1),
                              border: Border.all(
                                color: GowlokColors.critical,
                                width: 2,
                              ),
                              borderRadius:
                                  BorderRadius.circular(GowlokTheme.cardRadius),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.emergency,
                                  color: GowlokColors.critical,
                                ),
                                const SizedBox(width: GowlokSpacing.md),
                                Text(
                                  'Immediate attention required',
                                  style: GowlokTextStyles.bodyLarge.copyWith(
                                    color: GowlokColors.critical,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (status == 'warning')
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(GowlokSpacing.md),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA500).withValues(alpha: 0.1),
                              border: Border.all(
                                color: Color(0xFFFFA500),
                                width: 2,
                              ),
                              borderRadius:
                                  BorderRadius.circular(GowlokTheme.cardRadius),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: Color(0xFFFFA500),
                                ),
                                const SizedBox(width: GowlokSpacing.md),
                                Text(
                                  'Monitor health closely',
                                  style: GowlokTextStyles.bodyLarge.copyWith(
                                    color: Color(0xFFFFA500),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
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
                                      'Health Status',
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
                                            .copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: GowlokSpacing.md),
                                _metricRow(
                                  'Body Temperature',
                                  bodyTemp != null
                                      ? '${bodyTemp.toString()} °C'
                                      : '—',
                                ),
                                const SizedBox(height: GowlokSpacing.sm),
                                _metricRow(
                                  'Heart Rate',
                                  heartRate != null
                                      ? '${heartRate.toString()} bpm'
                                      : '—',
                                ),
                                const SizedBox(height: GowlokSpacing.sm),
                                _metricRow(
                                  'Activity Level',
                                  activity != null
                                      ? '${activity.toString()} %'
                                      : '—',
                                ),
                                const SizedBox(height: GowlokSpacing.sm),
                                _metricRow(
                                  'Rumination',
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
                                      'No health data available',
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
                                'Recent Health History',
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
                                      'No previous health records',
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
                                        padding:
                                            const EdgeInsets.all(GowlokSpacing.md),
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
                                                color: GowlokColors
                                                    .neutral600,
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

  Widget _metricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GowlokTextStyles.bodyMedium,
        ),
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
