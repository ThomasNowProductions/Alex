import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'components/chat_screen.dart';
import 'constants/app_theme.dart';
import 'constants/app_constants.dart';
import 'services/settings_service.dart';
import 'utils/logger.dart';
import 'widgets/pin_entry_dialog.dart';

/// Widget that wraps the main app content and handles PIN lock
class PinLockWrapper extends StatefulWidget {
  final Widget child;
  final bool showPinDialog;

  const PinLockWrapper({
    super.key,
    required this.child,
    this.showPinDialog = false,
  });

  @override
  State<PinLockWrapper> createState() => _PinLockWrapperState();
}

class _PinLockWrapperState extends State<PinLockWrapper> {
  bool _showPinDialog = false;

  @override
  void initState() {
    super.initState();
    _checkPinLockStatus();
  }

  @override
  void didUpdateWidget(PinLockWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkPinLockStatus();
  }

  void _checkPinLockStatus() {
    final isPinLockEnabled = SettingsService.pinLockEnabled;
    final hasPinCode = SettingsService.pinCode.isNotEmpty;

    AppLogger.d('PIN Lock Status - Enabled: $isPinLockEnabled, Has Code: $hasPinCode');

    if (isPinLockEnabled && hasPinCode && !_showPinDialog) {
      AppLogger.i('PIN lock is active, showing PIN dialog');
      setState(() {
        _showPinDialog = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPinEntryDialog();
      });
    } else if (!isPinLockEnabled || !hasPinCode) {
      AppLogger.d('PIN lock not active, hiding PIN dialog');
      setState(() {
        _showPinDialog = false;
      });
    }
  }

  /// Method to refresh PIN lock status (can be called when settings change)
  void refreshPinLockStatus() {
    _checkPinLockStatus();
  }

  Future<void> _showPinEntryDialog() async {
    final pinCorrect = await showPinEntryDialog(
      context,
      title: 'Welcome Back',
      subtitle: 'Enter your PIN to access the app',
    );

    if (pinCorrect && mounted) {
      setState(() {
        _showPinDialog = false;
      });
    } else if (mounted) {
      // If PIN is incorrect, show error and try again
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Incorrect PIN. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      // Show PIN dialog again after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _showPinEntryDialog();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showPinDialog)
          const PinEntryDialog(
            title: 'Welcome Back',
            subtitle: 'Enter your PIN to access the app',
          ),
      ],
    );
  }
}

void main() async {
  await dotenv.load(fileName: AppConstants.envFileName);
  AppLogger.init();
  await SettingsService.loadSettings();

  // Check if PIN lock is enabled and show PIN entry if needed
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.d('PIN Lock Enabled: ${SettingsService.pinLockEnabled}');
  AppLogger.d('PIN Code Set: ${SettingsService.pinCode.isNotEmpty}');

  runApp(const FraintedApp());
}

class FraintedApp extends StatefulWidget {
  const FraintedApp({super.key});

  @override
  State<FraintedApp> createState() => _FraintedAppState();
}

class _FraintedAppState extends State<FraintedApp> {
  late Stream<String> _themeStream;
  late Stream<String> _colorStream;

  @override
  void initState() {
    super.initState();
    _themeStream = SettingsService.themeChangeStream;
    _colorStream = SettingsService.colorChangeStream;
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
      builder: (context, themeSnapshot) {
        return StreamBuilder<String>(
          stream: _colorStream,
          builder: (context, colorSnapshot) {
            return MaterialApp(
              title: AppConstants.appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: _getThemeMode(),
              home: const PinLockWrapper(
                child: ChatScreen(),
              ),
            );
          },
        );
      },
    );
  }
}
