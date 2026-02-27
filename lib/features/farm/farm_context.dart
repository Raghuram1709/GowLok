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

  static Future<FarmContext?> resolveActiveFarm() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      activeFarm = null;
      return null;
    }

    final response = await Supabase.instance.client
        .from('farm_members')
        .select('farm_id, role, farms(name)')
        .eq('user_id', user.id)
        .order('created_at', ascending: true)
        .limit(1)
        .single();

    if (response == null) {
      activeFarm = null;
      return null;
    }

    final farmId = response['farm_id']?.toString();
    final role = response['role']?.toString() ?? 'worker';
    final farms = response['farms'] as Map<String, dynamic>?;
    final farmName = farms?['name']?.toString();

    if (farmId == null || farmName == null) {
      activeFarm = null;
      return null;
    }

    activeFarm = FarmContext(
      farmId: farmId,
      farmName: farmName,
      role: role,
    );

    return activeFarm;
  }
}
