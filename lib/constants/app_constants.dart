/// Application-wide constants
import 'package:flutter/material.dart';

/// Application-wide constants

class AppConstants {
  /// App metadata
  static const String appTitle = 'Alex - AI Companion';
  static const String appName = 'Alex';

  /// Speech recognition constants
  static const Duration speechListenDuration = Duration(seconds: 30);
  static const Duration speechPauseDuration = Duration(seconds: 5);

  /// Animation durations
  static const Duration snackbarAnimationDuration = Duration(milliseconds: 300);
  static const Duration snackbarShowDuration = Duration(seconds: 4);

  /// Message limits for summarization
  static const int summarizationThreshold = 10;
  static const int summarizationUpdateThreshold = 25;
  static const int maxMessagesForContext = 50;

  /// UI spacing and sizing
  static const double chatBubbleMaxWidth = 0.8;
  static const double glowEffectWidth = 180;
  static const EdgeInsets inputPadding = EdgeInsets.all(20);
  static const EdgeInsets messageMargin = EdgeInsets.only(bottom: 24);

  /// File names
  static const String conversationContextFile = 'conversation_context.json';
  static const String envFileName = 'assets/.env';
}