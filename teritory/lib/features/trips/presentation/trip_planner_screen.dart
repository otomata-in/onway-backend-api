import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/teritory_theme.dart';

class TripPlannerScreen extends ConsumerStatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  ConsumerState<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends ConsumerState<TripPlannerScreen> {
  final _originController = TextEditingController();
  final _destController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng? _origin;
  LatLng? _destination;
  final List<_EditableWaypoint> _waypoints = [];
  bool _showDetailsForm = false;

  // Waypoint suggestions (simulated)
  static final List<_WaypointSuggestion> _suggestions = [
    _WaypointSuggestion('Lockhart Gap', LatLng(10.0712, 77.0523), 'viewpoint', 8),
    _WaypointSuggestion('Top Station', LatLng(10.1262, 77.2354), 'viewpoint', 12),
    _WaypointSuggestion('Chinnar Wildlife Sanctuary', LatLng(10.3000, 77.1833), 'wildlife', 5),
    _WaypointSuggestion('Marayoor Sandalwood Forest', LatLng(10.2762, 77.1625), 'forest', 3),
    _WaypointSuggestion('Berijam Lake', LatLng(10.2167, 77.4333), 'lake', 6),
    _WaypointSuggestion('Edakkal Caves', LatLng(11.6308, 76.0297), 'heritage', 10),
    _WaypointSuggestion('Meenmutty Falls', LatLng(11.6833, 76.0167), 'waterfall', 7),
    _WaypointSuggestion('Varkala Cliff', LatLng(8.7379, 76.7163), 'cliff', 11),
  ];

