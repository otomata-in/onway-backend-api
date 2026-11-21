import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_flag.dart';

/// Durable home of the flag queue.
///
/// Storage is best-effort on purpose: an unwritable preferences file must leave
/// the queue alive in memory for this session instead of turning "stake this
/// spot" into a crash. [init] runs before `runApp`, so providers can read the
/// queue synchronously.
class PendingFlagStore {
  PendingFlagStore._();
  static final PendingFlagStore instance = PendingFlagStore._();

  static const String storageKey = 'teritory_pending_flags';

  List<PendingFlag> _items = const [];

  List<PendingFlag> get items => List<PendingFlag>.unmodifiable(_items);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _items = _decode(prefs.getString(storageKey));
    } catch (_) {
      // Unreadable prefs: start empty rather than block startup.
      _items = const [];
    }
  }

  Future<void> save(List<PendingFlag> items) async {
    _items = List<PendingFlag>.of(items);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        storageKey,
        jsonEncode(_items.map((flag) => flag.toJson()).toList()),
      );
    } catch (_) {
      // Memory still holds the queue; the next successful write persists it.
    }
  }

  List<PendingFlag> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PendingFlag.fromJson)
          .where((flag) => flag.localId.isNotEmpty)
          .toList();
    } catch (_) {
      // A corrupt entry must not take the whole queue with it.
      return const [];
    }
  }
}
