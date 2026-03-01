import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/top_app_bar.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/theme/app_theme.dart';

class CattleFullDetailsPage extends StatelessWidget {
  final String cattleId;
  final String tagNumber;

  const CattleFullDetailsPage({
    Key? key,
    required this.cattleId,
    required this.tagNumber,
  }) : super(key: key);

  Future<Map<String, dynamic>> _fetchAll() async {
    final client = Supabase.instance.client;

    // Fetch cattle basic info
    final cattleResp = await client
        .from('cattle')
        .select()
        .eq('id', cattleId)
        .maybeSingle();

    // Fetch cattle profile
    final profileResp = await client
        .from('cattle_profiles')
        .select()
        .eq('cattle_id', cattleId)
        .maybeSingle();

    return {
      'cattle': cattleResp ?? {},
      'profile': profileResp ?? {},
    };
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
    } catch (_) {
      return raw;
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
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GowlokTopBar(title: 'Full Details'),
      bottomNavigationBar: GlobalBottomNav.persistent(context),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? {};
          final cattle = Map<String, dynamic>.from(data['cattle'] ?? {});
          final profile = Map<String, dynamic>.from(data['profile'] ?? {});

          final name = cattle['name']?.toString();
          final tag = cattle['tag_number']?.toString() ?? tagNumber;
          final breed = cattle['breed']?.toString();
          final gender = cattle['gender']?.toString();
          final dob = cattle['date_of_birth']?.toString();
          final age = _calculateAge(dob);
          final isPregnant = cattle['is_pregnant'];
          final imageUrl = cattle['primary_image_url']?.toString();

          final weight = profile['weight'];
          final color = profile['color_pattern']?.toString();
          final shed = profile['shed_location']?.toString();
          final gestationCount = profile['gestation_count'];
          final birthCount = profile['birth_count'];
          final milkProduction = profile['milk_production'];
          final feedingType = profile['feeding_type']?.toString();
          final hygiene = profile['hygiene_history']?.toString();
          final supplier = profile['supplier_name']?.toString();
          final origin = profile['origin_place']?.toString();
          final healthNotes = profile['previous_health_notes']?.toString();
          final vaccination = profile['vaccination_history']?.toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(GowlokSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 160,
                          height: 160,
                          color: GowlokColors.neutral300,
                          child: const Icon(Icons.image, size: 48),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: GowlokSpacing.md),

                // Basic Details
                _sectionCard(context, 'Basic Details', [
                  _row('Name', name),
                  _row('Tag Number', tag),
                  _row('Breed', breed),
                  _row('Gender', gender),
                  _row('Date of Birth', _formatDate(dob)),
                  _row('Age', '$age years'),
                  if (gender?.toLowerCase() == 'female')
                    _row('Pregnant', isPregnant == true ? 'Yes' : 'No'),
                ]),
                const SizedBox(height: GowlokSpacing.md),

                // Physical & Location
                _sectionCard(context, 'Physical & Location', [
                  _row('Weight', weight != null ? '$weight kg' : null),
                  _row('Color / Pattern', color),
                  _row('Shed Location', shed),
                ]),
                const SizedBox(height: GowlokSpacing.md),

                // Reproduction
                _sectionCard(context, 'Reproduction', [
                  _row('Gestation Count', gestationCount?.toString()),
                  _row('Birth Count', birthCount?.toString()),
                  _row('Milk Production',
                      milkProduction != null ? '$milkProduction L/day' : null),
                ]),
                const SizedBox(height: GowlokSpacing.md),

                // Feeding
                _sectionCard(context, 'Feeding', [
                  _row('Feeding Type', feedingType),
                ]),
                const SizedBox(height: GowlokSpacing.md),

                // Hygiene
                _sectionCard(context, 'Hygiene', [
                  _row('Hygiene Notes', hygiene),
                ]),
                const SizedBox(height: GowlokSpacing.md),

                // Supplier
                _sectionCard(context, 'Supplier', [
                  _row('Supplier Name', supplier),
                  _row('Origin Place', origin),
                ]),
                const SizedBox(height: GowlokSpacing.md),

                // Health notes
                _sectionCard(context, 'Health Notes', [
                  _row('Previous Health Notes', healthNotes),
                  _row('Vaccination History', vaccination),
                ]),
                const SizedBox(height: GowlokSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionCard(
      BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GowlokSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: GowlokSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: GowlokColors.neutral600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value != null && value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
