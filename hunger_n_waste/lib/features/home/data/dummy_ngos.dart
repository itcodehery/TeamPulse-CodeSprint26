import '../../auth/domain/models/organization_profile.dart';
import '../../auth/domain/models/user_enums.dart';

final List<OrganizationProfile> dummyNGOs = [
  const OrganizationProfile(
    id: '1',
    organizationName: 'Helping Hands Foundation',
    organizationType: OrganizationType.ngo,
    address: '123 Charity Lane, London',
    latitude: 51.5074,
    longitude: -0.1278,
    isVerified: true,
  ),
  const OrganizationProfile(
    id: '2',
    organizationName: 'City Orphanage',
    organizationType: OrganizationType.orphanage,
    address: '45 Hope Street, London',
    latitude: 51.5150,
    longitude: -0.0900,
    isVerified: true,
  ),
  const OrganizationProfile(
    id: '3',
    organizationName: 'Senior Care Home',
    organizationType: OrganizationType.oldAgeHome,
    address: '88 Elderly Avenue, London',
    latitude: 51.4900,
    longitude: -0.1400,
    isVerified: false,
  ),
  const OrganizationProfile(
    id: '4',
    organizationName: 'Green Earth Initiative',
    organizationType: OrganizationType.ngo,
    address: '22 Planet Road, London',
    latitude: 51.5200,
    longitude: -0.1100,
    isVerified: true,
  ),
  const OrganizationProfile(
    id: '5',
    organizationName: 'Food for All',
    organizationType: OrganizationType.other,
    address: '101 Community Blvd, London',
    latitude: 51.5000,
    longitude: -0.0800,
    isVerified: true,
  ),
];
