import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

/// Root widget of the app: owns the MaterialApp and reacts to theme-mode
/// changes coming from [Providers.themeModeProvider].
class WriportApp extends ConsumerWidget {
  const WriportApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(Providers.themeModeProvider); // dark/light theme mode

    return MaterialApp(
      title: 'Wriport',
      debugShowCheckedModeBanner: false, // to remove the debug banner
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}