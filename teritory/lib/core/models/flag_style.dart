import 'dart:convert';

/// A traveller's flag identity: the whole look of a flag in one immutable,
/// JSON-safe value.
///
/// The same object is used by every flag surface (home pins, detail sheet,
/// profile, worldwide map, carousel, search rows and the staking ceremony), so
/// a flag drawn at 36 px uses exactly the vocabulary of the same flag drawn at
/// 320 px.
///
/// [FlagStyle] is a *snapshot* on a flag row: changing a signature later never
/// rewrites flags already staked. The server (`flag_style.js`) is the
/// authority on which ids are legal; [FlagStyle.fromJson] is deliberately
/// lenient because a display layer must never crash on a row it cannot fully
/// understand — an unknown dimension falls back to its product default.
class FlagStyle {
  /// Wire version of this shape. v1 is the only version the client emits.
  static const int currentVersion = 1;

  static const String defaultTheme = 'midnight_tide';
  static const String defaultPattern = 'horizon';
  static const String defaultShape = 'classic';
  static const String defaultEmblem = 'compass';
  static const String defaultMotion = 'breeze';
  static const double defaultSpeed = 1.0;

  static const double minSpeed = 0.5;
  static const double maxSpeed = 2.0;

  /// Canonical ids. The server validator and the visual catalog both use these
  /// exact strings; a contract test keeps the catalog in step.
  static const List<String> themeIds = [
    'midnight_tide',
    'crimson_charge',
    'black_pirate',
    'neon_hacker',
    'rider_steel',
    'golden_summit',
    'emerald_trail',
    'sakura_dusk',
    'desert_mirage',
    'aurora',
    'monochrome_ink',
    // Kept for flags already staked in it, but deliberately last: blue is the
    // product default and the orange family is no longer promoted.
    'coral_expedition',
  ];

  static const List<String> patternIds = [
    'solid',
    'horizon',
    'chevron',
    'tide',
    'sunburst',
    'constellation',
    'topographic',
    'weave',
  ];

  static const List<String> shapeIds = [
    'classic',
    'swallowtail',
    'pennant',
    'burgee',
  ];

  static const List<String> emblemIds = [
    'none',
    'compass',
    'peak',
    'anchor',
    'star',
    'flame',
    'compass_rose',
    'paw',
    // Pirate / hacker / rider identities.
    'skull',
    'terminal',
    'helmet',
    // Bikes and cars, three each so a rider can pick their machine.
    'bike_road',
    'bike_mountain',
    'bike_moto',
    'car_sedan',
    'car_suv',
    'car_sports',
  ];

  static const List<String> motionIds = [
    'still',
    'breeze',
    'gust',
    'ripple',
    'shimmer',
    'aurora',
    // Game-grade motions: heavier wind, embers and a glowing edge.
    'storm',
    'inferno',
    'neon_pulse',
  ];

  /// The product default, used when a traveller has not chosen a style and a
  /// flag row predates the style columns.
  static const FlagStyle fallback = FlagStyle();

  final int version;
  final String theme;

  /// `#RRGGBB` override for the primary cloth colour, or null to use [theme].
  final String? color;
  final String pattern;
  final String shape;
  final String emblem;
  final String motion;

  /// 0.5 (calm) – 2.0 (wild).
  final double speed;

  const FlagStyle({
    this.version = currentVersion,
    this.theme = defaultTheme,
    this.color,
    this.pattern = defaultPattern,
    this.shape = defaultShape,
    this.emblem = defaultEmblem,
    this.motion = defaultMotion,
    this.speed = defaultSpeed,
  });

  bool get hasCustomColor => color != null;

  bool get isAnimated => motion != 'still';

  FlagStyle copyWith({
    int? version,
    String? theme,
    Object? color = _keepColor,
    String? pattern,
    String? shape,
    String? emblem,
    String? motion,
    double? speed,
  }) {
    return FlagStyle(
      version: version ?? this.version,
      theme: theme ?? this.theme,
      color: identical(color, _keepColor) ? this.color : color as String?,
      pattern: pattern ?? this.pattern,
      shape: shape ?? this.shape,
      emblem: emblem ?? this.emblem,
      motion: motion ?? this.motion,
      speed: speed == null ? this.speed : clampSpeed(speed),
    );
  }

  /// Lenient decode. Accepts a map (or a JSON object string) and replaces any
  /// unknown or malformed dimension with its default instead of throwing.
  factory FlagStyle.fromJson(Object? json) {
    Object? source = json;
    if (source is String) {
      try {
        source = jsonDecode(source);
      } catch (_) {
        return fallback;
      }
    }
    if (source is! Map) return fallback;

    final rawSpeed = source['speed'];
    return FlagStyle(
      version: currentVersion,
      theme: knownId(source['theme'], themeIds, defaultTheme),
      color: normalizeHex(source['color']),
      pattern: knownId(source['pattern'], patternIds, defaultPattern),
      shape: knownId(source['shape'], shapeIds, defaultShape),
      emblem: knownId(source['emblem'], emblemIds, defaultEmblem),
      motion: knownId(source['motion'], motionIds, defaultMotion),
      speed: rawSpeed is num ? clampSpeed(rawSpeed.toDouble()) : defaultSpeed,
    );
  }

  /// Canonical wire object. Always reports [currentVersion] and an uppercase
  /// hex override, so equal styles always encode identically.
  Map<String, dynamic> toJson() => {
    'v': currentVersion,
    'theme': theme,
    'color': color,
    'pattern': pattern,
    'shape': shape,
    'emblem': emblem,
    'motion': motion,
    'speed': speed,
  };

  /// True when [raw] is one of [allowed] (case-insensitive); otherwise
  /// [fallbackId].
  static String knownId(Object? raw, List<String> allowed, String fallbackId) {
    if (raw is! String) return fallbackId;
    final value = raw.trim().toLowerCase();
    return allowed.contains(value) ? value : fallbackId;
  }

  /// Normalises `#abc123`, `abc123` and `#ABC123` to `#ABC123`; anything else
  /// (including empty) becomes null, i.e. "use the theme".
  static String? normalizeHex(Object? raw) {
    if (raw is! String) return null;
    var value = raw.trim();
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length != 6) return null;
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) return null;
    return '#${value.toUpperCase()}';
  }

  static double clampSpeed(double value) {
    if (value.isNaN) return defaultSpeed;
    final clamped = value.clamp(minSpeed, maxSpeed);
    // Two decimals keeps JSON and equality stable when a slider reports 1.0001.
    return (clamped * 100).roundToDouble() / 100;
  }

  @override
  bool operator ==(Object other) {
    return other is FlagStyle &&
        other.version == version &&
        other.theme == theme &&
        other.color == color &&
        other.pattern == pattern &&
        other.shape == shape &&
        other.emblem == emblem &&
        other.motion == motion &&
        other.speed == speed;
  }

  @override
  int get hashCode => Object.hash(
    version,
    theme,
    color,
    pattern,
    shape,
    emblem,
    motion,
    speed,
  );

  @override
  String toString() =>
      'FlagStyle(theme: $theme, color: $color, pattern: $pattern, '
      'shape: $shape, emblem: $emblem, motion: $motion, speed: $speed)';
}

/// `copyWith` sentinel: lets `copyWith(color: null)` clear the override while
/// an omitted `color` keeps it.
const Object _keepColor = Object();
