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

  /// Get pending approvals for a farm, joined with cattle details manually
  static Future<List<Map<String, dynamic>>> getPendingApprovals(String farmId) async {
    try {
      // Fetch approvals without join since entity_id is polymorphic
      final response = await _client
          .from('approvals')
          .select('''
            id,
            entity_type,
            entity_id,
            action,
            status,
            created_at
          ''')
          .eq('farm_id', farmId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final list = (response as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Fetch related cattle data separately
      for (var approval in list) {
        if (approval['entity_type'] == 'cattle') {
          try {
            final cattleResponse = await _client
                .from('cattle')
                .select('id, tag_number, name, breed, gender, primary_image_url, date_of_birth')
                .eq('id', approval['entity_id'].toString())
                .maybeSingle();
            
            if (cattleResponse != null) {
              approval['cattle'] = cattleResponse;
            }
          } catch (_) {
            // Cattle fetch failed, continue with just the approval data
          }
        }
      }
      
      return list;
    } catch (e) {
      print('Error fetching pending approvals: $e');
      return [];
    }
  }

  /// Review an approval (Approve or Reject)
  static Future<void> reviewApproval({
    required String approvalId,
    required String status, // 'approved' or 'rejected'
    String? remarks,
  }) async {
    try {
      await _client.rpc('review_approval', params: {
        'approval_id': approvalId,
        'new_status': status,
        'review_notes': remarks,
      });
    } catch (e) {
      rethrow;
    }
  }
}
