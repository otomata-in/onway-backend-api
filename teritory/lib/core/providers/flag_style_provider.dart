import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/flag_style.dart';
import '../services/teritory_repository.dart';
import '../theme/flag_style_catalog.dart';
import 'preferences_provider.dart';

/// The traveller's signature flag, as the server last confirmed it.
///
/// The cached value is what pins and offline drops draw before the profile
/// request settles; [saveSignature] is server-first, so a refused save leaves
/// the previous style in place and rethrows for the UI to show.
class FlagStyleNotifier extends Notifier<FlagStyle> {
  @override
  FlagStyle build() => PreferenceStore.instance.flagStyle;

  /// `PATCH /users/me/flag-style`. Returns the normalised style the server
  /// stored, which becomes the new state and cache.
  Future<FlagStyle> saveSignature(FlagStyle style) async {
    final saved = await TeritoryRepository.instance.updateMyFlagStyle(
      FlagStyleCatalog.normalize(style),
    );
    state = saved;
    await PreferenceStore.instance.setFlagStyle(saved);
    return saved;
  }

  /// Replaces the local copy with the style in a profile response. The server
  /// is authoritative: a style saved on another device shows up here too.
  Future<void> syncFromProfile(FlagStyle style) async {
    final normalized = FlagStyleCatalog.normalize(style);
    if (normalized == state) return;
    state = normalized;
    await PreferenceStore.instance.setFlagStyle(normalized);
  }
}

final flagStyleProvider =
    NotifierProvider<FlagStyleNotifier, FlagStyle>(FlagStyleNotifier.new);
