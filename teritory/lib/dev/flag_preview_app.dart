import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../core/models/flag_style.dart';
import '../core/theme/flag_style_catalog.dart';
import '../core/theme/teritory_theme.dart';
import '../features/flag/presentation/epic_flag_staking_ceremony.dart';
import '../features/flag/presentation/flag_preview_screen.dart';
import '../features/flag/presentation/flag_studio_screen.dart';

/// Dev-only entrypoint for reviewing the flag language before it is wired into
/// the app. It is not referenced by `main.dart` or the router.
///
/// Run it with:
/// `flutter run -d chrome --target lib/dev/flag_preview_app.dart`
///
/// Optional query parameters jump straight to a preset, theme or the studio,
/// which is handy on a small viewport:
/// `?preset=pirate_black`, `?preset=trail_suv`, `?theme=crimson_charge`,
/// `?studio=1`, `?ceremony=1` (add `&major=1` for the major-wonder variant)
void main() => runApp(const FlagPreviewApp());

class FlagPreviewApp extends StatelessWidget {
  const FlagPreviewApp({super.key});

  FlagStyle get _initialStyle {
    final params = Uri.base.queryParameters;
    final preset = FlagStyleCatalog.presetFor(params['preset'] ?? '');
    if (preset != null) return preset.style;

    final themeId = params['theme'];
    if (themeId != null &&
        themeId.isNotEmpty &&
        FlagStyle.themeIds.contains(themeId)) {
      return FlagStyle(theme: themeId);
    }
    return FlagStyle.fallback;
  }

  bool get _openStudio => Uri.base.queryParameters['studio'] == '1';

  bool get _openCeremony => Uri.base.queryParameters['ceremony'] == '1';

  Widget get _home {
    if (_openCeremony) {
      final params = Uri.base.queryParameters;
      return EpicFlagStakingCeremony(
        placeName: 'Varkala Cliff',
        city: 'Varkala, Kerala',
        coordinates: const LatLng(8.7379, 76.7163),
        isMajorFlag: params['major'] == '1',
        category: 'Scenic Viewpoint',
        style: _initialStyle,
      );
    }
    if (_openStudio) return FlagStudioScreen(initialStyle: _initialStyle);
    return FlagPreviewScreen(initialStyle: _initialStyle);
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Flag Preview',
        debugShowCheckedModeBanner: false,
        theme: TeritoryTheme.lightTheme,
        home: _home,
      ),
    );
  }
}
