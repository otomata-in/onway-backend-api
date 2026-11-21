import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/models/community_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../application/trips_provider.dart';

class TripPlannerScreen extends ConsumerStatefulWidget {
  /// Opens the planner with a community already selected, so a community plan
  /// is created against that community without a second picker step.
  final String? communityId;
  final String? communityName;

  const TripPlannerScreen({super.key, this.communityId, this.communityName});

  @override
  ConsumerState<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends ConsumerState<TripPlannerScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final MapController _mapController = MapController();

  ApiFlag? _origin;
  ApiFlag? _destination;
  final List<_EditableWaypoint> _waypoints = [];
  bool _showDetailsForm = false;
  bool _saving = false;
  String? _communityId;
  String? _communityName;
  List<LatLng> _roadGeometry = const [];
  String? _loadedWaypointsSignature;

  /// Typical road day. Kept explicit so the ETA is a stated assumption rather
  /// than a number pulled out of the air.
  static const double _kmPerDay = 150;

  @override
  void initState() {
    super.initState();
    _communityId = widget.communityId;
    _communityName = widget.communityName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  List<LatLng> get _routePoints {
    final points = <LatLng>[];
    if (_origin != null) points.add(_origin!.coordinates);
    for (final wp in _waypoints) {
      points.add(wp.location);
    }
    if (_destination != null) points.add(_destination!.coordinates);
    return points;
  }

  /// Road-following geometry once OSRM answers; straight stops until then.
  List<LatLng> get _displayRoutePoints =>
      _roadGeometry.length >= 2 ? _roadGeometry : _routePoints;

  void _loadRoadGeometry() {
    final stops = _routePoints;
    if (stops.length < 2) return;

    final signature = stops
        .map((point) => '${point.latitude},${point.longitude}')
        .join(';');
    if (signature == _loadedWaypointsSignature) return;
    _loadedWaypointsSignature = signature;

    // A new stop list must not briefly draw the previous route.
    _roadGeometry = const [];
    final coords = stops
        .map((point) => [point.latitude, point.longitude])
        .toList();

    TeritoryRepository.instance.fetchDirections(coords).then((result) {
      if (!mounted) return;
      if (result.coordinates.isEmpty || result.fallback) return;
      setState(() {
        _roadGeometry =
            result.coordinates.map((c) => LatLng(c[0], c[1])).toList();
      });
    }).catchError((_) {});
  }

  double get _distanceKm {
    final points = _routePoints;
    if (points.length < 2) return 0;
    const distance = Distance();
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += distance.as(LengthUnit.Kilometer, points[i - 1], points[i]);
    }
    return total;
  }

  int get _estimatedDays => (_distanceKm / _kmPerDay).ceil().clamp(1, 30);

