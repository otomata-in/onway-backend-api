import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_flag.dart';
import '../../../core/services/teritory_repository.dart';

/// The major wonders registry (`GET /flags/wonders`).
///
/// Live-only: the server derives it from flags travelers staked as major
/// wonders. There is no bundled catalogue to fall back to, so failures surface
/// as an error state with a retry.
final wondersProvider = FutureProvider.autoDispose<List<ApiWonder>>((ref) {
  return TeritoryRepository.instance.fetchWonders();
});

/// Continents present in the registry, for the filter chips. Derived from the
/// payload so the chips never offer a continent with no rows.
List<String> wonderContinents(List<ApiWonder> wonders) {
  final continents = <String>{
    for (final wonder in wonders)
      if (wonder.continent.trim().isNotEmpty) wonder.continent.trim(),
  }.toList()..sort();
  return continents;
}
