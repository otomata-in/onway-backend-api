import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/bloc/vendor_home_bloc.dart';
import '../../../home/presentation/bloc/vendor_home_event.dart';
import '../../../home/presentation/bloc/vendor_home_state.dart';

class VendorProfilePage extends StatelessWidget {
  final VendorHomeState state;
  final VoidCallback onLogout;

  const VendorProfilePage({
    super.key,
    required this.state,
    required this.onLogout,
  });

  static const _vehiclePresets = [
    'assets/images/vendor_green_valley.png',
    'assets/images/stitch_saved_vendor_1.png',
    'assets/images/stitch_saved_vendor_2.png',
    'assets/images/vendor_ocean_catch.png',
  ];

  void _showVehiclePhotoUpdateModal(BuildContext context) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Update Vehicle Photo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
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
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              ),
              title: Text('Take Vehicle Photo', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Camera opened (Demo)', style: GoogleFonts.plusJakartaSans()), backgroundColor: AppColors.primary),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              ),
              title: Text('Choose from Gallery', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gallery opened (Demo)', style: GoogleFonts.plusJakartaSans()), backgroundColor: AppColors.primary),
                );
              },
            ),
            const Divider(height: 24),
            Text(
              'Select Vehicle Preset Image',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _vehiclePresets.map((path) {
                final isSelected = state.vehicleImagePath == path;
                return GestureDetector(
                  onTap: () {
                    context.read<VendorHomeBloc>().add(VendorUpdateVehiclePhoto(path));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Vehicle photo updated!', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: Container(
                    width: 70,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(path, fit: BoxFit.cover),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  static const _sellerCategories = [
    'Organic Vegetables',
    'Fish & Seafood',
    'Bakery & Pastries',
    'Fresh Fruits',
    'Meat & Poultry',
    'Dairy & Fresh Products',
    'Spices & Groceries',
  ];

  void _showEditProfileModal(BuildContext context) {
    final nameCtrl = TextEditingController(text: state.vendorName);
    final vehicleCtrl = TextEditingController(text: state.vehicleNumber);
    String selectedCategory = _sellerCategories.contains(state.category)
        ? state.category
        : _sellerCategories.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Store & Seller Details',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Business / Store Name',
                  prefixIcon: const Icon(Icons.storefront, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Seller Type / Category',
                  prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _sellerCategories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setStateModal(() => selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: vehicleCtrl,
                decoration: InputDecoration(
                  labelText: 'Vehicle Registration Number',
                  prefixIcon: const Icon(Icons.directions_car, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<VendorHomeBloc>().add(
                      VendorUpdateProfile(
                        nameCtrl.text.trim(),
                        vehicleCtrl.text.trim(),
                        selectedCategory,
                      ),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Store & Seller Type updated!', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOperatingHoursModal(BuildContext context) {
    final hoursCtrl = TextEditingController(text: state.operatingHours);
    final presets = [
      '7:00 AM - 7:00 PM Daily',
      '6:00 AM - 9:00 PM Daily',
      '8:00 AM - 8:00 PM Daily',
      'Open 24/7',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Operating Hours',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: hoursCtrl,
              decoration: InputDecoration(
                labelText: 'Operating Hours Schedule',
                prefixIcon: const Icon(Icons.schedule, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quick Schedule Presets:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((preset) {
                return ActionChip(
                  label: Text(
                    preset,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  onPressed: () {
                    hoursCtrl.text = preset;
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newHours = hoursCtrl.text.trim();
              if (newHours.isNotEmpty) {
                context.read<VendorHomeBloc>().add(VendorUpdateOperatingHours(newHours));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Operating hours updated to "$newHours"', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Hours'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Seller Vehicle Landscape Banner Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceContainerHigh),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showVehiclePhotoUpdateModal(context),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            state.vehicleImagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: AppColors.primaryContainer,
                              child: const Icon(Icons.directions_car, size: 60, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.photo_camera, size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  state.vendorName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  state.category,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_car, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Vehicle Reg: ${state.vehicleNumber}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showEditProfileModal(context),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Store Info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Settings Group
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceContainerHigh),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.schedule, color: AppColors.primary),
                  title: Text('Operating Hours', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  subtitle: Text(state.operatingHours, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                  onTap: () => _showOperatingHoursModal(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                  title: Text('Seller License & Verification', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  subtitle: Text('FSSAI Verified Active', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.green)),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: Text('Logout Account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.error)),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // padding for bottom bar
        ],
      ),
    );
  }
}