  LatLng get _mapCenter {
    if (_routePoints.isEmpty) return const LatLng(10.15, 77.25);
    final lats = _routePoints.map((p) => p.latitude);
    final lngs = _routePoints.map((p) => p.longitude);
    return LatLng(
      (lats.reduce(min) + lats.reduce(max)) / 2,
      (lngs.reduce(min) + lngs.reduce(max)) / 2,
    );
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? TeritoryColors.expiredRed : null,
      ),
    );
  }

  Future<void> _pickPlace({required bool isOrigin}) async {
    final places = ref.read(plannerPlacesProvider).valueOrNull;
    if (places == null || places.isEmpty) {
      _toast(
        'Flagged places are still loading. Check the API and try again.',
        error: true,
      );
      return;
    }

    final selected = await showModalBottomSheet<ApiFlag>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlacePickerSheet(
        title: isOrigin ? 'Choose origin' : 'Choose destination',
        places: places,
      ),
    );
    if (selected == null || !mounted) return;

    setState(() {
      if (isOrigin) {
        _origin = selected;
      } else {
        _destination = selected;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(_mapCenter, 9);
    });
  }

  Future<void> _pickCommunity() async {
    final communities = ref.read(plannerCommunitiesProvider).valueOrNull;
    if (communities == null) {
      _toast(
        'Communities are still loading. Plan without one for now.',
        error: true,
      );
      return;
    }

    final selection = await showModalBottomSheet<_CommunityChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommunityPickerSheet(communities: communities),
    );
    if (selection == null || !mounted) return;

    setState(() {
      _communityId = selection.id;
      _communityName = selection.name;
    });
  }

  Future<void> _handleSavePlan() async {
    if (_saving) return;

    final origin = _origin;
    final destination = _destination;
    if (origin == null || destination == null) {
      _toast(
        'Pick an origin and a destination from flagged places.',
        error: true,
      );
      return;
    }

    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : '${origin.placeName} to ${destination.placeName}';

    final waypoints = <Map<String, dynamic>>[];
    var index = 0;
    waypoints.add({
      'orderIndex': index++,
      'placeName': origin.placeName,
      'latitude': origin.latitude,
      'longitude': origin.longitude,
      'category': 'origin',
    });
    double previousLat = origin.latitude;
    double previousLng = origin.longitude;
    const distance = Distance();
    for (final waypoint in _waypoints) {
      final stepKm = distance.as(
        LengthUnit.Kilometer,
        LatLng(previousLat, previousLng),
        waypoint.location,
      );
      waypoints.add({
        'orderIndex': index++,
        'placeName': waypoint.name,
        'latitude': waypoint.location.latitude,
        'longitude': waypoint.location.longitude,
        'category': waypoint.category,
        'distanceFromPrevKm': double.parse(stepKm.toStringAsFixed(1)),
      });
      previousLat = waypoint.location.latitude;
      previousLng = waypoint.location.longitude;
    }
    waypoints.add({
      'orderIndex': index++,
      'placeName': destination.placeName,
      'latitude': destination.latitude,
      'longitude': destination.longitude,
      'category': 'destination',
      'distanceFromPrevKm': double.parse(
        distance
            .as(
              LengthUnit.Kilometer,
              LatLng(previousLat, previousLng),
              destination.coordinates,
            )
            .toStringAsFixed(1),
      ),
    });

    setState(() => _saving = true);
    try {
      await TeritoryRepository.instance.createPlan(
        name: name,
        originName: origin.placeName,
        destinationName: destination.placeName,
        description: _descController.text.trim(),
        communityId: _communityId,
        totalDistanceKm: double.parse(_distanceKm.toStringAsFixed(1)),
        estimatedDays: _estimatedDays,
        waypoints: waypoints,
      );
      if (!mounted) return;
      ref.invalidate(tripsHubProvider);
      ref.invalidate(savedPlanIdsProvider);
      _toast('“$name” created');
      context.pop();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Could not save this plan. Check your connection.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addWaypoint(ApiFlag place) {
    setState(() {
      _waypoints.add(
        _EditableWaypoint(
          name: place.placeName,
          location: place.coordinates,
          category: place.category.isEmpty ? 'general' : place.category,
        ),
      );
    });
  }

  void _removeWaypoint(int index) {
    setState(() => _waypoints.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    _loadRoadGeometry();
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
            onPressed: _saving ? null : _handleSavePlan,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                _PlaceField(
                  place: _origin,
                  label: 'Origin',
                  icon: Icons.trip_origin_rounded,
                  iconColor: TeritoryColors.validatedGreen,
                  onTap: () => _pickPlace(isOrigin: true),
                ),
                const SizedBox(height: 8),
                _PlaceField(
                  place: _destination,
                  label: 'Destination',
                  icon: Icons.location_on_rounded,
                  iconColor: TeritoryColors.expiredRed,
                  onTap: () => _pickPlace(isOrigin: false),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    -0.20,
                    -0.15,
                    -0.30,
                    0.0,
                    140,
                    -0.45,
                    0.20,
                    -0.35,
                    0.0,
                    165,
                    -0.55,
                    0.05,
                    -0.05,
                    0.0,
                    185,
                    0.0,
                    0.0,
                    0.0,
                    1.0,
                    0,
                  ]),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _mapCenter,
                      initialZoom: 9,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.onway.teritory',
                      ),
                      if (_displayRoutePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _displayRoutePoints,
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
                              point: _origin!.coordinates,
                              width: 36,
                              height: 36,
                              child: _MapPin(
                                color: TeritoryColors.validatedGreen,
                                icon: Icons.play_arrow_rounded,
                              ),
                            ),
                          if (_destination != null)
                            Marker(
                              point: _destination!.coordinates,
                              width: 36,
                              height: 36,
                              child: _MapPin(
                                color: TeritoryColors.expiredRed,
                                icon: Icons.flag_rounded,
                              ),
                            ),
                          ..._waypoints.asMap().entries.map((entry) {
                            return Marker(
                              point: entry.value.location,
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: TeritoryColors.rallyGold,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
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

                if (_routePoints.length >= 2)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.route_rounded,
                            color: TeritoryColors.tripRoute,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '~${_distanceKm.toStringAsFixed(1)} km',
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
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _handleSavePlan,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
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
        ),
      ),
    );
  }

  Widget _buildWaypointPanel() {
    final placesAsync = ref.watch(plannerPlacesProvider);

    return Column(
      children: [
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: TeritoryColors.tripRoute.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: TeritoryColors.tripRoute.withValues(alpha: 0.3),
                    ),
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
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: TeritoryColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Flagged Places',
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
          child: placesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: TeritoryColors.tripRoute),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load flagged places.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: TeritoryColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(plannerPlacesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (places) {
              final candidates = places.where((place) {
                if (place.id == _origin?.id || place.id == _destination?.id) {
                  return false;
                }
                return !_waypoints.any((w) => w.name == place.placeName);
              }).toList();

              if (candidates.isEmpty) {
                return Center(
                  child: Text(
                    'No other flagged places nearby to add.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: TeritoryColors.textMuted,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  final place = candidates[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: TeritoryColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: TeritoryColors.rallyGold.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.place_rounded,
                          color: TeritoryColors.rallyGold,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        place.placeName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        [
                          place.city,
                          place.category,
                        ].where((part) => part.isNotEmpty).join(' · '),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: TeritoryColors.textMuted,
                        ),
                      ),
                      trailing: GestureDetector(
                        onTap: () => _addWaypoint(place),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: TeritoryColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: TeritoryColors.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
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
                  label: 'Est. distance',
                  value: '~${_distanceKm.toStringAsFixed(0)} km',
                ),
                Container(width: 1, height: 40, color: TeritoryColors.border),
                _EstimateField(
                  icon: Icons.schedule_rounded,
                  label: 'Est. days',
                  value: '~$_estimatedDays',
                ),
                Container(width: 1, height: 40, color: TeritoryColors.border),
                _EstimateField(
                  icon: Icons.flag_rounded,
                  label: 'Stops',
                  value: '$_waypoints.length',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Distance is the straight-line sum between selected stops and days '
            'assume ~${_kmPerDay.toInt()} km of travel per day.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: TeritoryColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Community (Optional)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TeritoryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickCommunity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: TeritoryColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.groups_rounded,
                    color: TeritoryColors.communityIndigo,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _communityName ?? 'Personal plan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TeritoryColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: TeritoryColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────

class _PlaceField extends StatelessWidget {
  final ApiFlag? place;
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _PlaceField({
    required this.place,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: TeritoryColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: TeritoryColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place?.placeName ?? 'Choose from flagged places',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: place == null
                          ? TeritoryColors.textMuted
                          : TeritoryColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.unfold_more_rounded,
              color: TeritoryColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _MapPin({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _PlacePickerSheet extends StatelessWidget {
  final String title;
  final List<ApiFlag> places;

  const _PlacePickerSheet({required this.title, required this.places});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: TeritoryColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: TeritoryColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];
                return ListTile(
                  leading: const Icon(
                    Icons.place_rounded,
                    color: TeritoryColors.tripRoute,
                  ),
                  title: Text(
                    place.placeName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    [
                      place.city,
                      place.category,
                    ].where((part) => part.isNotEmpty).join(' · '),
                    style: GoogleFonts.plusJakartaSans(fontSize: 11),
                  ),
                  onTap: () => Navigator.of(context).pop(place),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityChoice {
  final String? id;
  final String name;

  const _CommunityChoice({this.id, required this.name});
}

class _CommunityPickerSheet extends StatelessWidget {
  final List<Community> communities;

  const _CommunityPickerSheet({required this.communities});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: TeritoryColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Attach to community',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: TeritoryColors.textPrimary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.person_rounded,
              color: TeritoryColors.textSecondary,
            ),
            title: Text(
              'Personal plan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => Navigator.of(
              context,
            ).pop(const _CommunityChoice(name: 'Personal plan')),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                return ListTile(
                  leading: const Icon(
                    Icons.groups_rounded,
                    color: TeritoryColors.communityIndigo,
                  ),
                  title: Text(
                    community.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${community.memberCount} members',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11),
                  ),
                  onTap: () => Navigator.of(context).pop(
                    _CommunityChoice(id: community.id, name: community.name),
                  ),
                );
              },
            ),
          ),
        ],
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
          color: isSelected
              ? TeritoryColors.primary
              : TeritoryColors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : TeritoryColors.textSecondary,
            ),
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

  const _EstimateField({
    required this.icon,
    required this.label,
    required this.value,
  });

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
