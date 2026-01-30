import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/user_enums.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Not logged in'),
              ElevatedButton(
                onPressed: () {
                  // For demo purposes, re-login as donor
                  // In real app, navigate to login
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user.userType.name.toUpperCase(),
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(
              title: 'Contact Info',
              children: [
                _buildInfoRow(Icons.email, 'Email', user.email),
                if (user.phoneNumber != null)
                  _buildInfoRow(Icons.phone, 'Phone', user.phoneNumber!),
              ],
            ),
            const SizedBox(height: 20),

            // Specific Profile Details
            if (user.userType == UserType.donor &&
                authState.donorProfile != null)
              _buildInfoCard(
                title: 'Donor Details',
                children: [
                  if (authState.donorProfile!.defaultAddress != null)
                    _buildInfoRow(
                      Icons.location_on,
                      'Address',
                      authState.donorProfile!.defaultAddress!,
                    ),
                ],
              ),

            if (user.userType == UserType.organization &&
                authState.organizationProfile != null)
              _buildInfoCard(
                title: 'Organization Details',
                children: [
                  _buildInfoRow(
                    Icons.business,
                    'Type',
                    authState.organizationProfile!.organizationType.name
                        .toUpperCase(),
                  ),
                  _buildInfoRow(
                    Icons.location_city,
                    'Address',
                    authState.organizationProfile!.address,
                  ),
                  _buildInfoRow(
                    Icons.verified,
                    'Status',
                    authState.organizationProfile!.isVerified
                        ? 'Verified'
                        : 'Unverified',
                  ),
                ],
              ),

            if (user.userType == UserType.rider &&
                authState.riderProfile != null)
              _buildInfoCard(
                title: 'Rider Details',
                children: [
                  _buildInfoRow(
                    Icons.directions_bike,
                    'Vehicle',
                    authState.riderProfile!.vehicleType ?? 'N/A',
                  ),
                  _buildInfoRow(
                    Icons.confirmation_number,
                    'Plate Number',
                    authState.riderProfile!.vehicleNumber ?? 'N/A',
                  ),
                  _buildInfoRow(
                    Icons.circle,
                    'Status',
                    authState.riderProfile!.isAvailable ? 'Available' : 'Busy',
                  ),
                ],
              ),

            const SizedBox(height: 20),
            // Debug buttons to switch profiles
            const Divider(),
            const Text("Debug: Switch User Type"),
            Wrap(
              spacing: 10,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      ref.read(authProvider.notifier).loginAsOrganization(),
                  child: const Text("Org"),
                ),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(authProvider.notifier).loginAsRider(),
                  child: const Text("Rider"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
