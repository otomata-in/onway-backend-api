import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_top_bar.dart';

class AddressEditPage extends StatefulWidget {
  final String? addressId;
  final String? initialTitle;
  final String? initialAddress;
  final String? initialInstructions;
  final double? initialLatitude;
  final double? initialLongitude;

  const AddressEditPage({
    super.key,
    this.addressId,
    this.initialTitle,
    this.initialAddress,
    this.initialInstructions,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends State<AddressEditPage> {
  final _api = BuyerApiService();
  late TextEditingController _titleController;
  late TextEditingController _addressController;
  late TextEditingController _instructionsController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  bool _isLoading = false;
  bool _isFetchingGps = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _addressController = TextEditingController(text: widget.initialAddress ?? '');
    _instructionsController = TextEditingController(text: widget.initialInstructions ?? '');
    _latitudeController = TextEditingController(text: (widget.initialLatitude ?? 9.9790).toString());
    _longitudeController = TextEditingController(text: (widget.initialLongitude ?? 76.2760).toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _instructionsController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveGps() async {
    setState(() => _isFetchingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable GPS Location in your phone settings.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied in Android settings.')),
          );
        }
        return;
      }

      // Query raw hardware GPS sensor on Android
      LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 1),
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        );
      }

      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      setState(() {
        _latitudeController.text = pos.latitude.toStringAsFixed(6);
        _longitudeController.text = pos.longitude.toStringAsFixed(6);
      });

      // Reverse geocode to get street name if address text is empty
      try {
        final geoUri = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}');
        final geoRes = await http.get(geoUri, headers: {'User-Agent': 'OnWayMarket/1.0'}).timeout(const Duration(seconds: 3));
        if (geoRes.statusCode == 200) {
          final geoData = jsonDecode(geoRes.body);
          if (geoData['display_name'] != null && _addressController.text.trim().isEmpty) {
            setState(() {
              _addressController.text = geoData['display_name'];
            });
          }
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fetched live GPS coordinates: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching live GPS: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingGps = false);
    }
  }

  Future<void> _handleSaveAddress() async {
    final title = _titleController.text.trim();
    final addressLine = _addressController.text.trim();
    final instructions = _instructionsController.text.trim();
    final latVal = double.tryParse(_latitudeController.text.trim()) ?? 9.9790;
    final lngVal = double.tryParse(_longitudeController.text.trim()) ?? 76.2760;

    if (title.isEmpty || addressLine.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in Address Title and Delivery Address', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.addressId != null) {
        await _api.updateAddress(
          widget.addressId!,
          title: title,
          addressLine: addressLine,
          deliveryInstructions: instructions,
          latitude: latVal,
          longitude: lngVal,
        );
      } else {
        await _api.addAddress(
          title: title,
          addressLine: addressLine,
          deliveryInstructions: instructions,
          latitude: latVal,
          longitude: lngVal,
        );
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surface,
                    AppColors.surfaceContainerHigh.withValues(alpha: 0.3),
                    AppColors.surface,
                  ],
                ),
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              StandardTopBar(
                title: widget.initialAddress == null ? 'Add New Address' : 'Edit Address',
                icon: Icons.location_on_outlined,
                showBackButton: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionTitle('Location Details', 'Set delivery address & exact GPS coordinates'),
                    const SizedBox(height: 24),
                    
                    // 1. Address Title
                    _buildLabel('Address Title (e.g. Home, Work)', required: true),
                    const SizedBox(height: 8),
                    _GlassInputField(
                      controller: _titleController,
                      hintText: 'e.g. Home, Office, Apartment',
                      icon: Icons.label_outline,
                    ),
                    const SizedBox(height: 24),
                    
                    // 2. Delivery Address (Street Text)
                    _buildLabel('Delivery Address (Street & Building)', required: true),
                    const SizedBox(height: 8),
                    _GlassInputField(
                      controller: _addressController,
                      hintText: 'e.g. 123 Green Street, Apt 4B, Food City',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // 3. Delivery Location GPS Coordinates (Separate Fields!)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Delivery Location (GPS Coordinates)', required: true),
                        _buildCurrentLocationButton(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Latitude', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.outline)),
                              const SizedBox(height: 4),
                              _GlassInputField(
                                controller: _latitudeController,
                                hintText: '9.9790',
                                icon: Icons.my_location,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Longitude', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.outline)),
                              const SizedBox(height: 4),
                              _GlassInputField(
                                controller: _longitudeController,
                                hintText: '76.2760',
                                icon: Icons.explore_outlined,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // 4. Delivery Instructions (Optional)
                    _buildLabel('Delivery Instructions', optional: true),
                    const SizedBox(height: 8),
                    _GlassInputField(
                      controller: _instructionsController,
                      hintText: 'e.g. Leave at front door, ring doorbell 4B...',
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 48),
                    
                    // Save Button
                    _buildSaveButton(context),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, {bool required = false, bool optional = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        if (optional)
          Text(
            'Optional',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentLocationButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isFetchingGps ? null : _fetchLiveGps,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isFetchingGps
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.gps_fixed, color: AppColors.primary, size: 14),
              const SizedBox(width: 4),
              Text(
                _isFetchingGps ? 'Locating...' : 'Fetch GPS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSaveAddress,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Save Address & GPS Location',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: AppColors.onPrimary, size: 20),
                ],
              ),
      ),
    );
  }
}

class _GlassInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  const _GlassInputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  State<_GlassInputField> createState() => _GlassInputFieldState();
}

class _GlassInputFieldState extends State<_GlassInputField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: _isFocused ? 0.3 : 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused 
                    ? AppColors.primary 
                    : AppColors.outlineVariant.withValues(alpha: 0.2),
                width: _isFocused ? 2 : 1,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: widget.maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: widget.maxLines > 1 ? 16.0 : 0),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: _isFocused ? AppColors.primary : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    child: Icon(
                      widget.icon,
                      color: _isFocused ? AppColors.primary : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    maxLines: widget.maxLines,
                    keyboardType: widget.keyboardType,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: widget.maxLines > 1 ? 16 : 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
