import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  static const _navItems = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.map_rounded, label: 'Live Map'),
    (icon: Icons.bookmark_rounded, label: 'Saved'),
    (icon: Icons.qr_code_scanner_rounded, label: 'Scan'),
    (icon: Icons.shopping_bag_rounded, label: 'Orders'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final navWidth = math.min(screenWidth - 32, 380.0);

    return Center(
      child: Container(
        width: navWidth,
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isActive = index == currentIndex;
            return Tooltip(
              message: item.label,
              child: GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    item.icon,
                    color: isActive ? Colors.white : AppColors.onSurfaceVariant,
                    size: 23,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
