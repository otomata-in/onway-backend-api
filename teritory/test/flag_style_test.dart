import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teritory/core/models/api_flag.dart';
import 'package:teritory/core/models/api_user.dart';
import 'package:teritory/core/models/flag_style.dart';
import 'package:teritory/core/models/pending_flag.dart';
import 'package:teritory/core/theme/flag_style_catalog.dart';

Map<String, dynamic> _flagJson({Object? flagStyle, Object? ownerStyle}) => {
  'id': 'f1',
  'userId': 'u1',
  'placeName': 'Fort Kochi',
  'city': 'Kochi',
  'country': 'India',
  'countryCode': 'IN',
  'continent': 'Asia',
  'latitude': 9.9658,
  'longitude': 76.2421,
  'isMajorFlag': false,
  'category': 'Coastal Heritage',
  'notes': '',
  'photoUrl': '',
  'kudos': 4,
  'distanceKm': 1.2,
  'createdAt': '2026-01-04T10:00:00.000Z',
  'flagStyle': flagStyle,
  'user': {
    'id': 'u1',
    'displayName': 'Arun',
    'handle': 'arun',
    'avatarUrl': '',
    'flagStyle': ownerStyle,
  },
};

void main() {
  group('FlagStyle codec', () {
    test('round-trips a full style', () {
      const style = FlagStyle(
        theme: 'aurora',
        color: '#0EA5E9',
        pattern: 'tide',
        shape: 'swallowtail',
        emblem: 'compass_rose',
        motion: 'gust',
        speed: 1.4,
      );

      final decoded = FlagStyle.fromJson(
        jsonDecode(jsonEncode(style.toJson())),
      );

      expect(decoded, style);
      expect(decoded.toJson()['v'], FlagStyle.currentVersion);
    });

    test('the default style is valid and static-safe', () {
      expect(FlagStyle.fallback.theme, FlagStyle.defaultTheme);
      expect(FlagStyle.themeIds, contains(FlagStyle.fallback.theme));
      expect(FlagStyle.patternIds, contains(FlagStyle.fallback.pattern));
      expect(FlagStyle.shapeIds, contains(FlagStyle.fallback.shape));
      expect(FlagStyle.emblemIds, contains(FlagStyle.fallback.emblem));
      expect(FlagStyle.motionIds, contains(FlagStyle.fallback.motion));
    });

    test('unknown ids fall back to their default instead of throwing', () {
      final style = FlagStyle.fromJson({
        'theme': 'volcano',
        'pattern': 42,
        'shape': '',
        'emblem': null,
        'motion': 'TORNADO',
      });

      expect(style.theme, FlagStyle.defaultTheme);
      expect(style.pattern, FlagStyle.defaultPattern);
      expect(style.shape, FlagStyle.defaultShape);
      expect(style.emblem, FlagStyle.defaultEmblem);
      expect(style.motion, FlagStyle.defaultMotion);
    });

    test('colour is canonicalised and invalid values clear the override', () {
      expect(
        FlagStyle.fromJson({'color': '0ea5e9'}).color,
        '#0EA5E9',
      );
      expect(FlagStyle.fromJson({'color': '#a1b2c3'}).color, '#A1B2C3');
      expect(FlagStyle.fromJson({'color': 'red'}).color, isNull);
      expect(FlagStyle.fromJson({'color': '#12345'}).color, isNull);
    });

    test('speed is clamped to the supported range', () {
      expect(FlagStyle.fromJson({'speed': 0.1}).speed, FlagStyle.minSpeed);
      expect(FlagStyle.fromJson({'speed': 9}).speed, FlagStyle.maxSpeed);
      expect(FlagStyle.fromJson({'speed': 'fast'}).speed, FlagStyle.defaultSpeed);
      expect(FlagStyle.fromJson({'speed': 1.23456}).speed, 1.23);
    });

    test('a malformed payload is the default style, never an exception', () {
      expect(FlagStyle.fromJson(null), FlagStyle.fallback);
      expect(FlagStyle.fromJson('not json'), FlagStyle.fallback);
      expect(FlagStyle.fromJson([1, 2, 3]), FlagStyle.fallback);
    });

    test('copyWith preserves fields and can clear the colour', () {
      const style = FlagStyle(theme: 'aurora', color: '#112233', motion: 'gust');
      final moved = style.copyWith(pattern: 'weave');

      expect(moved.theme, 'aurora');
      expect(moved.color, '#112233');
      expect(moved.pattern, 'weave');
      expect(moved.motion, 'gust');

      expect(moved.copyWith(color: null).color, isNull);
    });

    test('value equality includes every dimension', () {
      const base = FlagStyle(theme: 'aurora', speed: 1.2);

      expect(base, const FlagStyle(theme: 'aurora', speed: 1.2));
      expect(base.hashCode, const FlagStyle(theme: 'aurora', speed: 1.2).hashCode);
      expect(base == base.copyWith(theme: 'emerald_trail'), isFalse);
      expect(base == base.copyWith(shape: 'pennant'), isFalse);
      expect(base == base.copyWith(emblem: 'paw'), isFalse);
      expect(base == base.copyWith(motion: 'still'), isFalse);
      expect(base == base.copyWith(speed: 1.5), isFalse);
      expect(base == base.copyWith(color: '#FFFFFF'), isFalse);
    });
  });

  group('FlagStyleCatalog', () {
    test('every catalog id is part of the wire vocabulary', () {
      expect(
        FlagStyleCatalog.themes.map((t) => t.id).toList(),
        FlagStyle.themeIds,
      );
      expect(
        FlagStyleCatalog.patterns.map((p) => p.id).toList(),
        FlagStyle.patternIds,
      );
      expect(FlagStyleCatalog.shapes.map((s) => s.id).toList(), FlagStyle.shapeIds);
      expect(
        FlagStyleCatalog.emblems.map((e) => e.id).toList(),
        FlagStyle.emblemIds,
      );
      expect(FlagStyleCatalog.motions.map((m) => m.id).toList(), FlagStyle.motionIds);
    });

    test('ids and preset ids are unique', () {
      for (final ids in [
        FlagStyle.themeIds,
        FlagStyle.patternIds,
        FlagStyle.shapeIds,
        FlagStyle.emblemIds,
        FlagStyle.motionIds,
      ]) {
        expect(ids.toSet().length, ids.length);
      }
      final presetIds = FlagStyleCatalog.presets.map((p) => p.id).toList();
      expect(presetIds.toSet().length, presetIds.length);
    });

    test('every preset is already a valid style', () {
      for (final preset in FlagStyleCatalog.presets) {
        expect(
          FlagStyleCatalog.normalize(preset.style),
          preset.style,
          reason: preset.id,
        );
      }
    });

    test('lookup helpers fall back to the first entry', () {
      expect(FlagStyleCatalog.themeFor('missing').id, 'midnight_tide');
      expect(FlagStyleCatalog.patternFor('missing').id, 'solid');
      expect(FlagStyleCatalog.motionFor('missing').id, 'still');
      expect(FlagStyleCatalog.presetFor('missing'), isNull);
    });

    test('hex colours round-trip and drive the effective primary', () {
      expect(FlagStyleCatalog.hexOf(const Color(0xFF0EA5E9)), '#0EA5E9');
      expect(
        FlagStyleCatalog.colorFromHex('#0ea5e9'),
        const Color(0xFF0EA5E9),
      );
      expect(FlagStyleCatalog.colorFromHex('nope'), isNull);

      const themed = FlagStyle(theme: 'emerald_trail');
      expect(
        FlagStyleCatalog.primaryColor(themed),
        FlagStyleCatalog.themeFor('emerald_trail').primary,
      );
      expect(
        FlagStyleCatalog.primaryColor(themed.copyWith(color: '#123456')),
        const Color(0xFF123456),
      );
    });

    test('foreground ink stays readable on light and dark cloth', () {
      expect(FlagStyleCatalog.foregroundOn(Colors.white), const Color(0xFF0F172A));
      expect(FlagStyleCatalog.foregroundOn(Colors.black), const Color(0xFFFFFFFF));
    });

    test('blue is the default and the orange theme is demoted', () {
      expect(FlagStyle.defaultTheme, 'midnight_tide');
      expect(FlagStyle.fallback.theme, 'midnight_tide');
      expect(FlagStyle.themeIds.first, 'midnight_tide');
      expect(FlagStyle.themeIds.last, 'coral_expedition');
      expect(FlagStyleCatalog.themes.first.id, 'midnight_tide');
      expect(FlagStyleCatalog.themes.last.id, 'coral_expedition');

      // The first preset is exactly the product default, so a fresh traveller
      // sees a selected preset rather than an empty selection.
      expect(FlagStyleCatalog.presets.first.style, FlagStyle.fallback);
      expect(
        FlagStyleCatalog.presets.any((p) => p.style.theme == 'coral_expedition'),
        isFalse,
      );
    });

    test('red, pirate, hacker and rider identities exist', () {
      for (final id in const [
        'crimson_charge',
        'black_pirate',
        'neon_hacker',
        'rider_steel',
      ]) {
        expect(FlagStyle.themeIds, contains(id));
        expect(FlagStyleCatalog.themeFor(id).id, id);
      }
    });

    test('bikes and cars are selectable emblems', () {
      for (final id in const [
        'bike_road',
        'bike_mountain',
        'bike_moto',
        'car_sedan',
        'car_suv',
        'car_sports',
      ]) {
        expect(FlagStyle.emblemIds, contains(id));
        expect(FlagStyleCatalog.emblemFor(id).id, id);
      }
      expect(FlagStyle.emblemIds, contains('skull'));
      expect(FlagStyle.emblemIds, contains('terminal'));
      expect(FlagStyle.emblemIds, contains('helmet'));
    });

    test('game-grade motions are offered', () {
      for (final id in const ['storm', 'inferno', 'neon_pulse']) {
        expect(FlagStyle.motionIds, contains(id));
        expect(FlagStyleCatalog.motionFor(id).id, id);
      }
      expect(const FlagStyle(motion: 'storm').isAnimated, isTrue);
    });

    test('mid-tone accents get dark ink, not weak white ink', () {
      expect(
        FlagStyleCatalog.foregroundOn(const Color(0xFFD4AF37)),
        const Color(0xFF0F172A),
      );
    });

    test('normalize repairs a hand-built style', () {
      const rough = FlagStyle(theme: 'nope', pattern: 'weave', speed: 8);
      final fixed = FlagStyleCatalog.normalize(rough);

      expect(fixed.theme, FlagStyle.defaultTheme);
      expect(fixed.pattern, 'weave');
      expect(fixed.speed, FlagStyle.maxSpeed);
    });
  });

  group('API parsing', () {
    test('ApiFlag carries its own style snapshot', () {
      final flag = ApiFlag.fromJson(
        _flagJson(
          flagStyle: {
            'v': 1,
            'theme': 'aurora',
            'color': '#0ea5e9',
            'pattern': 'tide',
            'shape': 'pennant',
            'emblem': 'star',
            'motion': 'gust',
            'speed': 1.4,
          },
        ),
      );

      expect(flag.flagStyle.theme, 'aurora');
      expect(flag.flagStyle.color, '#0EA5E9');
      expect(flag.flagStyle.motion, 'gust');
      expect(flag.toFlagItem().style, flag.flagStyle);
      expect(flag.toFriendFlag().style, flag.flagStyle);
    });

    test('a legacy flag falls back to the owner signature, then default', () {
      final legacy = ApiFlag.fromJson(
        _flagJson(
          flagStyle: null,
          ownerStyle: {'theme': 'emerald_trail', 'pattern': 'solid'},
        ),
      );
      expect(legacy.flagStyle.theme, 'emerald_trail');
      expect(legacy.flagStyle.pattern, 'solid');

      final bare = ApiFlag.fromJson(_flagJson());
      expect(bare.flagStyle, FlagStyle.fallback);
    });

    test('ApiUser carries the signature', () {
      final user = ApiUser.fromJson({
        'id': 'u1',
        'displayName': 'Arun',
        'handle': 'arun',
        'flagStyle': {'theme': 'sakura_dusk', 'emblem': 'flame'},
      });

      expect(user.flagStyle.theme, 'sakura_dusk');
      expect(user.flagStyle.emblem, 'flame');
    });

    test('a user without a signature reads as the product default', () {
      final user = ApiUser.fromJson({
        'id': 'u1',
        'displayName': 'Arun',
        'handle': 'arun',
      });
      expect(user.flagStyle, FlagStyle.fallback);
    });
  });

  group('PendingFlag offline round-trip', () {
    test('keeps the chosen style across a restart', () {
      final flag = PendingFlag(
        localId: 'local-1',
        userId: 'u1',
        placeName: 'Varkala Cliff',
        latitude: 8.7379,
        longitude: 76.7163,
        createdAt: DateTime.utc(2026, 2, 3, 8),
        flagStyle: const FlagStyle(
          theme: 'midnight_tide',
          shape: 'burgee',
          motion: 'still',
        ),
      );

      final restored = PendingFlag.fromJson(
        jsonDecode(jsonEncode(flag.toJson())) as Map<String, dynamic>,
      );

      expect(restored.flagStyle, flag.flagStyle);
      expect(restored.style.theme, 'midnight_tide');
      expect(restored.style.motion, 'still');
    });

    test('an old queued entry without a style still decodes', () {
      final restored = PendingFlag.fromJson({
        'localId': 'local-2',
        'userId': 'u1',
        'placeName': 'Munnar Top',
        'latitude': 10.08,
        'longitude': 77.06,
        'createdAt': '2026-02-03T08:00:00.000Z',
      });

      expect(restored.flagStyle, isNull);
      expect(restored.style, FlagStyle.fallback);
    });

    test('copyWith on a failed sync keeps the style', () {
      const style = FlagStyle(theme: 'desert_mirage');
      final flag = PendingFlag(
        localId: 'local-3',
        userId: 'u1',
        placeName: 'Jaisalmer',
        latitude: 26.91,
        longitude: 70.91,
        createdAt: DateTime.utc(2026, 2, 3),
        flagStyle: style,
      );

      final failed = flag.copyWith(lastError: 'offline', attempts: 1);
      expect(failed.flagStyle, style);
      expect(failed.lastError, 'offline');
    });
  });
}
