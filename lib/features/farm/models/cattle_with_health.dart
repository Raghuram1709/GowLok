class CattleWithHealth {
  final String id;
  final String tagNumber;
  final String breed;
  final String gender;
  final String? primaryImageUrl;
  final String healthStatus;
  final bool hasActiveAlert;

  CattleWithHealth({
    required this.id,
    required this.tagNumber,
    required this.breed,
    required this.gender,
    required this.primaryImageUrl,
    required this.healthStatus,
    required this.hasActiveAlert,
  });

  factory CattleWithHealth.fromMap(
    Map<String, dynamic> cattle, {
    Map<String, dynamic>? latestHealth,
    bool hasActiveAlert = false,
  }) {
    String healthStatus = 'normal';
    if (latestHealth != null) {
      final status = latestHealth['status']?.toString().toLowerCase();
      if (status == 'warning' || status == 'critical') {
        healthStatus = status ?? 'normal';
      }
    }

    return CattleWithHealth(
      id: cattle['id']?.toString() ?? '',
      tagNumber: cattle['tag_number']?.toString() ?? '',
      breed: cattle['breed']?.toString() ?? '',
      gender: cattle['gender']?.toString() ?? '',
      primaryImageUrl: cattle['primary_image_url']?.toString(),
      healthStatus: healthStatus,
      hasActiveAlert: hasActiveAlert,
    );
  }
}
