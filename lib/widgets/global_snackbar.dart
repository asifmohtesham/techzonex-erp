import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GlobalSnackbar {
  /// Displays a success notification (Green scheme)
  static void showSuccess({
    required String title,
    required String message,
  }) {
    _show(
      title: title,
      message: message,
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      textColor: Colors.green,
      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
    );
  }

  /// Displays an error notification (Red scheme)
  static void showError({
    required String title,
    required String message,
  }) {
    _show(
      title: title,
      message: message,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
      textColor: Colors.red,
      icon: const Icon(Icons.error_outline, color: Colors.red),
    );
  }

  /// Displays an informational notification (Blue scheme)
  static void showInfo({
    required String title,
    required String message,
  }) {
    _show(
      title: title,
      message: message,
      backgroundColor: Colors.blue.withValues(alpha: 0.1),
      textColor: Colors.blue,
      icon: const Icon(Icons.info_outline, color: Colors.blue),
    );
  }

  /// Internal generic method to construct the Get.snackbar
  static void _show({
    required String title,
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required Icon icon,
  }) {
    // Dismiss if a snackbar is already open to prevent stacking spam
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: textColor,
      icon: icon,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      // Explicit Dismiss Action for better UX
      mainButton: TextButton(
        onPressed: () {
          if (Get.isSnackbarOpen) Get.back();
        },
        child: Text(
          'Dismiss',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}