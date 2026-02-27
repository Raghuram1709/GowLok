import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gowlok/core/widgets/top_app_bar.dart';
import 'package:gowlok/core/theme/health_status_colors.dart';
import 'package:gowlok/core/theme/app_theme.dart';

class QuickCheckPage extends StatefulWidget {
  const QuickCheckPage({Key? key}) : super(key: key);

  @override
  State<QuickCheckPage> createState() => _QuickCheckPageState();
}

class _QuickCheckPageState extends State<QuickCheckPage> {
  final TextEditingController _tagController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _search() async {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) {
      if (!mounted) return;
      setState(() => _error = 'Please enter a tag number');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final client = Supabase.instance.client;

      final cattleResp = await client
          .from('cattle')
          .select('id, tag_number, breed, gender, farm_id')
          .eq('tag_number', tag)
          .eq('is_active', true);

      if (!mounted) return;
      if (cattleResp == null || (cattleResp as List).isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'No cattle found with this tag';
        });
        return;
      }

      final cattle = Map<String, dynamic>.from(cattleResp[0] as Map);
      final cattleId = cattle['id']?.toString();
      final farmId = cattle['farm_id']?.toString();

      String? farmName;
      if (farmId != null) {
        try {
          final farmResp = await client.from('farms').select('name').eq('id', farmId);
          if (!mounted) return;
          if (farmResp != null && (farmResp as List).isNotEmpty) {
            farmName = (farmResp[0] as Map)['name']?.toString();
          }
        } catch (e) {
          farmName = null;
        }
      }

      Map<String, dynamic>? health;
      if (cattleId != null) {
        try {
          final healthResp = await client
              .from('cattle_health_readings')
              .select('body_temperature, heart_rate, activity_level, rumination_minutes, status, recorded_at')
              .eq('cattle_id', cattleId)
              .order('recorded_at', ascending: false)
              .limit(1);

          if (!mounted) return;
          if (healthResp != null && (healthResp as List).isNotEmpty) {
            health = Map<String, dynamic>.from(healthResp[0] as Map);
          }
        } catch (e) {
          health = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _result = {
          'cattle': cattle,
          'farmName': farmName,
          'health': health,
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
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
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GowlokTopBar(title: 'Quick Check'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GowlokSpacing.md),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Quick Check',
                  style: GowlokTextStyles.headline2,
                ),
                const SizedBox(height: GowlokSpacing.lg),
                TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    labelText: 'Cattle Tag Number',
                    hintText: 'e.g., TAG001',
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: GowlokSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _search,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Check'),
                  ),
                ),
                const SizedBox(height: GowlokSpacing.lg),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(GowlokSpacing.md),
                    decoration: BoxDecoration(
                      color: GowlokColors.critical.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(GowlokTheme.cardRadius),
                      border: Border.all(
                        color: GowlokColors.critical,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: GowlokTextStyles.bodyMedium.copyWith(
                        color: GowlokColors.critical,
                      ),
                    ),
                  ),
                if (_result != null) ...[
                  _buildIdentityCard(),
                  const SizedBox(height: GowlokSpacing.md),
                  _buildHealthCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityCard() {
    final cattle = _result!['cattle'] as Map<String, dynamic>;
    final farmName = _result!['farmName'] as String?;
    final breed = cattle['breed']?.toString() ?? 'Unknown';
    final tag = cattle['tag_number']?.toString() ?? '—';
    final gender = cattle['gender']?.toString() ?? '—';

    return Card(
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
              tag,
              style: GowlokTextStyles.headline3,
            ),
            const SizedBox(height: GowlokSpacing.sm),
            Text(
              gender,
              style: GowlokTextStyles.bodySmall.copyWith(
                color: GowlokColors.neutral600,
              ),
            ),
            if (farmName != null) ...[
              const SizedBox(height: GowlokSpacing.xs),
              Text(
                'Farm: $farmName',
                style: GowlokTextStyles.bodySmall.copyWith(
                  color: GowlokColors.neutral600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard() {
    final health = _result!['health'] as Map<String, dynamic>?;

    if (health == null || health.isEmpty) {
      return Card(
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? GowlokColors.neutral600
                        : GowlokColors.neutral400,
                  ),
                  const SizedBox(height: GowlokSpacing.md),
                  Text(
                    'No health data available',
                    style: GowlokTextStyles.bodyMedium.copyWith(
                      color: GowlokColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final status = health['status']?.toString();
    final bodyTemp = health['body_temperature'];
    final heartRate = health['heart_rate'];
    final activity = health['activity_level'];
    final rumination = health['rumination_minutes'];
    final recordedAt = health['recorded_at'];

    return Column(
      children: [
        if (status == 'critical')
          Padding(
            padding: const EdgeInsets.only(bottom: GowlokSpacing.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(GowlokSpacing.md),
              decoration: BoxDecoration(
                color: GowlokColors.critical.withOpacity(0.1),
                border: Border.all(color: GowlokColors.critical, width: 2),
                borderRadius:
                    BorderRadius.circular(GowlokTheme.cardRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.emergency, color: GowlokColors.critical),
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
          ),
        if (status == 'warning')
          Padding(
            padding: const EdgeInsets.only(bottom: GowlokSpacing.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(GowlokSpacing.md),
              decoration: BoxDecoration(
                color: Color(0xFFFFA500).withOpacity(0.1),
                border: Border.all(color: Color(0xFFFFA500), width: 2),
                borderRadius:
                    BorderRadius.circular(GowlokTheme.cardRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Color(0xFFFFA500)),
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
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(GowlokSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        borderRadius:
                            BorderRadius.circular(GowlokTheme.chipRadius),
                      ),
                      child: Text(
                        (status ?? 'NORMAL').toUpperCase(),
                        style: GowlokTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GowlokSpacing.md),
                _metricRow(
                  'Body Temperature',
                  bodyTemp != null ? '${bodyTemp.toString()} °C' : '—',
                ),
                const SizedBox(height: GowlokSpacing.sm),
                _metricRow(
                  'Heart Rate',
                  heartRate != null ? '${heartRate.toString()} bpm' : '—',
                ),
                const SizedBox(height: GowlokSpacing.sm),
                _metricRow(
                  'Activity Level',
                  activity != null ? '${activity.toString()} %' : '—',
                ),
                const SizedBox(height: GowlokSpacing.sm),
                _metricRow(
                  'Rumination',
                  rumination != null ? '${rumination.toString()} min/day' : '—',
                ),
                const SizedBox(height: GowlokSpacing.md),
                Text(
                  'Last updated: ${_formatTimestamp(recordedAt)}',
                  style: GowlokTextStyles.bodySmall.copyWith(
                    color: GowlokColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
