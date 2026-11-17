import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/preferences_provider.dart';
import 'core/services/teritory_data_service.dart';
import 'core/services/api_service.dart';
import 'core/theme/teritory_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TeritoryApiService.instance.init();
  await PreferenceStore.instance.init();
  await TeritoryDataService.instance.initialize();
  runApp(const ProviderScope(child: TeritoryApp()));
}

class TeritoryApp extends ConsumerWidget {
  const TeritoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Teritory',
      debugShowCheckedModeBanner: false,
      theme: TeritoryTheme.lightTheme,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
