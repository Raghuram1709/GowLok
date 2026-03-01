import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class CattleRegistrationService {
  CattleRegistrationService._();
  static final _client = Supabase.instance.client;

  /// Check if tag is unique within farm (case-insensitive)
  static Future<bool> isTagUnique(String farmId, String tagNumber) async {
    try {
      final response = await _client
          .from('cattle')
          .select('id')
          .eq('farm_id', farmId)
          .ilike('tag_number', tagNumber.trim());
      return response.isEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Upload image to Supabase storage and return public URL
  static Future<String?> uploadImage(File imageFile, String tagNumber) async {
    try {
      final ext = imageFile.path.split('.').last;
      final fileName =
          '${tagNumber.trim()}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storagePath = 'cattle-images/$fileName';

      await _client.storage
          .from('cattle-images')
          .upload(storagePath, imageFile);

      final publicUrl =
          _client.storage.from('cattle-images').getPublicUrl(storagePath);

      return publicUrl;
    } catch (_) {
      return null;
    }
  }

  /// Insert cattle record, returns the inserted row
  static Future<Map<String, dynamic>> insertCattle({
    required String farmId,
    required String tagNumber,
    required String breed,
    required String gender,
    required String dateOfBirth,
    required String registeredBy,
    String? name,
    String? primaryImageUrl,
    bool? isPregnant,
  }) async {
    final genderLower = gender.trim().toLowerCase();
    final response = await _client.from('cattle').insert({
      'farm_id': farmId,
      'tag_number': tagNumber.trim(),
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      'breed': breed.trim(),
      'gender': genderLower,
      'date_of_birth': dateOfBirth,
      'registered_by': registeredBy,
      'is_active': false,
      'is_pregnant': genderLower == 'female' ? (isPregnant ?? false) : null,
      if (primaryImageUrl != null) 'primary_image_url': primaryImageUrl,
    }).select().single();
    return Map<String, dynamic>.from(response);
  }

  /// Insert cattle profile
  static Future<void> insertProfile({
    required String cattleId,
    double? weight,
    String? colorPattern,
    String? shedLocation,
    int? gestationCount,
    int? birthCount,
    double? milkProduction,
    String? feedingType,
    String? hygieneHistory,
    String? supplierName,
    String? originPlace,
    String? previousHealthNotes,
    String? vaccinationHistory,
  }) async {
    await _client.from('cattle_profiles').insert({
      'cattle_id': cattleId,
      if (weight != null) 'weight': weight,
      if (colorPattern != null) 'color_pattern': colorPattern,
      if (shedLocation != null) 'shed_location': shedLocation,
      if (gestationCount != null) 'gestation_count': gestationCount,
      if (birthCount != null) 'birth_count': birthCount,
      if (milkProduction != null) 'milk_production': milkProduction,
      if (feedingType != null) 'feeding_type': feedingType,
      if (hygieneHistory != null) 'hygiene_history': hygieneHistory,
      if (supplierName != null) 'supplier_name': supplierName,
      if (originPlace != null) 'origin_place': originPlace,
      if (previousHealthNotes != null) 'previous_health_notes': previousHealthNotes,
      if (vaccinationHistory != null) 'vaccination_history': vaccinationHistory,
    });
  }

  /// Submit for approval
  static Future<void> submitApproval({
    required String farmId,
    required String cattleId,
  }) async {
    await _client.rpc('submit_approval', params: {
      'p_farm_id': farmId,
      'p_entity_type': 'cattle',
      'p_entity_id': cattleId,
      'p_action': 'create',
    });
  }

  /// Delete cattle record (cleanup on profile insert failure)
  static Future<void> deleteCattle(String cattleId) async {
    try {
      await _client.from('cattle').delete().eq('id', cattleId);
    } catch (_) {}
  }
}
