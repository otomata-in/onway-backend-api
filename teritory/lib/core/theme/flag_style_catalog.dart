import 'dart:ui' show Color;

import 'package:flutter/material.dart' show IconData, Icons;

import '../models/flag_style.dart';

/// Curated palette for one flag theme. The renderer derives everything else
/// (shading, emblem disc, border) from these five colours so a theme can never
/// produce an unreadable flag.
class FlagThemeData {
  final String id;
  final String label;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color pole;
  final Color finial;

  const FlagThemeData({
    required this.id,
    required this.label,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.pole,
    required this.finial,
  });
}

class FlagPatternData {
  final String id;
  final String label;

  const FlagPatternData(this.id, this.label);
}

class FlagShapeData {
  final String id;
  final String label;

  const FlagShapeData(this.id, this.label);
}

class FlagEmblemData {
  final String id;
  final String label;
  final IconData icon;

  const FlagEmblemData(this.id, this.label, this.icon);
}

class FlagMotionData {
  final String id;
  final String label;
  final String description;

  const FlagMotionData(this.id, this.label, this.description);
}

class FlagPreset {
  final String id;
  final String label;
  final FlagStyle style;

  const FlagPreset({required this.id, required this.label, required this.style});
}

/// The whole flag vocabulary in one place: colours, labels and ready-made
/// presets. Ids mirror [FlagStyle] and the server validator exactly.
class FlagStyleCatalog {
  const FlagStyleCatalog._();

