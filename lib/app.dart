import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wriport/router.dart';

import 'providers.dart';
import 'ui/theme/app_theme.dart';

/// Root widget of the app: owns the MaterialApp and reacts to theme-mode
/// changes coming from [Providers.themeModeProvider]. Navigation is
/// declarative via go_router (see [AppRouter]).
class WriportApp extends ConsumerWidget {
  const WriportApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(Providers.themeModeProvider); // dark/light theme mode
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Wriport',
      debugShowCheckedModeBanner: false, // to remove the debug banner
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
