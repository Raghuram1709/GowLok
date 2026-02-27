import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cattle_with_health.dart';

class CattleService {
  CattleService._();

  static final _client = Supabase.instance.client;

  static Future<List<CattleWithHealth>> getCattleByFarm(String farmId) async {
    try {
      final cattleResponse = await _client
          .from('cattle')
          .select('id, tag_number, breed, gender, primary_image_url')
          .eq('farm_id', farmId)
          .eq('is_active', true);

      if (cattleResponse.isEmpty) {
        return [];
      }

      final cattleList =
          List<Map<String, dynamic>>.from(cattleResponse as List);

      final result = <CattleWithHealth>[];

      for (final cattle in cattleList) {
        final cattleId = cattle['id']?.toString();
        if (cattleId == null) continue;

        Map<String, dynamic>? latestHealth;
        bool hasActiveAlert = false;

        try {
          final healthResponse = await _client
              .from('cattle_health_readings')
              .select('status, recorded_at')
              .eq('cattle_id', cattleId)
              .order('recorded_at', ascending: false)
              .limit(1);

          if (healthResponse.isNotEmpty) {
            latestHealth =
                Map<String, dynamic>.from(healthResponse[0] as Map);
          }
        } catch (_) {
          latestHealth = null;
        }

        // Check for unresolved alerts
        try {
          final alertResponse = await _client
              .from('alerts')
              .select('id')
              .eq('cattle_id', cattleId)
              .eq('resolved', false);

          hasActiveAlert = alertResponse.isNotEmpty;
        } catch (_) {
          hasActiveAlert = false;
        }

        result.add(
          CattleWithHealth.fromMap(cattle, latestHealth: latestHealth, hasActiveAlert: hasActiveAlert),
        );
      }

      return result;
    } catch (e) {
      return [];
    }
  }
}
