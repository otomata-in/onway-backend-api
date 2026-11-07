import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../../features/home/presentation/bloc/vendor_home_bloc.dart';
import '../../features/home/presentation/bloc/vendor_home_event.dart';
import '../../features/home/presentation/bloc/vendor_home_state.dart';

class VendorTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final VoidCallback? onIconTap;
  final Widget? trailing;

  const VendorTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.onIconTap,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VendorHomeBloc, VendorHomeState>(
      builder: (context, state) {
        final isDeliveryMode = state.isDeliveryModeActive;

        return SliverAppBar(
          pinned: true,
          floating: false,
          toolbarHeight: 72,
          backgroundColor: Colors.white.withValues(alpha: 0.96),
          elevation: 0,
          scrolledUnderElevation: 2,
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Store Brand Identity & Subtitle
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'OnWay Partner',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Delivery Mode Toggle Switch & Logout Action
              Row(
                children: [
                  // ── Prominent Delivery Mode Toggle Pill Button ──
                  GestureDetector(
                    onTap: () {
                      final newMode = !isDeliveryMode;
                      context.read<VendorHomeBloc>().add(VendorToggleDeliveryMode(newMode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            newMode
                                ? '🚚 Delivery Mode Activated! Cards hidden for focused navigation.'
                                : '📋 Delivery Mode Off. Full setup cards restored.',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white),
                          ),
                          backgroundColor: newMode ? AppColors.primary : AppColors.outline,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: isDeliveryMode
                            ? const LinearGradient(
                                colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                              )
                            : null,
                        color: isDeliveryMode ? null : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDeliveryMode ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        boxShadow: isDeliveryMode
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDeliveryMode ? Icons.local_shipping_rounded : Icons.local_shipping_outlined,
                            size: 15,
                            color: isDeliveryMode ? Colors.white : const Color(0xFF334155),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isDeliveryMode ? 'DELIVERY ON' : 'DELIVERY OFF',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDeliveryMode ? Colors.white : const Color(0xFF334155),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(icon, color: AppColors.outline, size: 22),
                      onPressed: onIconTap,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
