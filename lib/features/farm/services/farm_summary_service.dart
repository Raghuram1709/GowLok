import 'package:supabase_flutter/supabase_flutter.dart';

class FarmSummaryService {
  static final _client = Supabase.instance.client;

  /// Calls the RPC `get_farm_summary` with `p_farm_id` and returns a
  /// `Map<String, dynamic>`. If the RPC returns null or an unexpected
  /// shape, an empty map is returned.
  static Future<Map<String, dynamic>> getSummary(String farmId) async {
    try {
      final resp = await _client.rpc('get_farm_summary', params: {
        'p_farm_id': farmId,
      });

      if (resp == null) return {};

      if (resp is Map) return Map<String, dynamic>.from(resp);

      if (resp is List && resp.isNotEmpty) {
        final first = resp[0];
        if (first is Map) return Map<String, dynamic>.from(first);
      }

      return {};
    } catch (e) {
      return {};
    }
  }
}
