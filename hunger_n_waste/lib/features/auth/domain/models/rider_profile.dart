class RiderProfile {
  final String id;
  final String? vehicleType;
  final String? vehicleNumber;
  final bool isAvailable;
  final double? currentLatitude;
  final double? currentLongitude;

  const RiderProfile({
    required this.id,
    this.vehicleType,
    this.vehicleNumber,
    this.isAvailable = false,
    this.currentLatitude,
    this.currentLongitude,
  });

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    return RiderProfile(
      id: json['id'] as String,
      vehicleType: json['vehicle_type'] as String?,
      vehicleNumber: json['vehicle_number'] as String?,
      isAvailable: json['is_available'] as bool? ?? false,
      currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
      currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'is_available': isAvailable,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
    };
  }
}
