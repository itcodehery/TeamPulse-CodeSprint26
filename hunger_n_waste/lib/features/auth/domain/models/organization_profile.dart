import 'user_enums.dart';

class OrganizationProfile {
  final String id;
  final String organizationName;
  final OrganizationType organizationType;
  final String address;
  final double? latitude;
  final double? longitude;
  final bool isVerified;
  final String? licenseNumber;

  const OrganizationProfile({
    required this.id,
    required this.organizationName,
    required this.organizationType,
    required this.address,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.licenseNumber,
  });

  factory OrganizationProfile.fromJson(Map<String, dynamic> json) {
    return OrganizationProfile(
      id: json['id'] as String,
      organizationName: json['organization_name'] as String,
      organizationType: OrganizationType.values.firstWhere(
        (e) => e.name == json['organization_type'],
        orElse: () => OrganizationType.other,
      ),
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isVerified: json['is_verified'] as bool? ?? false,
      licenseNumber: json['license_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_name': organizationName,
      'organization_type': organizationType.name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'is_verified': isVerified,
      'license_number': licenseNumber,
    };
  }
}
