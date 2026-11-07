import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class StandardTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onIconTap;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  const StandardTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onIconTap,
    this.showBackButton = true,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false, // Prevents default back button
      pinned: true,
      backgroundColor: AppColors.surface.withValues(alpha: 0.98),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 80,
      collapsedHeight: 56,
      toolbarHeight: 56,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ColorFilter.mode(Colors.white.withValues(alpha: 0.0), BlendMode.srcOver),
          child: FlexibleSpaceBar(
            expandedTitleScale: 1.15, // Reduced scaling effect
            titlePadding: const EdgeInsets.only(left: 16, bottom: 12, right: 16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showBackButton) ...[
                      GestureDetector(
                        onTap: () {
                          if (onBackTap != null) {
                            onBackTap!();
                          } else if (ModalRoute.of(context)?.canPop ?? false) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            height: 1.2,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (icon != null)
                  GestureDetector(
                    onTap: onIconTap,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 18),
                    ),
                  )
                else
                  const SizedBox(width: 35, height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
