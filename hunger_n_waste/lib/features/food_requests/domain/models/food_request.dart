import '../../../auth/domain/models/organization_profile.dart';

enum FoodRequestStatus { open, pendingPickup, inTransit, completed, cancelled }

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
  });

  factory FoodRequest.fromJson(Map<String, dynamic> json) {
    return FoodRequest(
      id: json['id'] as String,
      orgId: json['org_id'] as String,
      foodType: json['food_type'] as String,
      quantity: json['quantity'] as int,
      status: FoodRequestStatus.values.firstWhere(
        (e) => e.name == _snakeToCamel(json['status'] as String),
        orElse: () => FoodRequestStatus.open,
      ),
      donorId: json['donor_id'] as String?,
      riderId: json['rider_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      organization: json['organization_profiles'] != null
          ? OrganizationProfile.fromJson(json['organization_profiles'])
          : null,
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
}
