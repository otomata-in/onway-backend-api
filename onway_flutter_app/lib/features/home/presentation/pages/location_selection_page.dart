import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_top_bar.dart';
import '../widgets/map_section.dart';
import 'address_edit_page.dart';

class LocationSelectionPage extends StatefulWidget {
  const LocationSelectionPage({super.key});

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  final _api = BuyerApiService();
  bool _isLoading = true;
  bool _isFetchingGps = false;
  String? _selectedAddressId;
  List<Map<String, dynamic>> _savedAddresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final res = await _api.getAddresses();
      if (res['success'] == true && res['data'] != null) {
        final list = res['data'] as List;
        setState(() {
          _savedAddresses = list.map<Map<String, dynamic>>((a) {
            final isDef = a['isDefault'] ?? false;
            if (isDef && _selectedAddressId == null) {
              _selectedAddressId = a['id'];
            }
            return {
              'id': a['id'],
              'title': a['title'] ?? 'Address',
              'subtitle': a['addressLine'] ?? '',
              'instructions': a['deliveryInstructions'] ?? '',
              'isDefault': isDef,
              'lat': (a['latitude'] as num?)?.toDouble() ?? 9.9790,
              'lng': (a['longitude'] as num?)?.toDouble() ?? 76.2760,
            };
          }).toList();

          if (_selectedAddressId == null && _savedAddresses.isNotEmpty) {
            _selectedAddressId = _savedAddresses.first['id'] as String?;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _savedAddresses = _fallbackAddresses;
          _selectedAddressId = _fallbackAddresses.first['id'] as String?;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _savedAddresses = _fallbackAddresses;
        _selectedAddressId = _fallbackAddresses.first['id'] as String?;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLiveDeviceLocation() async {
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

      // 1. Force raw hardware GPS sensor fix on Android device
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

      // 2. Reverse geocode exact live street address
      String displayAddress = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)} (Live Device GPS)';
      try {
        final geoUri = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}');
        final geoRes = await http.get(geoUri, headers: {'User-Agent': 'OnWayMarket/1.0'}).timeout(const Duration(seconds: 3));
        if (geoRes.statusCode == 200) {
          final geoData = jsonDecode(geoRes.body);
          if (geoData['display_name'] != null) {
            displayAddress = geoData['display_name'];
          }
        }
      } catch (_) {}

      if (mounted) {
        _selectAddress({
          'id': 'current_gps_${DateTime.now().millisecondsSinceEpoch}',
          'title': 'Current Live Location',
          'subtitle': displayAddress,
          'lat': pos.latitude,
          'lng': pos.longitude,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching device GPS: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingGps = false);
    }
  }

  Future<void> _selectAddress(Map<String, dynamic> addr) async {
    final id = addr['id'];
    setState(() => _selectedAddressId = id);

    if (id != null && !id.startsWith('fallback') && !id.startsWith('current')) {
      await _api.updateAddress(id, isDefault: true);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selected "${addr['title']}" as delivery address!',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context, addr);
    }
  }

  IconData _iconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'office':
      case 'work':
        return Icons.work_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                const StandardTopBar(
                  title: 'Select Delivery Address',
                  icon: Icons.map_outlined,
                  showBackButton: true,
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSearchBar(context),
                      const SizedBox(height: 16),
                      _buildCurrentLocationButton(),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saved Addresses',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddressEditPage()),
                              );
                              _loadAddresses();
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.add, size: 18, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Add New',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._savedAddresses.map((addr) {
                        final isSelected = _selectedAddressId == addr['id'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAddressCard(
                            context: context,
                            addressData: addr,
                            isSelected: isSelected,
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                      const MapSection(isLocationSelected: false),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddressEditPage()),
        );
        _loadAddresses();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.transparent, width: 2),
        ),
        child: TextField(
          enabled: false,
          style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Search for a new address...',
            hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.outlineVariant),
            prefixIcon: const Icon(Icons.search, color: AppColors.outline),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLocationButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isFetchingGps ? null : _fetchLiveDeviceLocation,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: _isFetchingGps
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                      )
                    : const Icon(Icons.my_location, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use Current Location',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _isFetchingGps ? 'Detecting GPS position...' : 'Fetch real live GPS / Wi-Fi position',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required BuildContext context,
    required Map<String, dynamic> addressData,
    required bool isSelected,
  }) {
    final String? addressId = addressData['id'];
    final String title = addressData['title'];
    final String subtitle = addressData['subtitle'];
    final String? instructions = addressData['instructions'];
    final double? lat = addressData['lat'];
    final double? lng = addressData['lng'];
    final IconData icon = _iconForTitle(title);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectAddress(addressData),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? Icons.check_circle_rounded : icon,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SELECTED',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (lat != null && lng != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                tooltip: 'Edit Address',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddressEditPage(
                        addressId: addressId,
                        initialTitle: title,
                        initialAddress: subtitle,
                        initialInstructions: instructions,
                        initialLatitude: lat,
                        initialLongitude: lng,
                      ),
                    ),
                  );
                  _loadAddresses();
                },
              ),

              if (addressId != null && !addressId.startsWith('fallback'))
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  tooltip: 'Delete Address',
                  onPressed: () async {
                    await _api.deleteAddress(addressId);
                    _loadAddresses();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }



  static const _fallbackAddresses = [
    {
      'id': 'fallback_home',
      'title': 'Home',
      'subtitle': '123 Culinary Blvd, Apt 4B, Food City',
      'instructions': 'Ring doorbell 4B',
      'isDefault': true,
      'lat': 9.9790,
      'lng': 76.2760,
    },
    {
      'id': 'fallback_office',
      'title': 'Flat',
      'subtitle': 'Technopark Phase 1, Trivandrum',
      'instructions': 'Leave at security gate',
      'isDefault': false,
      'lat': 8.5581,
      'lng': 76.8816,
    },
  ];
}
