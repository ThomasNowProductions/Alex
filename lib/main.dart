import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'components/chat_screen.dart';
import 'constants/app_theme.dart';
import 'constants/app_constants.dart';
import 'services/settings_service.dart';
import 'utils/logger.dart';

void main() async {
  await dotenv.load(fileName: AppConstants.envFileName);
  AppLogger.init();
  await SettingsService.loadSettings();
  runApp(const FraintedApp());
}

class FraintedApp extends StatefulWidget {
  const FraintedApp({super.key});

  @override
  State<FraintedApp> createState() => _FraintedAppState();
}

class _FraintedAppState extends State<FraintedApp> {
  late Stream<String> _themeStream;

  @override
  void initState() {
    super.initState();
    _themeStream = SettingsService.themeChangeStream;
  }

  ThemeMode _getThemeMode() {
    final themeMode = SettingsService.themeMode;
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _themeStream,
      builder: (context, snapshot) {
        return MaterialApp(
          title: AppConstants.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _getThemeMode(),
          home: const ChatScreen(),
        );
      },
    );
  }
}
