import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../widgets/floating_snackbar.dart';

/// Utility class for handling permissions
class PermissionUtils {
  /// Request microphone permission
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    try {
      // Check current permission status first
      await Permission.microphone.status;

      // Request permission
      PermissionStatus status = await Permission.microphone.request();

      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        if (context.mounted) {
          FloatingSnackbar.show(
            context,
            message: 'Microphone permission is required for speech recognition. Please grant permission in app settings.',
            actionLabel: 'Settings',
            onActionPressed: openAppSettings,
            duration: const Duration(seconds: 4),
          );
        }
        return false;
      } else if (status.isPermanentlyDenied) {
        if (context.mounted) {
          FloatingSnackbar.show(
            context,
            message: 'Microphone permission is permanently denied. Please enable it in app settings to use speech recognition.',
            actionLabel: 'Settings',
            onActionPressed: openAppSettings,
            duration: const Duration(seconds: 4),
          );
        }
        return false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Check if microphone permission is granted
  static Future<bool> isMicrophonePermissionGranted() async {
    try {
      PermissionStatus status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }
}