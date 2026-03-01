import 'package:supabase_flutter/supabase_flutter.dart';

class FarmContext {
  final String farmId;
  final String farmName;
  final String role;

  const FarmContext({
    required this.farmId,
    required this.farmName,
    required this.role,
  });

  static FarmContext? activeFarm;

  /// Get ALL farms the current user belongs to.
  static Future<List<FarmContext>> getAllFarms() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await Supabase.instance.client
          .from('farm_members')
          .select('farm_id, role, farms(name)')
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      final list = response as List;
      final farms = <FarmContext>[];

      for (final row in list) {
        final farmId = row['farm_id']?.toString();
        final role = row['role']?.toString() ?? 'worker';
        final farmsData = row['farms'] as Map<String, dynamic>?;
        final farmName = farmsData?['name']?.toString();

        if (farmId != null && farmName != null) {
          farms.add(FarmContext(
            farmId: farmId,
            farmName: farmName,
            role: role,
          ));
        }
      }

      // Set first farm as active if none set
      if (activeFarm == null && farms.isNotEmpty) {
        activeFarm = farms.first;
      }

      return farms;
    } catch (e) {
      return [];
    }
  }

  /// Resolve the first farm as active (for badges/alerts).
  static Future<FarmContext?> resolveActiveFarm() async {
    final farms = await getAllFarms();
    if (farms.isNotEmpty) {
      activeFarm = farms.first;
      return activeFarm;
    }
    activeFarm = null;
    return null;
  }
}
