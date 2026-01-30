class DonorProfile {
  final String id;
  final String? defaultAddress;
  final double? defaultLatitude;
  final double? defaultLongitude;

  const DonorProfile({
    required this.id,
    this.defaultAddress,
    this.defaultLatitude,
    this.defaultLongitude,
  });

  factory DonorProfile.fromJson(Map<String, dynamic> json) {
    return DonorProfile(
      id: json['id'] as String,
      defaultAddress: json['default_address'] as String?,
      defaultLatitude: (json['default_latitude'] as num?)?.toDouble(),
      defaultLongitude: (json['default_longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'default_address': defaultAddress,
      'default_latitude': defaultLatitude,
      'default_longitude': defaultLongitude,
    };
  }
}
