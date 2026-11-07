import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/bloc/home_state.dart';
import '../../../vendor_details/presentation/pages/live_tracking_page.dart';

class DeliveryTrackingControls extends StatelessWidget {
  final String vendorName;
  final String eta;
  final double progress; // 0.0 to 1.0
  final IconData progressIcon;
  final String distance;

  const DeliveryTrackingControls({
    super.key,
    required this.vendorName,
    required this.eta,
    required this.progress,
    required this.progressIcon,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProgressBarAndETA(),
        const SizedBox(height: 16),
        const Divider(color: AppColors.surfaceContainerHigh, height: 1),
        const SizedBox(height: 16),
        _buildFeaturesRow(),
        const SizedBox(height: 20),
        _buildFooterActions(context),
      ],
    );
  }

  Widget _buildProgressBarAndETA() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 32,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // Track
                    Container(
                      height: 6,
                      width: width,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E3DD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    // Fill
                    Container(
                      height: 6,
                      width: width * progress,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    // Start dot
                    Positioned(
                      left: 0,
                      child: Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                    ),
                    // Thumb
                    Positioned(
                      left: (width * progress) - 16,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Icon(progressIcon, size: 16, color: AppColors.primary),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8EE),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: Color(0xFF1EB956)),
              const SizedBox(width: 6),
              Text(
                eta,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1EB956),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPill(Icons.notifications_none, 'Notify on reach', false),
          const SizedBox(width: 8),
          _buildPill(Icons.calendar_today_outlined, 'Daily Tracking', false),
          const SizedBox(width: 8),
          _buildPill(Icons.notifications_active, 'Ring on Reach', true),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, String text, bool isHighlighted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFE8F8EE) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isHighlighted ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFFE2E3DD),
        ),
        boxShadow: isHighlighted ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 1))] : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isHighlighted ? AppColors.primary : const Color(0xFF9CA3AF)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
              color: isHighlighted ? AppColors.primary : const Color(0xFF1A1C19),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTrackingPage(
                orderInfo: ActiveOrderInfo(
                  vendorName: vendorName,
                  eta: eta,
                  distance: distance,
                  progress: progress,
                ),
              )));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1EB956),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.location_on, size: 18),
            label: Text('View Map', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1C19),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE2E3DD), width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.call_outlined, size: 18, color: Color(0xFF1EB956)),
            label: Text('Contact', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