  @override
  void initState() {
    super.initState();
    // Default origin/destination for demo
    _origin = LatLng(10.0889, 77.0595);
    _destination = LatLng(10.2381, 77.4892);
    _originController.text = 'Munnar Town';
    _destController.text = 'Kodaikanal';
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  List<LatLng> get _routePoints {
    final points = <LatLng>[];
    if (_origin != null) points.add(_origin!);
    for (final wp in _waypoints) {
      points.add(wp.location);
    }
    if (_destination != null) points.add(_destination!);
    return points;
  }

  LatLng get _mapCenter {
    if (_routePoints.isEmpty) return LatLng(10.15, 77.25);
    final lats = _routePoints.map((p) => p.latitude);
    final lngs = _routePoints.map((p) => p.longitude);
    return LatLng(
      (lats.reduce(min) + lats.reduce(max)) / 2,
      (lngs.reduce(min) + lngs.reduce(max)) / 2,
    );
  }

  void _addWaypoint(_WaypointSuggestion suggestion) {
    setState(() {
      _waypoints.add(_EditableWaypoint(
        name: suggestion.name,
        location: suggestion.location,
        category: suggestion.category,
      ));
    });
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeritoryColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Trip Planner',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: TeritoryColors.textPrimary,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Trip plan saved!',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: TeritoryColors.validatedGreen,
                ),
              );
            },
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Origin & Destination inputs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                _LocationInput(
                  controller: _originController,
                  label: 'Origin',
                  icon: Icons.trip_origin_rounded,
                  iconColor: TeritoryColors.validatedGreen,
                ),
                const SizedBox(height: 8),
                _LocationInput(
                  controller: _destController,
                  label: 'Destination',
                  icon: Icons.location_on_rounded,
                  iconColor: TeritoryColors.expiredRed,
                ),
              ],
            ),
          ),

          // Map with oceanic theme
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    -0.20, -0.15, -0.30, 0.0, 140,
                    -0.45, 0.20, -0.35, 0.0, 165,
                    -0.55, 0.05, -0.05, 0.0, 185,
                    0.0, 0.0, 0.0, 1.0, 0,
                  ]),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _mapCenter,
                      initialZoom: 9,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      if (_routePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 4,
                              color: TeritoryColors.tripRoute,
                              pattern: const StrokePattern.solid(),
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (_origin != null)
                            Marker(
                              point: _origin!,
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: TeritoryColors.validatedGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: TeritoryColors.validatedGreen.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          if (_destination != null)
                            Marker(
                              point: _destination!,
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: TeritoryColors.expiredRed,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: TeritoryColors.expiredRed.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ..._waypoints.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final wp = entry.value;
                            return Marker(
                              point: wp.location,
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: TeritoryColors.rallyGold,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    '${idx + 1}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                // Corridor indicator overlay
                if (_origin != null && _destination != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.route_rounded, color: TeritoryColors.tripRoute, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Route Corridor',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Waypoint suggestions panel
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TeritoryColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Toggle between suggestions and form
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _ToggleChip(
                          label: 'Waypoints',
                          icon: Icons.add_location_alt_rounded,
                          isSelected: !_showDetailsForm,
                          onTap: () => setState(() => _showDetailsForm = false),
                        ),
                        const SizedBox(width: 8),
                        _ToggleChip(
                          label: 'Trip Details',
                          icon: Icons.edit_note_rounded,
                          isSelected: _showDetailsForm,
                          onTap: () => setState(() => _showDetailsForm = true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: _showDetailsForm
                        ? _buildDetailsForm()
                        : _buildWaypointPanel(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text(
                    'Share',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TeritoryColors.sapphireBlue,
                    side: const BorderSide(color: TeritoryColors.sapphireBlue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Trip plan saved!',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: TeritoryColors.validatedGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    'Save Plan',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeritoryColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaypointPanel() {
    return Column(
      children: [
        // Current waypoints (reorderable)
        if (_waypoints.isNotEmpty) ...[
          SizedBox(
            height: 52,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _waypoints.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _waypoints.removeAt(oldIndex);
                  _waypoints.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final wp = _waypoints[index];
                return Container(
                  key: ValueKey('wp_${wp.name}_$index'),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: TeritoryColors.tripRoute.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TeritoryColors.tripRoute.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: TeritoryColors.rallyGold,
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        wp.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeWaypoint(index),
                        child: const Icon(Icons.close_rounded, size: 16, color: TeritoryColors.textMuted),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Suggestions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Suggested Waypoints',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TeritoryColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final s = _suggestions[index];
              final isAdded = _waypoints.any((w) => w.name == s.name);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isAdded
                      ? TeritoryColors.tripRoute.withValues(alpha: 0.06)
                      : TeritoryColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: isAdded
                      ? Border.all(color: TeritoryColors.tripRoute.withValues(alpha: 0.3))
                      : null,
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: TeritoryColors.rallyGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.place_rounded, color: TeritoryColors.rallyGold, size: 20),
                  ),
                  title: Text(
                    s.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TeritoryColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${s.category} · ${s.flagCount} flags nearby',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: TeritoryColors.textMuted,
                    ),
                  ),
                  trailing: isAdded
                      ? const Icon(Icons.check_circle_rounded, color: TeritoryColors.tripRoute, size: 22)
                      : GestureDetector(
                          onTap: () => _addWaypoint(s),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: TeritoryColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_rounded, color: TeritoryColors.primary, size: 18),
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Name',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TeritoryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'e.g. Western Ghats Ridge Run',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: TeritoryColors.textMuted,
              ),
              filled: true,
              fillColor: TeritoryColors.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Description',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TeritoryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            maxLines: 3,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Describe the trek, terrain, and highlights...',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: TeritoryColors.textMuted,
              ),
              filled: true,
              fillColor: TeritoryColors.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),

          // Estimated stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TeritoryColors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _EstimateField(
                  icon: Icons.straighten_rounded,
                  label: 'Distance',
                  value: '~145 km',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: TeritoryColors.border,
                ),
                _EstimateField(
                  icon: Icons.schedule_rounded,
                  label: 'Duration',
                  value: '~72 hrs',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: TeritoryColors.border,
                ),
                _EstimateField(
                  icon: Icons.flag_rounded,
                  label: 'Waypoints',
                  value: '${_waypoints.length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Community selector
          Text(
            'Community (Optional)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TeritoryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: TeritoryColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.groups_rounded, color: TeritoryColors.communityIndigo, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Munnar Trail Blazers',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: TeritoryColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────

class _LocationInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _LocationInput({
    required this.controller,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        hintText: label,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: TeritoryColors.textMuted,
        ),
        filled: true,
        fillColor: TeritoryColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? TeritoryColors.primary : TeritoryColors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : TeritoryColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : TeritoryColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _EstimateField({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: TeritoryColors.tripRoute),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: TeritoryColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: TeritoryColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableWaypoint {
  final String name;
  final LatLng location;
  final String category;

  _EditableWaypoint({
    required this.name,
    required this.location,
    required this.category,
  });
}

class _WaypointSuggestion {
  final String name;
  final LatLng location;
  final String category;
  final int flagCount;

  const _WaypointSuggestion(this.name, this.location, this.category, this.flagCount);
}
