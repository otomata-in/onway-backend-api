import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/pending_flag.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/pending_flag_store.dart';
import '../../../core/services/teritory_repository.dart';
import '../../explore/application/explore_flags_provider.dart';

/// The network write one queued flag needs. A seam so the queue's behaviour —
/// retrying, 409-as-success, ordering — can be tested without an API.
typedef FlagDropRequest = Future<void> Function(PendingFlag flag);

final flagDropRequestProvider = Provider<FlagDropRequest>((ref) {
  return (flag) => TeritoryRepository.instance.dropFlag(
    placeName: flag.placeName,
    latitude: flag.latitude,
    longitude: flag.longitude,
    city: flag.city,
    country: flag.country,
    countryCode: flag.countryCode,
    continent: flag.continent,
    isMajorFlag: flag.isMajorFlag,
    category: flag.category,
    notes: flag.notes,
    photoUrl: flag.photoUrl,
  );
});

class FlagQueueSyncReport {
  final int attempted;
  final int synced;
  final int pending;
  final bool skipped;

  const FlagQueueSyncReport({
    required this.attempted,
    required this.synced,
    required this.pending,
    this.skipped = false,
  });
}

/// Flags staked locally and not yet accepted by the server, oldest first.
///
/// Entries are scoped to the traveler who staked them: signing out never hands
/// someone else's queued spots to whoever signs in next.
class FlagQueueNotifier extends Notifier<List<PendingFlag>> {
  static final Uuid _uuid = const Uuid();

  bool _syncing = false;

  @override
  List<PendingFlag> build() => PendingFlagStore.instance.items;

  List<PendingFlag> forUser(String? userId) {
    if (userId == null || userId.isEmpty) return const [];
    return state.where((flag) => flag.userId == userId).toList();
  }

  Future<PendingFlag> enqueue({
    required String userId,
    required String placeName,
    required double latitude,
    required double longitude,
    String city = '',
    String country = 'India',
    String countryCode = 'IN',
    String continent = 'Asia',
    bool isMajorFlag = false,
    String category = 'General',
    String notes = '',
    String? photoUrl,
  }) async {
    final flag = PendingFlag(
      localId: _uuid.v4(),
      userId: userId,
      placeName: placeName,
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
      countryCode: countryCode,
      continent: continent,
      isMajorFlag: isMajorFlag,
      category: category,
      notes: notes,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );
    await _save([...state, flag]);
    return flag;
  }

  Future<void> discard(String localId) async {
    await _save(state.where((flag) => flag.localId != localId).toList());
  }

  /// Replays the queue for the signed-in traveler, oldest first.
  ///
  /// Stops at the first entry that still cannot be delivered so the order the
  /// traveler staked the spots in is preserved, and so a dead connection is not
  /// hammered once per queued flag.
  Future<FlagQueueSyncReport> sync() async {
    final userId = ref.read(currentUserProvider).id;
    final skipped = FlagQueueSyncReport(
      attempted: 0,
      synced: 0,
      pending: state.length,
      skipped: true,
    );
    if (_syncing || userId.isEmpty) return skipped;

    final queue = forUser(userId);
    if (queue.isEmpty) {
      return FlagQueueSyncReport(
        attempted: 0,
        synced: 0,
        pending: state.length,
        // Whatever is on the device belongs to another account.
        skipped: state.isNotEmpty,
      );
    }

    final drop = ref.read(flagDropRequestProvider);
    _syncing = true;
    var attempted = 0;
    var synced = 0;

    try {
      for (final flag in queue) {
        attempted++;
        try {
          await drop(flag);
          synced++;
          await _remove(flag.localId);
        } on ApiException catch (e) {
          if (e.statusCode == 409) {
            // The lost attempt did reach the server: this spot is already
            // staked, which is exactly the outcome the traveler wanted.
            synced++;
            await _remove(flag.localId);
            continue;
          }
          await _markFailed(flag, e.message);
          break;
        } catch (_) {
          await _markFailed(flag, 'Still offline — will retry');
          break;
        }
      }
    } finally {
      _syncing = false;
    }

    return FlagQueueSyncReport(
      attempted: attempted,
      synced: synced,
      pending: state.length,
    );
  }

  Future<void> _remove(String localId) async {
    await _save(state.where((flag) => flag.localId != localId).toList());
  }

  Future<void> _markFailed(PendingFlag flag, String message) async {
    await _save([
      for (final item in state)
        if (item.localId == flag.localId)
          item.copyWith(lastError: message, attempts: item.attempts + 1)
        else
          item,
    ]);
  }

  Future<void> _save(List<PendingFlag> next) async {
    state = next;
    await PendingFlagStore.instance.save(next);
  }
}

final flagQueueProvider =
    NotifierProvider<FlagQueueNotifier, List<PendingFlag>>(
      FlagQueueNotifier.new,
    );

/// Drains the queue when connectivity returns and when the app is resumed.
///
/// Wraps the router rather than living in a screen: flags staked in a dead zone
/// must sync even if the traveler is on the profile page when signal comes back.
class FlagQueueSyncScope extends ConsumerStatefulWidget {
  final Widget child;

  const FlagQueueSyncScope({super.key, required this.child});

  @override
  ConsumerState<FlagQueueSyncScope> createState() => _FlagQueueSyncScopeState();
}

class _FlagQueueSyncScopeState extends ConsumerState<FlagQueueSyncScope>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  ProviderSubscription<AuthStatus>? _authSub;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForConnectivity();
    // A queue left over from a previous session drains as soon as the app opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    // That first attempt usually runs while the session is still restoring (the
    // user id is not known yet), so try again the moment it resolves.
    _authSub = ref.listenManual<AuthStatus>(authStatusProvider, (
      previous,
      next,
    ) {
      if (next == AuthStatus.signedIn) _sync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivity?.cancel();
    _authSub?.close();
    super.dispose();
  }

  void _listenForConnectivity() {
    try {
      _connectivity = Connectivity().onConnectivityChanged.listen(
        _onConnectivity,
        // A platform without the plugin (tests, desktop) simply loses the
        // reconnect trigger; resume and the manual retry still work.
        onError: (_) {},
      );
    } catch (_) {
      // Same fallback as above.
    }
  }

  void _onConnectivity(List<ConnectivityResult> results) {
    final online = results.any((result) => result != ConnectivityResult.none);
    // Only the transition back online is interesting: a stream of "mobile"
    // events while already connected must not replay the queue.
    if (online && _wasOffline) _sync();
    _wasOffline = !online;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  Future<void> _sync() async {
    if (!mounted) return;
    final report = await ref.read(flagQueueProvider.notifier).sync();
    if (report.synced > 0 && mounted) {
      // The server now has pins the Explore payload was loaded without.
      ref.invalidate(exploreFlagsProvider);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