  static const List<FlagThemeData> themes = [
    // Blue is the default identity (first, and FlagStyle.fallback).
    FlagThemeData(
      id: 'midnight_tide',
      label: 'Midnight Tide',
      primary: Color(0xFF0EA5E9),
      secondary: Color(0xFF1E3A8A),
      accent: Color(0xFF22D3EE),
      pole: Color(0xFF475569),
      finial: Color(0xFFE2E8F0),
    ),
    FlagThemeData(
      id: 'crimson_charge',
      label: 'Crimson Charge',
      primary: Color(0xFFDC2626),
      secondary: Color(0xFF7F1D1D),
      accent: Color(0xFFFDE68A),
      pole: Color(0xFF57534E),
      finial: Color(0xFFFCA5A5),
    ),
    FlagThemeData(
      id: 'black_pirate',
      label: 'Black Pirate',
      primary: Color(0xFF0B0B0F),
      secondary: Color(0xFF1F2937),
      accent: Color(0xFFD4AF37),
      pole: Color(0xFF44403C),
      finial: Color(0xFFD4AF37),
    ),
    FlagThemeData(
      id: 'neon_hacker',
      label: 'Neon Hacker',
      primary: Color(0xFF04120B),
      secondary: Color(0xFF052E16),
      accent: Color(0xFF22C55E),
      pole: Color(0xFF111827),
      finial: Color(0xFF4ADE80),
    ),
    FlagThemeData(
      id: 'rider_steel',
      label: 'Rider Steel',
      primary: Color(0xFF1F2937),
      secondary: Color(0xFF0F172A),
      accent: Color(0xFFA3E635),
      pole: Color(0xFF6B7280),
      finial: Color(0xFFA3E635),
    ),
    FlagThemeData(
      id: 'golden_summit',
      label: 'Golden Summit',
      primary: Color(0xFFD97706),
      secondary: Color(0xFFB45309),
      accent: Color(0xFFFDE68A),
      pole: Color(0xFF78716C),
      finial: Color(0xFFFBBF24),
    ),
    FlagThemeData(
      id: 'emerald_trail',
      label: 'Emerald Trail',
      primary: Color(0xFF10B981),
      secondary: Color(0xFF047857),
      accent: Color(0xFFA7F3D0),
      pole: Color(0xFF475569),
      finial: Color(0xFF34D399),
    ),
    FlagThemeData(
      id: 'sakura_dusk',
      label: 'Sakura Dusk',
      primary: Color(0xFFF472B6),
      secondary: Color(0xFFBE185D),
      accent: Color(0xFFFDBA74),
      pole: Color(0xFF6B7280),
      finial: Color(0xFFFBCFE8),
    ),
    FlagThemeData(
      id: 'desert_mirage',
      label: 'Desert Mirage',
      primary: Color(0xFFEA580C),
      secondary: Color(0xFF9A3412),
      accent: Color(0xFFFDE68A),
      pole: Color(0xFF8B7355),
      finial: Color(0xFFFCD34D),
    ),
    FlagThemeData(
      id: 'aurora',
      label: 'Aurora',
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFF06B6D4),
      accent: Color(0xFF34D399),
      pole: Color(0xFF334155),
      finial: Color(0xFFC4B5FD),
    ),
    FlagThemeData(
      id: 'monochrome_ink',
      label: 'Monochrome Ink',
      primary: Color(0xFF334155),
      secondary: Color(0xFF0F172A),
      accent: Color(0xFFE2E8F0),
      pole: Color(0xFF1E293B),
      finial: Color(0xFFCBD5E1),
    ),
    // Legacy theme: flags already staked in it keep working, but it sits last
    // so the orange family is no longer the first thing a traveller sees.
    FlagThemeData(
      id: 'coral_expedition',
      label: 'Coral Expedition',
      primary: Color(0xFFFF5330),
      secondary: Color(0xFFD63B19),
      accent: Color(0xFFF59E0B),
      pole: Color(0xFF64748B),
      finial: Color(0xFFF59E0B),
    ),
  ];

  static const List<FlagPatternData> patterns = [
    FlagPatternData('solid', 'Solid'),
    FlagPatternData('horizon', 'Horizon'),
    FlagPatternData('chevron', 'Chevron'),
    FlagPatternData('tide', 'Tidal Waves'),
    FlagPatternData('sunburst', 'Sunburst'),
    FlagPatternData('constellation', 'Constellation'),
    FlagPatternData('topographic', 'Topographic'),
    FlagPatternData('weave', 'Weave'),
  ];

  static const List<FlagShapeData> shapes = [
    FlagShapeData('classic', 'Classic'),
    FlagShapeData('swallowtail', 'Swallowtail'),
    FlagShapeData('pennant', 'Pennant'),
    FlagShapeData('burgee', 'Burgee'),
  ];

  static const List<FlagEmblemData> emblems = [
    FlagEmblemData('none', 'None', Icons.block_rounded),
    FlagEmblemData('compass', 'Compass', Icons.explore_rounded),
    FlagEmblemData('peak', 'Peak', Icons.landscape_rounded),
    FlagEmblemData('anchor', 'Anchor', Icons.anchor_rounded),
    FlagEmblemData('star', 'Star', Icons.star_rounded),
    FlagEmblemData('flame', 'Flame', Icons.local_fire_department_rounded),
    FlagEmblemData('compass_rose', 'Compass Rose', Icons.navigation_rounded),
    FlagEmblemData('paw', 'Trail Paw', Icons.pets_rounded),
    FlagEmblemData('skull', 'Skull', Icons.dangerous_rounded),
    FlagEmblemData('terminal', 'Terminal', Icons.terminal_rounded),
    FlagEmblemData('helmet', 'Helmet', Icons.sports_motorsports_rounded),
    FlagEmblemData('bike_road', 'Road Bike', Icons.pedal_bike_rounded),
    FlagEmblemData('bike_mountain', 'Mountain Bike', Icons.directions_bike_rounded),
    FlagEmblemData('bike_moto', 'Motorbike', Icons.two_wheeler_rounded),
    FlagEmblemData('car_sedan', 'Sedan', Icons.directions_car_rounded),
    FlagEmblemData('car_suv', 'SUV', Icons.airport_shuttle_rounded),
    FlagEmblemData('car_sports', 'Sports Car', Icons.electric_car_rounded),
  ];

  static const List<FlagMotionData> motions = [
    FlagMotionData('still', 'Still', 'A calm flag for busy maps'),
    FlagMotionData('breeze', 'Breeze', 'One easy wind wave'),
    FlagMotionData('gust', 'Gust', 'Layered wind, stronger at the fly'),
    FlagMotionData('ripple', 'Ripple', 'A travelling fabric ripple'),
    FlagMotionData('shimmer', 'Shimmer', 'Soft light crossing the cloth'),
    FlagMotionData('aurora', 'Aurora', 'Colour drifting through the cloth'),
    FlagMotionData('storm', 'Storm', 'Heavy wind with speed streaks'),
    FlagMotionData('inferno', 'Inferno', 'Flickering cloth and rising embers'),
    FlagMotionData('neon_pulse', 'Neon Pulse', 'A glowing edge that breathes'),
  ];

  /// One tap gives every dimension at once; the studio then fine-tunes.
  static const List<FlagPreset> presets = [
    FlagPreset(
      id: 'signature_blue',
      label: 'Signature Blue',
      // Exactly the product default, so a fresh traveller sees a selected
      // preset instead of an empty selection.
      style: FlagStyle(),
    ),
    FlagPreset(
      id: 'midnight_tide',
      label: 'Midnight Tide',
      style: FlagStyle(
        theme: 'midnight_tide',
        pattern: 'tide',
        shape: 'swallowtail',
        emblem: 'compass_rose',
        motion: 'ripple',
      ),
    ),
    FlagPreset(
      id: 'scarlet_charge',
      label: 'Crimson Charge',
      style: FlagStyle(
        theme: 'crimson_charge',
        pattern: 'chevron',
        shape: 'pennant',
        emblem: 'star',
        motion: 'gust',
      ),
    ),
    FlagPreset(
      id: 'pirate_black',
      label: 'Black Pirate',
      style: FlagStyle(
        theme: 'black_pirate',
        pattern: 'weave',
        shape: 'swallowtail',
        emblem: 'skull',
        motion: 'storm',
        speed: 1.2,
      ),
    ),
    FlagPreset(
      id: 'hacker_green',
      label: 'Neon Hacker',
      style: FlagStyle(
        theme: 'neon_hacker',
        pattern: 'constellation',
        shape: 'classic',
        emblem: 'terminal',
        motion: 'neon_pulse',
      ),
    ),
    FlagPreset(
      id: 'rider_steel',
      label: 'Rider Steel',
      style: FlagStyle(
        theme: 'rider_steel',
        pattern: 'chevron',
        shape: 'burgee',
        emblem: 'helmet',
        motion: 'gust',
      ),
    ),
    FlagPreset(
      id: 'road_bike',
      label: 'Road Bike',
      style: FlagStyle(
        theme: 'emerald_trail',
        pattern: 'solid',
        shape: 'pennant',
        emblem: 'bike_road',
        motion: 'breeze',
      ),
    ),
    FlagPreset(
      id: 'trail_suv',
      label: 'Trail SUV',
      style: FlagStyle(
        theme: 'desert_mirage',
        pattern: 'topographic',
        shape: 'classic',
        emblem: 'car_suv',
        motion: 'still',
      ),
    ),
    FlagPreset(
      id: 'golden_summit',
      label: 'Golden Summit',
      style: FlagStyle(
        theme: 'golden_summit',
        pattern: 'sunburst',
        shape: 'pennant',
        emblem: 'peak',
        motion: 'shimmer',
      ),
    ),
    FlagPreset(
      id: 'emerald_trail',
      label: 'Emerald Trail',
      style: FlagStyle(
        theme: 'emerald_trail',
        pattern: 'topographic',
        shape: 'burgee',
        emblem: 'paw',
        motion: 'breeze',
      ),
    ),
    FlagPreset(
      id: 'sakura_dusk',
      label: 'Sakura Dusk',
      style: FlagStyle(
        theme: 'sakura_dusk',
        pattern: 'chevron',
        shape: 'swallowtail',
        emblem: 'star',
        motion: 'gust',
      ),
    ),
    FlagPreset(
      id: 'desert_nomad',
      label: 'Desert Nomad',
      style: FlagStyle(
        theme: 'desert_mirage',
        pattern: 'weave',
        shape: 'pennant',
        emblem: 'flame',
        motion: 'still',
      ),
    ),
    FlagPreset(
      id: 'aurora_seeker',
      label: 'Aurora Seeker',
      style: FlagStyle(
        theme: 'aurora',
        pattern: 'constellation',
        shape: 'classic',
        emblem: 'star',
        motion: 'aurora',
        speed: 1.0,
      ),
    ),
    FlagPreset(
      id: 'ink_minimal',
      label: 'Ink Minimal',
      style: FlagStyle(
        theme: 'monochrome_ink',
        pattern: 'solid',
        shape: 'classic',
        emblem: 'none',
        motion: 'still',
      ),
    ),
  ];

  static FlagThemeData themeFor(String id) {
    for (final theme in themes) {
      if (theme.id == id) return theme;
    }
    return themes.first;
  }

  static FlagPatternData patternFor(String id) {
    for (final pattern in patterns) {
      if (pattern.id == id) return pattern;
    }
    return patterns.first;
  }

  static FlagShapeData shapeFor(String id) {
    for (final shape in shapes) {
      if (shape.id == id) return shape;
    }
    return shapes.first;
  }

  static FlagEmblemData emblemFor(String id) {
    for (final emblem in emblems) {
      if (emblem.id == id) return emblem;
    }
    return emblems.first;
  }

  static FlagMotionData motionFor(String id) {
    for (final motion in motions) {
      if (motion.id == id) return motion;
    }
    return motions.first;
  }

  static FlagPreset? presetFor(String id) {
    for (final preset in presets) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  /// The effective primary colour: the traveller's own hex when they picked
  /// one, otherwise the theme's.
  static Color primaryColor(FlagStyle style) {
    final override = colorFromHex(style.color);
    return override ?? themeFor(style.theme).primary;
  }

  /// Cloth gradient: primary (possibly overridden) → theme secondary → accent.
  static List<Color> clothGradient(FlagStyle style) {
    final theme = themeFor(style.theme);
    return [primaryColor(style), theme.secondary, theme.accent];
  }

  /// Readable ink for text or glyphs drawn on [background]. Picks whichever of
  /// near-black or white has the higher WCAG contrast, so mid-tone accents such
  /// as pirate gold get dark ink instead of weak white ink.
  static Color foregroundOn(Color background) {
    const dark = Color(0xFF0F172A);
    final luminance = background.computeLuminance();
    final darkContrast = (luminance + 0.05) / (0.0106 + 0.05);
    final lightContrast = 1.05 / (luminance + 0.05);
    return darkContrast >= lightContrast ? dark : const Color(0xFFFFFFFF);
  }

  static Color? colorFromHex(String? hex) {
    final normalized = FlagStyle.normalizeHex(hex);
    if (normalized == null) return null;
    return Color(int.parse(normalized.substring(1), radix: 16) | 0xFF000000);
  }

  /// `#RRGGBB` for a colour, for storing a swatch selection.
  static String hexOf(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Repairs a loosely built style (hand-written or from a cache) without
  /// throwing: unknown ids become defaults, the colour is canonicalised and
  /// the speed is clamped.
  static FlagStyle normalize(FlagStyle style) {
    return FlagStyle(
      theme: FlagStyle.knownId(style.theme, FlagStyle.themeIds, FlagStyle.defaultTheme),
      color: FlagStyle.normalizeHex(style.color),
      pattern:
          FlagStyle.knownId(style.pattern, FlagStyle.patternIds, FlagStyle.defaultPattern),
      shape: FlagStyle.knownId(style.shape, FlagStyle.shapeIds, FlagStyle.defaultShape),
      emblem:
          FlagStyle.knownId(style.emblem, FlagStyle.emblemIds, FlagStyle.defaultEmblem),
      motion:
          FlagStyle.knownId(style.motion, FlagStyle.motionIds, FlagStyle.defaultMotion),
      speed: FlagStyle.clampSpeed(style.speed),
    );
  }
}
