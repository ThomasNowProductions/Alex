import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'components/chat_screen.dart';
import 'constants/app_theme.dart';
import 'constants/app_constants.dart';

void main() async {
  await dotenv.load(fileName: AppConstants.envFileName);
  runApp(const FraintedApp());
}

class FraintedApp extends StatelessWidget {
  const FraintedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const ChatScreen(),
    );
  }
}
