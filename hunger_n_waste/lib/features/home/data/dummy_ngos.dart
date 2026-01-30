import '../../auth/domain/models/organization_profile.dart';
import '../../auth/domain/models/user_enums.dart';

final List<OrganizationProfile> dummyNGOs = [
  const OrganizationProfile(
    id: '1',
    organizationName: 'Helping Hands Foundation',
    organizationType: OrganizationType.ngo,
    address: '12 MG Road, Bangalore',
    latitude: 12.9716,
    longitude: 77.5946,
    isVerified: true,
  ),
  const OrganizationProfile(
    id: '2',
    organizationName: 'Delhi Orphanage',
    organizationType: OrganizationType.orphanage,
    address: '45 Connaught Place, New Delhi',
    latitude: 28.6139,
    longitude: 77.2090,
    isVerified: true,
  ),
  const OrganizationProfile(
    id: '3',
    organizationName: 'Mumbai Senior Care',
    organizationType: OrganizationType.oldAgeHome,
    address: '88 Marine Drive, Mumbai',
    latitude: 18.9220,
    longitude: 72.8347,
    isVerified: false,
  ),
  const OrganizationProfile(
    id: '4',
    organizationName: 'Green Earth India',
    organizationType: OrganizationType.ngo,
    address: '22 Park Street, Kolkata',
    latitude: 22.5726,
    longitude: 88.3639,
    isVerified: true,
  ),
  const OrganizationProfile(
    id: '5',
    organizationName: 'Food for All Chennai',
    organizationType: OrganizationType.other,
    address: '101 Anna Salai, Chennai',
    latitude: 13.0827,
    longitude: 80.2707,
    isVerified: true,
  ),
];
