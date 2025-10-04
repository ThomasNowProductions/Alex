import 'package:flutter/material.dart';

/// Application theme configuration
class AppTheme {
  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }

  /// Custom color scheme for chat messages
  static Color getMessageBackgroundColor(BuildContext context, bool isLoading) {
    return isLoading
        ? Colors.blue.withValues(alpha: 0.15)
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);
  }

  /// Custom color scheme for chat message shadows
  static Color getMessageShadowColor(BuildContext context, bool isLoading) {
    return isLoading
        ? Colors.blue.withValues(alpha: 0.08)
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.06);
  }
}