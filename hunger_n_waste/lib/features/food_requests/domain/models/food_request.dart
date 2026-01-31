import '../../../auth/domain/models/organization_profile.dart';

enum FoodRequestStatus {
  open,
  active,
  pendingPickup,
  inTransit,
  completed,
  cancelled,
}

class FoodRequest {
  final String id;
  final String orgId;
  final String foodType;
  final int quantity;
  final FoodRequestStatus status;
  final String? donorId;
  final String? riderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OrganizationProfile? organization; // Joined data
  // We might store location here or fetch from Org, assuming stored for now or handled via join
  final double latitude;
  final double longitude;

  const FoodRequest({
    required this.id,
    required this.orgId,
    required this.foodType,
    required this.quantity,
    this.status = FoodRequestStatus.open,
    this.donorId,
    this.riderId,
    required this.createdAt,
    required this.updatedAt,
    this.organization,
    required this.latitude,
    required this.longitude,
  });

  factory FoodRequest.fromJson(Map<String, dynamic> json) {
    final orgData = json['organization_profiles'];
    final orgProfile = orgData != null
        ? OrganizationProfile.fromJson(orgData)
        : null;

    final double lat =
        (json['latitude'] as num?)?.toDouble() ?? orgProfile?.latitude ?? 0.0;
    final double lng =
        (json['longitude'] as num?)?.toDouble() ?? orgProfile?.longitude ?? 0.0;

    try {
      return FoodRequest(
        id: json['id'] as String? ?? '',
        orgId: json['org_id'] as String? ?? '',
        foodType: json['food_type'] as String? ?? 'Unknown',
        quantity: json['quantity'] as int? ?? 0,
        status: FoodRequestStatus.values.firstWhere(
          (e) => e.name == _snakeToCamel(json['status'] as String? ?? 'open'),
          orElse: () => FoodRequestStatus.open,
        ),
        donorId: json['donor_id'] as String?,
        riderId: json['rider_id'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
        organization: orgProfile,
        latitude: lat,
        longitude: lng,
      );
    } catch (e) {
      rethrow;
    }
  }

  FoodRequest copyWith({
    String? id,
    String? orgId,
    String? foodType,
    int? quantity,
    FoodRequestStatus? status,
    String? donorId,
    String? riderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    OrganizationProfile? organization,
    double? latitude,
    double? longitude,
  }) {
    return FoodRequest(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      foodType: foodType ?? this.foodType,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      donorId: donorId ?? this.donorId,
      riderId: riderId ?? this.riderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organization: organization ?? this.organization,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'org_id': orgId,
      'food_type': foodType,
      'quantity': quantity,
      'status': _camelToSnake(status.name),
      'donor_id': donorId,
      'rider_id': riderId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static String _snakeToCamel(String snake) {
    // simple handling for our known values: pending_pickup -> pendingPickup
    if (snake == 'pending_pickup') return 'pendingPickup';
    if (snake == 'in_transit') return 'inTransit';
    return snake;
  }

  static String _camelToSnake(String camel) {
    if (camel == 'pendingPickup') return 'pending_pickup';
    if (camel == 'inTransit') return 'in_transit';
    return camel;
  }

  /// Returns a user-friendly display string for the current status
  String get statusDisplayString {
    switch (status) {
      case FoodRequestStatus.open:
        return 'Open';
      case FoodRequestStatus.active:
        return 'Active';
      case FoodRequestStatus.pendingPickup:
        return 'Pending Pickup';
      case FoodRequestStatus.inTransit:
        return 'In Transit';
      case FoodRequestStatus.completed:
        return 'Completed';
      case FoodRequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}
