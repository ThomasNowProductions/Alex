import 'dart:io' show Platform;

/// Utility class for platform-specific operations
class PlatformUtils {
  /// Check if the current platform is Android
  static bool get isAndroid => Platform.isAndroid;

  /// Check if the current platform is iOS
  static bool get isIOS => Platform.isIOS;

  /// Check if the current platform is Linux
  static bool get isLinux => Platform.isLinux;

  /// Check if the current platform is macOS
  static bool get isMacOS => Platform.isMacOS;

  /// Check if the current platform is Windows
  static bool get isWindows => Platform.isWindows;

  /// Get the current platform name as a string
  static String get platformName => Platform.operatingSystem;

  /// Check if the current platform supports speech recognition
  static bool get supportsSpeechRecognition {
    return isAndroid || isIOS;
  }

  /// Get platform-specific speech recognition availability message
  static String getSpeechRecognitionMessage() {
    if (isAndroid) {
      return 'Speech recognition available on Android';
    } else if (isIOS) {
      return 'Speech recognition available on iOS';
    } else {
      return 'Speech recognition is not supported on ${Platform.operatingSystem}. Please use an Android or iOS device for voice input features.';
    }
  }
}