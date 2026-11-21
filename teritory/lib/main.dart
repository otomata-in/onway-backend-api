import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/preferences_provider.dart';
import 'core/services/api_service.dart';
import 'core/services/pending_flag_store.dart';
import 'core/theme/teritory_theme.dart';
import 'core/router/app_router.dart';
import 'features/flag/application/flag_queue_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TeritoryApiService.instance.init();
  await PreferenceStore.instance.init();
  // The offline flag queue is read synchronously by providers, so it loads
  // before the first frame like the other device-local stores.
  await PendingFlagStore.instance.init();
  runApp(const ProviderScope(child: TeritoryApp()));
}

class TeritoryApp extends ConsumerWidget {
  const TeritoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No route shows the whole app, so the queue drains on reconnect and on
    // resume from here rather than from a screen.
    return FlagQueueSyncScope(
      child: MaterialApp.router(
        title: 'Teritory',
        debugShowCheckedModeBanner: false,
        theme: TeritoryTheme.lightTheme,
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}
