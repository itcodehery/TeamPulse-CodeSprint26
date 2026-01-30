import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
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
    // Start listening to auth changes
    final authSubscription = supabase
        .Supabase
        .instance
        .client
        .auth
        .onAuthStateChange
        .listen((data) {
          final session = data.session;
          if (session != null) {
            _loadUserData(session.user.id);
          } else {
            state = const AuthState();
          }
        });

    ref.onDispose(() {
      authSubscription.cancel();
    });

    // Check if checks are already signed in
    final currentUser = supabase.Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      _loadUserData(currentUser.id);
      return const AuthState(isLoading: true);
    }

    return const AuthState();
  }

  // Dispose subscription when the provider is destroyed?
  // Riverpod Notifier doesn't have a dispose method we can override easily for cleanup
  // typically, but keepAlive providers are long lived.
  // For simplicity we let it run. In a robust app we might use ref.onDispose.

  Future<void> _loadUserData(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final client = supabase.Supabase.instance.client;

      // 1. Fetch Basic Profile
      final profileData = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final appUser = AppUser.fromJson(profileData);

      DonorProfile? donorProfile;
      OrganizationProfile? orgProfile;
      RiderProfile? riderProfile;

      // 2. Fetch Specific Profile based on Type
      switch (appUser.userType) {
        case UserType.donor:
          final dData = await client
              .from('donor_profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();
          if (dData != null) donorProfile = DonorProfile.fromJson(dData);
          break;
        case UserType.organization:
          final oData = await client
              .from('organization_profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();
          if (oData != null) orgProfile = OrganizationProfile.fromJson(oData);
          break;
        case UserType.rider:
          final rData = await client
              .from('rider_profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();
          if (rData != null) riderProfile = RiderProfile.fromJson(rData);
          break;
      }

      state = AuthState(
        user: appUser,
        donorProfile: donorProfile,
        organizationProfile: orgProfile,
        riderProfile: riderProfile,
        isLoading: false,
      );
    } catch (e) {
      // In case of error (e.g. network), we might want to sign out or show error
      state = const AuthState(isLoading: false);
      print('Error loading user data: $e');
    }
  }

  Future<void> logout() async {
    await supabase.Supabase.instance.client.auth.signOut();
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
