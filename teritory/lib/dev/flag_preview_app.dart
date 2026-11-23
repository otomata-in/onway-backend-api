import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/flag_style.dart';
import '../core/theme/flag_style_catalog.dart';
import '../core/theme/teritory_theme.dart';
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
/// `?preset=black_pirate`, `?preset=trail_suv`, `?theme=crimson_charge`,
/// `?studio=1`
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

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Flag Preview',
        debugShowCheckedModeBanner: false,
        theme: TeritoryTheme.lightTheme,
        home: _openStudio
            ? FlagStudioScreen(initialStyle: _initialStyle)
            : FlagPreviewScreen(initialStyle: _initialStyle),
      ),
    );
  }
}
