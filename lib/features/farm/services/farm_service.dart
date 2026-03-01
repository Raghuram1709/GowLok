import 'package:supabase_flutter/supabase_flutter.dart';

class FarmService {
  static final _client = Supabase.instance.client;

  /// Rename a farm (admin-only).
  static Future<void> updateFarmName(String farmId, String newName) async {
    await _client.rpc('update_farm', params: {
      'p_farm_id': farmId,
      'p_new_name': newName,
    });
  }

  /// Add a worker to the farm by email (admin-only, always 'worker' role).
  static Future<void> addWorker(String farmId, String email) async {
    await _client.rpc('add_farm_worker', params: {
      'p_farm_id': farmId,
      'p_email': email.trim(),
    });
  }

  /// Remove a worker from the farm (admin-only).
  static Future<void> removeWorker(String farmId, String userId) async {
    await _client.rpc('remove_farm_worker', params: {
      'p_farm_id': farmId,
      'p_user_id': userId,
    });
  }

  /// Delete a farm and all related data (admin-only).
  static Future<void> deleteFarm(String farmId) async {
    await _client.rpc('delete_farm', params: {
      'p_farm_id': farmId,
    });
  }

  /// Get all members of a farm with email & role.
  static Future<List<Map<String, dynamic>>> getWorkers(String farmId) async {
    final resp = await _client.rpc('get_farm_workers', params: {
      'p_farm_id': farmId,
    });
    if (resp is List) {
      return resp.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }
}
