import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// Application theme configuration
class AppTheme {
  /// Get the primary color based on user settings
  static Color _getPrimaryColor() {
    final colorName = SettingsService.primaryColor;
    switch (colorName) {
      case 'purple':
        return Colors.purple;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'red':
        return Colors.red;
      case 'blue':
      default:
        return Colors.blue;
    }
  }

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _getPrimaryColor(),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _getPrimaryColor(),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }

  /// Custom color scheme for chat messages
  static Color getMessageBackgroundColor(BuildContext context, bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = isLoading ? colorScheme.secondary : colorScheme.primary;

    // Increase the glow opacity slightly for the wait/think state so the
    // feedback remains visible without ignoring the user's theme selection.
    final alpha = isLoading ? 0.16 : 0.12;
    return baseColor.withValues(alpha: alpha);
  }

  /// Custom color scheme for chat message shadows
  static Color getMessageShadowColor(BuildContext context, bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = isLoading ? colorScheme.secondary : colorScheme.primary;

    final alpha = isLoading ? 0.1 : 0.06;
    return baseColor.withValues(alpha: alpha);
  }
}