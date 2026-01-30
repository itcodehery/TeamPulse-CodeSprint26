import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/domain/models/organization_profile.dart';

class OrganizationCard extends StatelessWidget {
  final OrganizationProfile organization;
  final VoidCallback? onTap;

  const OrganizationCard({super.key, required this.organization, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Organization Icon/Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getColorForType(organization.organizationType),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForType(organization.organizationType),
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              // Organization Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            organization.organizationName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (organization.isVerified)
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      organization.organizationType.name.toUpperCase(),
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: _getColorForType(organization.organizationType),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            organization.address,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForType(dynamic organizationType) {
    switch (organizationType.toString()) {
      case 'OrganizationType.ngo':
        return Colors.green;
      case 'OrganizationType.orphanage':
        return Colors.orange;
      case 'OrganizationType.oldAgeHome':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  IconData _getIconForType(dynamic organizationType) {
    switch (organizationType.toString()) {
      case 'OrganizationType.ngo':
        return Icons.volunteer_activism;
      case 'OrganizationType.orphanage':
        return Icons.child_care;
      case 'OrganizationType.oldAgeHome':
        return Icons.elderly;
      default:
        return Icons.business;
    }
  }
}
