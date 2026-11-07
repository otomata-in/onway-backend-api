import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/bloc/vendor_home_bloc.dart';
import '../../../home/presentation/bloc/vendor_home_event.dart';
import '../../../home/presentation/bloc/vendor_home_state.dart';

class VendorInventoryPage extends StatelessWidget {
  final VendorHomeState state;
  const VendorInventoryPage({super.key, required this.state});

  static const _presetImages = [
    'assets/images/vendor_green_valley.png',
    'assets/images/stitch_saved_vendor_1.png',
    'assets/images/stitch_saved_vendor_2.png',
    'assets/images/vendor_ocean_catch.png',
  ];

  static const _categories = [
    'Vegetables',
    'Fruits',
    'Fish & Seafood',
    'Meat & Poultry',
    'Bakery & Pastries',
    'Dairy & Fresh Products',
  ];

  static const _stockLevels = ['Good', 'Medium', 'Low'];

  void _showAddItemModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedCategory = _categories.first;
    bool inStock = true;
    String selectedStock = _stockLevels.first;
    String selectedImagePath = _presetImages.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Product Item',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.outline),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Item Name
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Item Name (e.g. Fresh Tomatoes)',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              // Category Selection
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Product Category',
                  prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setStateModal(() => selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),
              // Stock Available Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stock Status:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        inStock ? 'Stock Available' : 'Stock Over',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: inStock ? AppColors.primary : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: inStock,
                        onChanged: (val) => setStateModal(() => inStock = val),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
              if (inStock) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedStock,
                  decoration: InputDecoration(
                    labelText: 'Stock Level Option',
                    prefixIcon: const Icon(Icons.inventory_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _stockLevels
                      .map((st) => DropdownMenuItem(value: st, child: Text('$st Stock')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setStateModal(() => selectedStock = val);
                  },
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Select Item Image',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.outline,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _presetImages.map((path) {
                  final isSelected = selectedImagePath == path;
                  return GestureDetector(
                    onTap: () => setStateModal(() => selectedImagePath = path),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(path, fit: BoxFit.cover),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter an item name', style: GoogleFonts.plusJakartaSans()),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    final newItem = InventoryItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      category: selectedCategory,
                      inStock: inStock,
                      stockLevel: selectedStock,
                      imagePath: selectedImagePath,
                    );
                    context.read<VendorHomeBloc>().add(VendorAddItem(newItem));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"$name" added to inventory!', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add Product Item',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStockLevelPicker(BuildContext context, InventoryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Stock Level - ${item.name}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ..._stockLevels.map((level) {
              final isSelected = item.stockLevel == level;
              final badgeColor = _getStockColor(level);
              return ListTile(
                leading: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                ),
                title: Text(
                  '$level Stock',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.onSurface,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  context.read<VendorHomeBloc>().add(VendorUpdateStockLevel(item.id, level));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.name} stock level set to $level', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getStockColor(String level) {
    switch (level) {
      case 'Good':
        return const Color(0xFF16A34A); // Green
      case 'Medium':
        return const Color(0xFFEAB308); // Yellow
      case 'Low':
        return const Color(0xFFF97316); // Orange
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Inventory',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddItemModal(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.inventory.length,
            itemBuilder: (context, index) {
              final item = state.inventory[index];
              final stockColor = _getStockColor(item.stockLevel);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceContainer),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.asset(
                          item.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: AppColors.primaryContainer,
                            child: const Icon(Icons.shopping_bag, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.outline,
                            ),
                          ),
                          if (item.inStock) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => _showStockLevelPicker(context, item),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: stockColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: stockColor.withValues(alpha: 0.4), width: 1.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(color: stockColor, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${item.stockLevel} Stock',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: stockColor,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_drop_down, size: 16, color: stockColor),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Switch(
                          value: item.inStock,
                          onChanged: (val) {
                            context.read<VendorHomeBloc>().add(VendorToggleItemStock(item.id, val));
                          },
                          activeThumbColor: AppColors.primary,
                        ),
                        Text(
                          item.inStock ? 'Stock Available' : 'Stock Over',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.inStock ? AppColors.primary : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 100), // padding for bottom bar
        ],
      ),
    );
  }
}
