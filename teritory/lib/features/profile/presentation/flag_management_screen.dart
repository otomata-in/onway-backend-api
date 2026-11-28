import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/flag_style_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/flag_style_catalog.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../../core/widgets/flag/teritory_flag.dart';
import '../../explore/application/explore_flags_provider.dart';
import '../application/profile_providers.dart';

/// Full-screen Teritory Flag Management map for the signed-in traveler.
///
/// Mirrors the Explore map UI with only the controls needed to audit and manage
/// one's own flags: `All`, `Major`, `Minor`, and `Hidden` filters, left/right
/// iterative traversal arrows at a comfortable zoom (`14.5`), and a tap-to-manage
/// sheet to edit post details, swap photos, hide/show visibility, or delete.
class FlagManagementScreen extends ConsumerStatefulWidget {
  final List<ApiFlag>? initialFlags;

  const FlagManagementScreen({super.key, this.initialFlags});

  static Future<void> open(
    BuildContext context, {
    List<ApiFlag>? initialFlags,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FlagManagementScreen(initialFlags: initialFlags),
      ),
    );
  }

  @override
  ConsumerState<FlagManagementScreen> createState() =>
      _FlagManagementScreenState();
}

class _FlagManagementScreenState extends ConsumerState<FlagManagementScreen> {
  static const double _focusZoom = 14.5;

