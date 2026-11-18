import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/rally_models.dart';
import '../../../core/services/teritory_repository.dart';

/// Live-only rally providers. Rallies are only ever what `teritory-api`
/// returns; `ApiException` propagates so the sheet can render the server
/// message with a retry instead of sample rows.

typedef RallyLocation = ({double lat, double lng});
typedef RallyDetailKey = ({String rallyId, double lat, double lng});

final nearbyRalliesProvider = FutureProvider.autoDispose
    .family<List<LegendaryRally>, RallyLocation>((ref, location) {
      return TeritoryRepository.instance.fetchNearbyRallies(
        latitude: location.lat,
        longitude: location.lng,
      );
    });

final rallyDetailProvider = FutureProvider.autoDispose
    .family<RallyDetail, RallyDetailKey>((ref, key) {
      return TeritoryRepository.instance.fetchRallyDetail(
        key.rallyId,
        latitude: key.lat,
        longitude: key.lng,
      );
    });
