import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teritory/core/models/pending_flag.dart';
import 'package:teritory/core/models/user_models.dart';
import 'package:teritory/core/providers/auth_provider.dart';
import 'package:teritory/core/services/api_service.dart';
import 'package:teritory/core/services/pending_flag_store.dart';
import 'package:teritory/features/flag/application/flag_queue_provider.dart';

final User _traveler = User(
  id: 'u1',
  email: 'arjun@example.com',
  phone: '+919876543210',
  displayName: 'Arjun Nair',
  handle: 'arjunnair',
  avatarUrl: '',
  createdAt: DateTime(2024, 1, 1),
);

final User _otherTraveler = User(
  id: 'u2',
  email: 'other@example.com',
  phone: '+919876543211',
  displayName: 'Other Traveler',
  handle: 'other',
  avatarUrl: '',
  createdAt: DateTime(2024, 1, 1),
);

ProviderContainer _container(
  FlagDropRequest drop, {
  User? user,
}) {
  final container = ProviderContainer(
    overrides: [
      currentUserProvider.overrideWithValue(user ?? _traveler),
      flagDropRequestProvider.overrideWithValue(drop),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<PendingFlag> _enqueue(
  ProviderContainer container,
  String placeName, {
  double latitude = 9.9701,
  String userId = 'u1',
}) {
  return container
      .read(flagQueueProvider.notifier)
      .enqueue(
        userId: userId,
        placeName: placeName,
        latitude: latitude,
        longitude: 76.2801,
        city: 'Kochi',
      );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PendingFlagStore.instance.init();
  });

  test('a queued flag survives a restart', () async {
    final container = _container((_) async {});
    await _enqueue(container, 'Varkala Cliff');

    // The next app launch reads the same store before runApp.
    await PendingFlagStore.instance.init();
    final relaunched = _container((_) async {});

    final queue = relaunched.read(flagQueueProvider);
    expect(queue, hasLength(1));
    expect(queue.single.placeName, 'Varkala Cliff');
    expect(queue.single.latitude, 9.9701);
    expect(queue.single.userId, 'u1');
  });

  test('sync stakes queued flags and empties the queue', () async {
    final calls = <String>[];
    final container = _container((flag) async => calls.add(flag.placeName));
    await _enqueue(container, 'Varkala Cliff');
    await _enqueue(container, 'Munnar Top', latitude: 10.08);

    final report = await container.read(flagQueueProvider.notifier).sync();

    expect(report.synced, 2);
    expect(report.pending, 0);
    expect(calls, ['Varkala Cliff', 'Munnar Top']);
    expect(container.read(flagQueueProvider), isEmpty);
    expect(PendingFlagStore.instance.items, isEmpty);
  });

  test('a 409 on a retried flag is success, not an error', () async {
    final container = _container((flag) async {
      // The first attempt reached the server before the response was lost, so
      // the spot is already staked.
      throw ApiException(
        'You already staked this spot ("Varkala Cliff").',
        statusCode: 409,
      );
    });
    await _enqueue(container, 'Varkala Cliff');

    final report = await container.read(flagQueueProvider.notifier).sync();

    expect(report.synced, 1);
    expect(container.read(flagQueueProvider), isEmpty);
    expect(PendingFlagStore.instance.items, isEmpty);
  });

  test('a dead connection keeps the flag with the honest reason', () async {
    final container = _container((_) async => throw Exception('offline'));
    await _enqueue(container, 'Varkala Cliff');

    final report = await container.read(flagQueueProvider.notifier).sync();

    expect(report.synced, 0);
    final queue = container.read(flagQueueProvider);
    expect(queue, hasLength(1));
    expect(queue.single.lastError, 'Still offline — will retry');
    expect(queue.single.attempts, 1);
    expect(PendingFlagStore.instance.items.single.lastError, isNotNull);
  });

  test('sync stops at the first failure so the stake order is kept', () async {
    final calls = <String>[];
    final container = _container((flag) async {
      calls.add(flag.placeName);
      if (flag.placeName == 'First') throw Exception('offline');
    });
    await _enqueue(container, 'First');
    await _enqueue(container, 'Second', latitude: 10.08);

    final report = await container.read(flagQueueProvider.notifier).sync();

    expect(report.synced, 0);
    expect(calls, ['First']);
    expect(container.read(flagQueueProvider).map((f) => f.placeName), [
      'First',
      'Second',
    ]);
  });

  test('a server refusal stays queued with the server message', () async {
    final container = _container(
      (_) async => throw ApiException(
        'Latitude and longitude must be valid coordinates',
        statusCode: 400,
      ),
    );
    await _enqueue(container, 'Bad Spot');

    await container.read(flagQueueProvider.notifier).sync();

    final pending = container.read(flagQueueProvider).single;
    expect(pending.lastError, 'Latitude and longitude must be valid coordinates');
    expect(pending.attempts, 1);
  });

  test('another traveler never replays the queue', () async {
    final calls = <String>[];
    final owner = _container((flag) async => calls.add(flag.placeName));
    await _enqueue(owner, 'Varkala Cliff');

    final other = _container((flag) async => calls.add(flag.placeName),
        user: _otherTraveler);
    final report = await other.read(flagQueueProvider.notifier).sync();

    expect(report.skipped, isTrue);
    expect(calls, isEmpty);
    expect(other.read(flagQueueProvider), hasLength(1));
  });

  test('discard removes the flag from the device', () async {
    final container = _container((_) async {});
    final flag = await _enqueue(container, 'Varkala Cliff');

    await container.read(flagQueueProvider.notifier).discard(flag.localId);

    expect(container.read(flagQueueProvider), isEmpty);
    expect(PendingFlagStore.instance.items, isEmpty);
  });
}
