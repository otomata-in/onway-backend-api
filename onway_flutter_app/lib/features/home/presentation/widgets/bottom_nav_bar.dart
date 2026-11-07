import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  static const _icons = [
    Icons.home,
    Icons.bookmark,
    Icons.qr_code_scanner,
    Icons.shopping_bag,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            final isActive = index == currentIndex;
            return GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Icon(
                  _icons[index],
                  color: isActive ? Colors.white : AppColors.onSurfaceVariant,
                  size: 24,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
