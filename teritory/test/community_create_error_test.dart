import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teritory/core/services/api_service.dart';
import 'package:teritory/features/community/presentation/community_create_screen.dart';

/// Offline coverage for the honest-error path: no server, a fake repository
/// call, and an assertion that the server's own message reaches the user and
/// that Retry re-submits.
void main() {
  setUpAll(() {
    // Keep the test hermetic: google_fonts must not try the network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('a rejected create shows the server message; Retry re-submits', (
    tester,
  ) async {
    var calls = 0;
    final payloads = <String>[];

    Future<void> failingCreate({
      required String name,
      required String description,
      required List<String> interestTags,
      required bool isPublic,
      String? coverImageUrl,
    }) async {
      calls++;
      payloads.add(name);
      throw ApiException(
        'Only members of this clan can found a community',
        statusCode: 403,
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CommunityCreateScreen(
            clanId: 'clan-42',
            create: failingCreate,
          ),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    expect(
      fields,
      findsNWidgets(3),
      reason: 'name, description and optional cover URL',
    );
    await tester.enterText(fields.at(0), 'Munnar Trekkers');
    await tester.enterText(fields.at(1), 'Weekend trails from Kochi');

    final submit = find.widgetWithText(ElevatedButton, 'Create Community');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(payloads.single, 'Munnar Trekkers');
    expect(
      find.text('Only members of this clan can found a community'),
      findsOneWidget,
      reason: 'the server message is shown, not a generic failure',
    );

    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(calls, 2, reason: 'Retry re-submits the same form');
    expect(
      find.text('Only members of this clan can found a community'),
      findsOneWidget,
    );
  });

  testWidgets('an unexpected failure falls back to an actionable message', (
    tester,
  ) async {
    Future<void> offlineCreate({
      required String name,
      required String description,
      required List<String> interestTags,
      required bool isPublic,
      String? coverImageUrl,
    }) async {
      throw const SocketExceptionStub();
    }

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CommunityCreateScreen(clanId: 'clan-42', create: offlineCreate),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Coastal Riders');
    await tester.enterText(fields.at(1), 'Sunset rides');

    final submit = find.widgetWithText(ElevatedButton, 'Create Community');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Check your connection and retry'),
      findsOneWidget,
    );
  });
}

/// A non-[ApiException] failure, standing in for a dead network.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
