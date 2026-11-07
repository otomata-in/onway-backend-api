import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/home_state.dart';

class CategoryChips extends StatelessWidget {
  final List<CategoryInfo> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryChips({super.key, required this.categories, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.name == selected;
          return GestureDetector(
            onTap: () => onSelected(cat.name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: isSelected ? null : Border.all(color: AppColors.surfaceContainerHigh),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(cat.name, style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.onSurface,
                )),
              ]),
            ),
          );
        },
      ),
    );
  }
}
