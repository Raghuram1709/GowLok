import 'package:supabase_flutter/supabase_flutter.dart';

class AlertService {
  static final _client = Supabase.instance.client;

  /// Get count of unresolved alerts for a farm
  static Future<int> getUnresolvedCount(String farmId) async {
    try {
      final response = await _client
          .from('alerts')
          .select('id')
          .eq('farm_id', farmId)
          .eq('resolved', false);

      return response.isEmpty ? 0 : response.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get all alerts for a farm ordered by created_at DESC
  static Future<List<Map<String, dynamic>>> getAlerts(String farmId) async {
    try {
      final response = await _client
          .from('alerts')
          .select()
          .eq('farm_id', farmId)
          .order('created_at', ascending: false);

      final list = response as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Resolve an alert by setting resolved = true
  static Future<void> resolveAlert(String alertId) async {
    try {
      await _client.from('alerts').update({'resolved': true}).eq('id', alertId);
    } catch (e) {
      rethrow;
    }
  }
}
