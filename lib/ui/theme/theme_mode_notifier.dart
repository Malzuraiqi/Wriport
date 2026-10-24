import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the current theme mode (system / light / dark).
/// 
/// Split from AppTheme so the theme *definition* (colors, widget styles)
/// and the theme *mode state* are separate concerns; AppTheme is now a
/// pure static theme builder.

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.dark;
  }
  
  void changeTheme(ThemeMode mode) {
    state = mode;
  }
}