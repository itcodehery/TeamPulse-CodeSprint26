import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/donor_profile.dart';
import '../../domain/models/organization_profile.dart';
import '../../domain/models/rider_profile.dart';
import '../../domain/models/user_enums.dart';

class AuthState {
  final AppUser? user;
  final DonorProfile? donorProfile;
  final OrganizationProfile? organizationProfile;
  final RiderProfile? riderProfile;
  final bool isLoading;

  const AuthState({
    this.user,
    this.donorProfile,
    this.organizationProfile,
    this.riderProfile,
    this.isLoading = false,
  });

  AuthState copyWith({
    AppUser? user,
    DonorProfile? donorProfile,
    OrganizationProfile? organizationProfile,
    RiderProfile? riderProfile,
    bool? isLoading,
  }) {
    return AuthState(
      user: user ?? this.user,
      donorProfile: donorProfile ?? this.donorProfile,
      organizationProfile: organizationProfile ?? this.organizationProfile,
      riderProfile: riderProfile ?? this.riderProfile,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Simulate initial login for testing (Mock Data)
    // We can't call methods in build easily without side effects,
    // so we return the initial state directly.
    return AuthState(
      user: AppUser(
        id: 'user_1',
        email: 'donor@example.com',
        name: 'John Doe',
        phoneNumber: '+91 9876543210',
        userType: UserType.donor,
        createdAt: DateTime.now(),
      ),
      donorProfile: const DonorProfile(
        id: 'user_1',
        defaultAddress: '123 Green Street, Mumbai',
        defaultLatitude: 19.0760,
        defaultLongitude: 72.8777,
      ),
    );
  }

  void loginAsDonor() {
    state = AuthState(
      user: AppUser(
        id: 'user_1',
        email: 'donor@example.com',
        name: 'John Doe',
        phoneNumber: '+91 9876543210',
        userType: UserType.donor,
        createdAt: DateTime.now(),
      ),
      donorProfile: const DonorProfile(
        id: 'user_1',
        defaultAddress: '123 Green Street, Mumbai',
        defaultLatitude: 19.0760,
        defaultLongitude: 72.8777,
      ),
    );
  }

  void loginAsOrganization() {
    state = AuthState(
      user: AppUser(
        id: 'org_1',
        email: 'help@ngo.org',
        name: 'Helping Hands',
        phoneNumber: '+91 9998887776',
        userType: UserType.organization,
        createdAt: DateTime.now(),
      ),
      organizationProfile: const OrganizationProfile(
        id: 'org_1',
        organizationName: 'Helping Hands Foundation',
        organizationType: OrganizationType.ngo,
        address: '45 Charity Lane, Delhi',
        isVerified: true,
        latitude: 28.6139,
        longitude: 77.2090,
      ),
    );
  }

  void loginAsRider() {
    state = AuthState(
      user: AppUser(
        id: 'rider_1',
        email: 'rider@delivery.com',
        name: 'Speedy Singh',
        phoneNumber: '+91 7776665554',
        userType: UserType.rider,
        createdAt: DateTime.now(),
      ),
      riderProfile: const RiderProfile(
        id: 'rider_1',
        vehicleType: 'Bike',
        vehicleNumber: 'KA-01-AB-1234',
        isAvailable: true,
      ),
    );
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