  late final MapController _mapController;
  List<ApiFlag> _flags = const [];
  bool _loading = true;
  String? _error;
  String _selectedFilter = 'All';
  int _focusedIndex = 0;
  double _currentZoom = _focusZoom;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialFlags != null) {
      _flags = List<ApiFlag>.from(widget.initialFlags!);
      _loading = false;
    }
    _loadFlags();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadFlags() async {
    final userId = ref.read(currentUserProvider).id;
    if (userId.isEmpty) return;
    if (_flags.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final fetched = await TeritoryRepository.instance.fetchUserFlags(
        userId,
        includeHidden: true,
      );
      if (!mounted) return;
      setState(() {
        _flags = fetched;
        _loading = false;
        _error = null;
        if (_focusedIndex >= _filteredFlags.length) {
          _focusedIndex = 0;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_flags.isEmpty) {
          _error = e is ApiException
              ? e.message
              : 'Could not load your flags. Please retry.';
        }
      });
    }
  }

  List<ApiFlag> get _filteredFlags {
    switch (_selectedFilter) {
      case 'Major':
        return _flags.where((f) => f.isMajorFlag).toList();
      case 'Minor':
        return _flags.where((f) => !f.isMajorFlag).toList();
      case 'Hidden':
        return _flags.where((f) => f.isHidden).toList();
      case 'All':
      default:
        return _flags;
    }
  }

  double get _flagZoomScale {
    if (_currentZoom >= 13.0) return 1.0;
    return math.pow(0.78, (13.0 - _currentZoom).clamp(0.0, 8.0))
        .toDouble()
        .clamp(0.22, 1.0);
  }

  void _stepFlag(int delta) {
    final visible = _filteredFlags;
    if (visible.isEmpty) return;
    final next = (_focusedIndex + delta + visible.length) % visible.length;
    setState(() => _focusedIndex = next);
    final target = visible[next];
    try {
      _mapController.move(target.coordinates, _focusZoom);
    } catch (_) {}
  }

  void _selectFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _focusedIndex = 0;
    });
    final visible = _filteredFlags;
    if (visible.isNotEmpty) {
      try {
        _mapController.move(visible.first.coordinates, _focusZoom);
      } catch (_) {}
    }
  }

  void _invalidateGlobalProviders() {
    final uid = ref.read(currentUserProvider).id;
    ref.invalidate(exploreFlagsProvider);
    ref.invalidate(myProfileProvider);
    if (uid.isNotEmpty) {
      ref.invalidate(userFlagsProvider(uid));
    }
  }

  Future<void> _showManageFlagSheet(ApiFlag flag) async {
    final placeCtrl = TextEditingController(text: flag.placeName);
    final notesCtrl = TextEditingController(text: flag.notes);
    String selectedCategory = flag.category;
    bool isHidden = flag.isHidden;
    String photoUrl = flag.photoUrl;
    File? pickedImage;
    bool saving = false;
    bool deleting = false;

    const categories = [
      'General',
      'Heritage',
      'Nature',
      'Food',
      'Adventure',
      'Hidden Gem',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.88,
              ),
              padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        TeritoryFlag(
                          style: flag.flagStyle,
                          width: 42,
                          isMajor: flag.isMajorFlag,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage Flag',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: TeritoryColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${flag.city.isNotEmpty ? "${flag.city}, " : ""}${flag.country}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: TeritoryColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove flag permanently',
                          onPressed: saving || deleting
                              ? null
                              : () async {
                                  final confirmed = await showDialog<bool>(
                                    context: ctx,
                                    builder: (dCtx) => AlertDialog(
                                      title: const Text('Remove Flag?'),
                                      content: Text(
                                        'Permanently delete "${flag.placeName}" from your territory?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(dCtx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                TeritoryColors.expiredRed,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () =>
                                              Navigator.of(dCtx).pop(true),
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;
                                  setSheetState(() => deleting = true);
                                  try {
                                    await TeritoryRepository.instance
                                        .deleteFlag(flag.id);
                                    if (!mounted) return;
                                    setState(() {
                                      _flags = _flags
                                          .where((f) => f.id != flag.id)
                                          .toList();
                                      if (_focusedIndex >=
                                          _filteredFlags.length) {
                                        _focusedIndex = math.max(
                                          0,
                                          _filteredFlags.length - 1,
                                        );
                                      }
                                    });
                                    _invalidateGlobalProviders();
                                    if (ctx.mounted) Navigator.of(ctx).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Removed "${flag.placeName}".',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    setSheetState(() => deleting = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e is ApiException
                                                ? e.message
                                                : 'Could not remove flag.',
                                          ),
                                          backgroundColor:
                                              TeritoryColors.expiredRed,
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: deleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: TeritoryColors.expiredRed,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline_rounded,
                                  color: TeritoryColors.expiredRed,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Visibility Toggle (Hide / Show)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isHidden
                            ? const Color(0xFFF1F5F9)
                            : TeritoryColors.primaryLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isHidden
                              ? TeritoryColors.border
                              : TeritoryColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isHidden
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: isHidden
                                ? TeritoryColors.textSecondary
                                : TeritoryColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHidden
                                      ? 'Flag is Hidden'
                                      : 'Flag is Visible on Explore',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: TeritoryColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  isHidden
                                      ? 'Only you can see it in Flag Management'
                                      : 'Friends and explorers can see this spot',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: TeritoryColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: !isHidden,
                            activeTrackColor: TeritoryColors.primary,
                            onChanged: (show) =>
                                setSheetState(() => isHidden = !show),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Photo picker
                    Text(
                      'Flag Photo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TeritoryColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final xfile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 82,
                          maxWidth: 1400,
                        );
                        if (xfile != null) {
                          setSheetState(() => pickedImage = File(xfile.path));
                        }
                      },
                      child: Container(
                        height: 130,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: TeritoryColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: TeritoryColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: pickedImage != null
                            ? Image.file(pickedImage!, fit: BoxFit.cover)
                            : (photoUrl.isNotEmpty
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: photoUrl,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        right: 8,
                                        bottom: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Text(
                                            'Change photo',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_a_photo_outlined,
                                        color: TeritoryColors.textSecondary,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tap to add or update photo',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: TeritoryColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Place Name
                    TextField(
                      controller: placeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Location / Spot Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category chips
                    Text(
                      'Category',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TeritoryColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cat in categories)
                          ChoiceChip(
                            label: Text(cat),
                            selected: selectedCategory == cat,
                            selectedColor: TeritoryColors.primaryLight,
                            onSelected: (_) =>
                                setSheetState(() => selectedCategory = cat),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Notes / Post Content
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Story / Post Content',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: saving || deleting
                            ? null
                            : () async {
                                final title = placeCtrl.text.trim();
                                if (title.isEmpty) return;
                                setSheetState(() => saving = true);
                                try {
                                  String? nextPhoto = photoUrl;
                                  if (pickedImage != null) {
                                    nextPhoto = await TeritoryRepository
                                        .instance
                                        .uploadImage(pickedImage!.path);
                                  }
                                  final updated = await TeritoryRepository
                                      .instance
                                      .updateFlag(
                                    flag.id,
                                    placeName: title,
                                    category: selectedCategory,
                                    notes: notesCtrl.text.trim(),
                                    photoUrl: nextPhoto,
                                    isHidden: isHidden,
                                  );
                                  if (!mounted) return;
                                  setState(() {
                                    _flags = _flags
                                        .map((f) => f.id == updated.id
                                            ? updated
                                            : f)
                                        .toList();
                                  });
                                  _invalidateGlobalProviders();
                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        updated.isHidden
                                            ? '"${updated.placeName}" is now hidden.'
                                            : 'Updated "${updated.placeName}".',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  setSheetState(() => saving = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e is ApiException
                                              ? e.message
                                              : 'Failed to update flag.',
                                        ),
                                        backgroundColor:
                                            TeritoryColors.expiredRed,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: TeritoryColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          saving ? 'Saving changes…' : 'Save Flag Changes',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    placeCtrl.dispose();
    notesCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(mapThemeProvider);
    final visible = _filteredFlags;
    final safeIdx =
        visible.isEmpty ? 0 : _focusedIndex.clamp(0, visible.length - 1);
    final focusedFlag = visible.isEmpty ? null : visible[safeIdx];
    final initialCenter =
        focusedFlag?.coordinates ?? const LatLng(8.5241, 76.9366);

    final markers = <Marker>[
      for (var i = 0; i < visible.length; i++)
        _buildFlagMarker(
          visible[i],
          isFocused: i == safeIdx,
          isDark: isDark,
          onTap: () {
            setState(() => _focusedIndex = i);
            _showManageFlagSheet(visible[i]);
          },
        ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: _focusZoom,
              minZoom: 2.0,
              maxZoom: 18.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (camera, _) {
                if ((camera.zoom - _currentZoom).abs() >= 0.04) {
                  setState(() => _currentZoom = camera.zoom);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.onway.teritory',
                tileBuilder: isDark
                    ? (context, tileWidget, tile) => ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            -0.20, -0.15, -0.30, 0.0, 140,
                            -0.45, 0.20, -0.35, 0.0, 165,
                            -0.55, 0.05, -0.05, 0.0, 185,
                            0.0, 0.0, 0.0, 1.0, 0,
                          ]),
                          child: tileWidget,
                        )
                    : null,
              ),
              FlagMotionHost(
                child: MarkerLayer(markers: markers, rotate: true),
              ),
            ],
          ),

          // Top bar + filter chips
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xF21E293B)
                          : Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      border: isDark
                          ? Border.all(color: const Color(0xFF334155))
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 34,
                            height: 34,
                          ),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: isDark
                                ? Colors.white
                                : TeritoryColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage My Flags',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : TeritoryColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${visible.length} shown · ${_flags.where((f) => f.isHidden).length} hidden',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : TeritoryColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: isDark
                              ? 'Switch to Daylight Map'
                              : 'Switch to Oceanic Map',
                          onPressed: () => ref
                              .read(mapThemeProvider.notifier)
                              .setDark(!isDark),
                          icon: Icon(
                            isDark
                                ? Icons.wb_sunny_rounded
                                : Icons.dark_mode_rounded,
                            size: 20,
                            color: isDark
                                ? TeritoryColors.majorGold
                                : TeritoryColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'All',
                          Icons.travel_explore_rounded,
                          isDark,
                        ),
                        _buildFilterChip(
                          'Major',
                          Icons.military_tech_rounded,
                          isDark,
                        ),
                        _buildFilterChip(
                          'Minor',
                          Icons.flag_outlined,
                          isDark,
                        ),
                        _buildFilterChip(
                          'Hidden',
                          Icons.visibility_off_rounded,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: TeritoryColors.primary),
            )
          else if (_error != null)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: TeritoryColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _loadFlags,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (visible.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  'No $_selectedFilter flags found',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
              ),
            ),

          // Bottom Iterative Traversal Deck (<  Focused Flag  >)
          if (focusedFlag != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: MediaQuery.of(context).padding.bottom + 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xF51E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: focusedFlag.isHidden
                        ? TeritoryColors.textMuted
                        : (focusedFlag.isMajorFlag
                            ? TeritoryColors.majorGold
                            : TeritoryColors.primary.withValues(alpha: 0.45)),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('flag_mgmt_prev'),
                      tooltip: 'Previous flag',
                      onPressed: visible.length > 1 ? () => _stepFlag(-1) : null,
                      icon: const Icon(Icons.chevron_left_rounded, size: 30),
                      color: isDark ? Colors.white : TeritoryColors.textPrimary,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showManageFlagSheet(focusedFlag),
                        child: Row(
                          children: [
                            TeritoryFlag(
                              style: focusedFlag.effectiveStyle(
                                ref.watch(currentUserProvider).id,
                                ref.watch(flagStyleProvider),
                              ),
                              width: 36,
                              isMajor: focusedFlag.isMajorFlag,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          focusedFlag.placeName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white
                                                : TeritoryColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${safeIdx + 1}/${visible.length}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: TeritoryColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: focusedFlag.isHidden
                                              ? const Color(0xFFE2E8F0)
                                              : (focusedFlag.isMajorFlag
                                                  ? TeritoryColors.majorGoldLight
                                                  : TeritoryColors.primaryLight),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          focusedFlag.isHidden
                                              ? 'HIDDEN'
                                              : (focusedFlag.isMajorFlag
                                                  ? 'MAJOR'
                                                  : 'MINOR'),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: focusedFlag.isHidden
                                                ? const Color(0xFF475569)
                                                : (focusedFlag.isMajorFlag
                                                    ? TeritoryColors
                                                        .majorGoldDark
                                                    : TeritoryColors.primary),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Tap to edit, hide or delete',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : TeritoryColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('flag_mgmt_next'),
                      tooltip: 'Next flag',
                      onPressed: visible.length > 1 ? () => _stepFlag(1) : null,
                      icon: const Icon(Icons.chevron_right_rounded, size: 30),
                      color: isDark ? Colors.white : TeritoryColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, bool isDark) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _selectFilter(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? TeritoryColors.primary
              : (isDark ? const Color(0xF21E293B) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? TeritoryColors.primary
                : (isDark ? const Color(0xFF334155) : TeritoryColors.border),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : TeritoryColors.textSecondary),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : TeritoryColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _buildFlagMarker(
    ApiFlag flag, {
    required bool isFocused,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isMajor = flag.isMajorFlag;
    final myId = ref.watch(currentUserProvider).id;
    final myStyle = ref.watch(flagStyleProvider);
    final effectiveStyle = flag.effectiveStyle(myId, myStyle);
    final double flagWidth = isMajor ? 34 : 28;
    final double flagHeight = isMajor ? 42 : 35;
    final double baseWidth = isMajor ? 26 : 20;
    final double poleCenterOffset = flagWidth * (1 - 0.15);
    final themeColor = isMajor
        ? TeritoryColors.majorGold
        : FlagStyleCatalog.primaryColor(effectiveStyle);

    return Marker(
      point: flag.coordinates,
      width: 152,
      height: isMajor ? 92 : 82,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: flag.isHidden ? 0.58 : 1.0,
          child: Transform.scale(
            scale: _flagZoomScale * (isFocused ? 1.12 : 1.0),
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: isFocused
                        ? TeritoryColors.primary
                        : (isDark ? const Color(0xF51E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isFocused
                          ? Colors.white
                          : (flag.isHidden
                              ? TeritoryColors.textMuted
                              : themeColor),
                      width: isFocused ? 1.8 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isFocused
                                ? TeritoryColors.primary
                                : Colors.black)
                            .withValues(alpha: isFocused ? 0.45 : 0.18),
                        blurRadius: isFocused ? 10 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (flag.isHidden) ...[
                        Icon(
                          Icons.visibility_off_rounded,
                          size: 11,
                          color: isFocused
                              ? Colors.white
                              : TeritoryColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          flag.placeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: isFocused
                                ? Colors.white
                                : (isDark
                                    ? Colors.white
                                    : TeritoryColors.textPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: flagHeight + (isMajor ? 9 : 6),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      FlagTerrainBase(
                        accentColor: themeColor,
                        isMajor: isMajor,
                        width: baseWidth,
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: poleCenterOffset,
                          bottom: isMajor ? 7.5 : 5,
                        ),
                        child: FlagPinFlag(
                          style: effectiveStyle,
                          width: flagWidth,
                          height: flagHeight,
                          showPole: true,
                          isMajor: isMajor,
                        ),
                      ),
                    ],
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
