import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/rally_models.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/teritory_repository.dart';
import '../../../core/theme/teritory_theme.dart';
import '../../shared/presentation/invite_friends_sheet.dart';
import '../application/rally_providers.dart';

/// Live Legendary Rallies.
///
/// Nearby rallies come from `GET /rallies/nearby`, creating one posts to
/// `POST /rallies`, and join / arrive / complete hit their own endpoints. The
/// roster and the ≥500 m arrival rule are the server's, not local guesses.
///
/// Arrival is checked against the map centre this sheet was opened from, because
/// the app has no device-location plugin yet; the sheet says so rather than
/// pretending it read the phone's GPS.
class LegendaryRallySheet extends ConsumerStatefulWidget {
  const LegendaryRallySheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.placeName,
  });

  final double latitude;
  final double longitude;
  final String placeName;

  static Future<void> show(
    BuildContext context, {
    required double latitude,
    required double longitude,
    required String placeName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LegendaryRallySheet(
        latitude: latitude,
        longitude: longitude,
        placeName: placeName,
      ),
    );
  }

  @override
  ConsumerState<LegendaryRallySheet> createState() =>
      _LegendaryRallySheetState();
}

class _LegendaryRallySheetState extends ConsumerState<LegendaryRallySheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int _tab = 0;
  int _windowHours = 2;
  int _minParticipants = 2;
  bool _creating = false;
  String? _busyRallyId;

  RallyLocation get _location => (lat: widget.latitude, lng: widget.longitude);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _runRallyAction(
    LegendaryRally rally,
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_busyRallyId != null) return;
    setState(() => _busyRallyId = rally.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      _invalidateRally(rally.id);
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busyRallyId = null);
    }
  }

  void _invalidateRally(String rallyId) {
    ref.invalidate(nearbyRalliesProvider(_location));
    ref.invalidate(
      rallyDetailProvider((
        rallyId: rallyId,
        lat: widget.latitude,
        lng: widget.longitude,
      )),
    );
  }

  Future<void> _arrive(LegendaryRally rally) async {
    if (_busyRallyId != null) return;
    setState(() => _busyRallyId = rally.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final loc = ref.read(mapLocationProvider).valueOrNull?.coordinates;
      final lat = loc?.latitude ?? widget.latitude;
      final lng = loc?.longitude ?? widget.longitude;

      final result = await TeritoryRepository.instance.markRallyArrival(
        rally.id,
        latitude: lat,
        longitude: lng,
      );
      _invalidateRally(rally.id);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: result.arrived
              ? TeritoryColors.validatedGreen
              : TeritoryColors.expiredRed,
          content: Text(
            result.message.isNotEmpty
                ? result.message
                : result.arrived
                ? 'Arrival verified!'
                : 'You are still ${result.distanceM} m away.',
          ),
        ),
      );
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busyRallyId = null);
    }
  }

  Future<void> _create() async {
    if (_creating) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a rally name')),
      );
      return;
    }

    setState(() => _creating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final rally = await TeritoryRepository.instance.createRally(
        name: name,
        description: _descriptionController.text.trim(),
        placeName: widget.placeName,
        latitude: widget.latitude,
        longitude: widget.longitude,
        minParticipants: _minParticipants,
        expiresHours: _windowHours,
      );
      ref.invalidate(nearbyRalliesProvider(_location));
      if (!mounted) return;
      setState(() {
        _creating = false;
        _tab = 0;
        _nameController.clear();
        _descriptionController.clear();
      });
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: TeritoryColors.surfaceDark,
          content: Text(
            '🏴 ${rally.name} is gathering at ${rally.locationName}',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _creating = false);
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentUser = ref.watch(currentUserProvider);
    final ralliesAsync = ref.watch(nearbyRalliesProvider(_location));

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag_circle_rounded,
                    color: TeritoryColors.rallyGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Legendary Rallies',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: TeritoryColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Gathering around ${widget.placeName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: TeritoryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _tabButton('Nearby', 0, Icons.local_fire_department_rounded),
                const SizedBox(width: 8),
                _tabButton('Start a Rally', 1, Icons.flag_outlined),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _tab == 0
                ? _buildNearby(ralliesAsync, currentUser.id)
                : _buildCreateForm(),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index, IconData icon) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? TeritoryColors.rallyGold.withValues(alpha: 0.14)
                : TeritoryColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? TeritoryColors.rallyGold
                  : TeritoryColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? TeritoryColors.rallyGold
                    : TeritoryColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? TeritoryColors.rallyGold
                      : TeritoryColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearby(
    AsyncValue<List<LegendaryRally>> ralliesAsync,
    String userId,
  ) {
    return ralliesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: TeritoryColors.primary),
      ),
      error: (error, _) => _RallyMessage(
        icon: Icons.cloud_off_rounded,
        message: error is ApiException
            ? error.message
            : 'Could not load nearby rallies.',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(nearbyRalliesProvider(_location)),
      ),
      data: (rallies) {
        if (rallies.isEmpty) {
          return _RallyMessage(
            icon: Icons.local_fire_department_outlined,
            message: 'No rallies gathering nearby.',
            subtitle: 'Start one and invite travelers to meet you here.',
            actionLabel: 'Start a Rally',
            onAction: () => setState(() => _tab = 1),
          );
        }
        return RefreshIndicator(
          color: TeritoryColors.primary,
          onRefresh: () async {
            ref.invalidate(nearbyRalliesProvider(_location));
            try {
              await ref.read(nearbyRalliesProvider(_location).future);
            } on ApiException {
              // The error state renders the message.
            }
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: rallies.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final rally = rallies[index];
              return _RallyCard(
                rally: rally,
                currentUserId: userId,
                busy: _busyRallyId == rally.id,
                onOpen: () => _RallyDetailSheet.show(
                  context,
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                  rallyId: rally.id,
                ),
                onJoin: () => _runRallyAction(
                  rally,
                  () => TeritoryRepository.instance.joinRally(rally.id),
                  'Joined ${rally.name}',
                ),
                onArrive: () => _arrive(rally),
                onComplete: () => _runRallyAction(
                  rally,
                  () => TeritoryRepository.instance.completeRally(rally.id),
                  'Rally completed — collective flag dropped',
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCreateForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(
          'Rally Name',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: TeritoryColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'e.g. Munnar Sunrise Rally',
            filled: true,
            fillColor: TeritoryColors.surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(
              Icons.edit_rounded,
              color: TeritoryColors.rallyGold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Notes (optional)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: TeritoryColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _descriptionController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Meeting point, gear, sunrise timing…',
            filled: true,
            fillColor: TeritoryColors.surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Gathering window',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: TeritoryColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [1, 2, 4, 8].map((hours) {
            final isSelected = _windowHours == hours;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: hours == 8 ? 0 : 8),
                child: ChoiceChip(
                  label: Text('${hours}h'),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFEF3C7),
                  backgroundColor: TeritoryColors.surfaceContainer,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? TeritoryColors.rallyGold
                        : TeritoryColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? TeritoryColors.rallyGold
                        : TeritoryColors.border,
                  ),
                  showCheckmark: false,
                  onSelected: (selected) {
                    if (selected) setState(() => _windowHours = hours);
                  },
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Text(
          'Verified arrivals needed to complete',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: TeritoryColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [2, 3, 5].map((count) {
            final isSelected = _minParticipants == count;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: count == 5 ? 0 : 8),
                child: ChoiceChip(
                  label: Text('$count travelers'),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFEF3C7),
                  backgroundColor: TeritoryColors.surfaceContainer,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? TeritoryColors.rallyGold
                        : TeritoryColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? TeritoryColors.rallyGold
                        : TeritoryColors.border,
                  ),
                  showCheckmark: false,
                  onSelected: (selected) {
                    if (selected) setState(() => _minParticipants = count);
                  },
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TeritoryColors.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 18,
                color: TeritoryColors.rallyGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The rally starts at ${widget.placeName} — the map centre you '
                  'opened this sheet from.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    height: 1.35,
                    color: TeritoryColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _creating ? null : _create,
            icon: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.flag_rounded, color: Colors.white),
            label: Text(
              _creating ? 'Starting rally…' : 'Start Rally',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeritoryColors.rallyGold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Rallies are open to nearby travelers. Arrival is verified by the '
          'server within 500 m of this point.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: TeritoryColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _RallyCard extends StatelessWidget {
  const _RallyCard({
    required this.rally,
    required this.currentUserId,
    required this.busy,
    required this.onOpen,
    required this.onJoin,
    required this.onArrive,
    required this.onComplete,
  });

  final LegendaryRally rally;
  final String currentUserId;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onJoin;
  final VoidCallback onArrive;
  final VoidCallback onComplete;

  String get _statusLabel {
    switch (rally.status) {
      case RallyStatus.active:
        return 'ACTIVE';
      case RallyStatus.completed:
        return 'COMPLETED';
      case RallyStatus.expired:
        return 'EXPIRED';
      case RallyStatus.pending:
        return 'GATHERING';
    }
  }

  Color get _statusColor {
    switch (rally.status) {
      case RallyStatus.active:
        return TeritoryColors.validatedGreen;
      case RallyStatus.completed:
        return TeritoryColors.sapphireBlue;
      case RallyStatus.expired:
        return TeritoryColors.expiredRed;
      case RallyStatus.pending:
        return TeritoryColors.rallyGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final joined = rally.isParticipant(currentUserId);
    final isOrganizer = rally.organizerId == currentUserId;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TeritoryColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rally.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: TeritoryColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${rally.locationName} • host ${rally.organizerName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: TeritoryColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    size: 13,
                    color: TeritoryColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${rally.participantCount} joined • ${rally.arrivedCount} arrived',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: TeritoryColors.textMuted,
                    ),
                  ),
                  if (rally.distanceKm != null) ...[
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.near_me_rounded,
                      size: 12,
                      color: TeritoryColors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${rally.distanceKm!.toStringAsFixed(1)} km',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: TeritoryColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              if (busy)
                const SizedBox(
                  height: 30,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    if (!joined && rally.status == RallyStatus.pending)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onJoin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TeritoryColors.rallyGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Join Rally',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (joined && rally.status != RallyStatus.completed)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onArrive,
                          icon: const Icon(Icons.pin_drop_rounded, size: 15),
                          label: Text(
                            'Register arrival',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TeritoryColors.textPrimary,
                            side: const BorderSide(
                              color: TeritoryColors.rallyGold,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (isOrganizer &&
                        joined &&
                        rally.status != RallyStatus.completed) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TeritoryColors.surfaceDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Complete',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (!joined && rally.status == RallyStatus.completed)
                      Expanded(
                        child: Text(
                          'This rally has finished.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: TeritoryColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Roster + arrival state for one rally, straight from `GET /rallies/:id`.
class _RallyDetailSheet extends ConsumerWidget {
  const _RallyDetailSheet({
    required this.latitude,
    required this.longitude,
    required this.rallyId,
  });

  final double latitude;
  final double longitude;
  final String rallyId;

  static void show(
    BuildContext context, {
    required double latitude,
    required double longitude,
    required String rallyId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RallyDetailSheet(
        latitude: latitude,
        longitude: longitude,
        rallyId: rallyId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(
      rallyDetailProvider((rallyId: rallyId, lat: latitude, lng: longitude)),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: detailAsync.when(
        loading: () => const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => _RallyMessage(
          icon: Icons.cloud_off_rounded,
          message: error is ApiException
              ? error.message
              : 'Could not load the rally roster.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(
            rallyDetailProvider((
              rallyId: rallyId,
              lat: latitude,
              lng: longitude,
            )),
          ),
        ),
        data: (detail) {
          final rally = detail.rally;
          final currentUserId = ref.watch(currentUserProvider).id;
          final canInvite = rally.isParticipant(currentUserId);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                rally.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: TeritoryColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hosted by ${rally.organizerName} • ${rally.locationName}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: TeritoryColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TeritoryColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${detail.roster.length} joined • ${detail.arrivedCount} verified '
                  'arrivals • ${rally.minParticipants} needed to complete.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TeritoryColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Roster',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: TeritoryColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (detail.roster.isEmpty)
                Text(
                  'No travelers have joined yet.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: TeritoryColors.textMuted,
                  ),
                )
              else
                for (final entry in detail.roster)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: TeritoryColors.surfaceContainer,
                          backgroundImage: entry.avatarUrl.isNotEmpty
                              ? NetworkImage(entry.avatarUrl)
                              : null,
                          child: entry.avatarUrl.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: TeritoryColors.textMuted,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.displayName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TeritoryColors.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          entry.hasArrived
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                          size: 16,
                          color: entry.hasArrived
                              ? TeritoryColors.validatedGreen
                              : TeritoryColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.hasArrived ? 'Arrived' : 'Joining',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: entry.hasArrived
                                ? TeritoryColors.validatedGreen
                                : TeritoryColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
              if (canInvite) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final invited = await InviteFriendsSheet.show(
                        context,
                        targetType: InviteTargetType.rally,
                        targetId: rally.id,
                        targetName: rally.name,
                        excludeUserIds: detail.roster
                            .map((entry) => entry.userId)
                            .toSet(),
                      );
                      if (!context.mounted || invited == null) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            invited == 1
                                ? 'Invitation sent'
                                : '$invited invitations sent',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text(
                      'Invite friends to this rally',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TeritoryColors.textPrimary,
                      side: const BorderSide(color: TeritoryColors.rallyGold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Arrival check-ins use the map centre you opened this sheet from '
                '(±500 m); the app has no device-location plugin yet.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  height: 1.35,
                  color: TeritoryColors.textMuted,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RallyMessage extends StatelessWidget {
  const _RallyMessage({
    required this.icon,
    required this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: TeritoryColors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TeritoryColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: TeritoryColors.textMuted,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: TeritoryColors.primary,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
