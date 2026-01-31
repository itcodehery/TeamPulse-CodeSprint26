import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/domain/models/organization_profile.dart';

class OrganizationCard extends StatelessWidget {
  final OrganizationProfile organization;
  final VoidCallback? onTap;
  final bool isOpen;

  const OrganizationCard({
    super.key,
    required this.organization,
    this.onTap,
    this.isOpen = true,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = _getColorForType(organization.organizationType);
    final typeIcon = _getIconForType(organization.organizationType);

    Widget cardContent = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isOpen ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        boxShadow: isOpen
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
        border: Border.all(
          color: isOpen ? Colors.grey[100]! : Colors.grey[200]!,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isOpen ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon/Image Section
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 28),
                ),
                const SizedBox(width: 16),

                // Content Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              organization.organizationName,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isOpen
                                    ? Colors.black87
                                    : Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (organization.isVerified && isOpen)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          organization.organizationType.name.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              organization.address,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey[500],
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

                // Action/Status Section
                if (isOpen)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'CLOSED',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return cardContent;
  }

  Color _getColorForType(dynamic organizationType) {
    final typeStr = organizationType.toString().toLowerCase();
    if (typeStr.contains('ngo')) return const Color(0xFF2E7D32);
    if (typeStr.contains('orphanage')) return const Color(0xFFE65100);
    if (typeStr.contains('oldagehome')) return const Color(0xFF6A1B9A);
    return const Color(0xFF1565C0);
  }

  IconData _getIconForType(dynamic organizationType) {
    final typeStr = organizationType.toString().toLowerCase();
    if (typeStr.contains('ngo')) return Icons.volunteer_activism_rounded;
    if (typeStr.contains('orphanage')) return Icons.child_care_rounded;
    if (typeStr.contains('oldagehome')) return Icons.elderly_rounded;
    return Icons.business_rounded;
  }
}
