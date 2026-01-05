import 'package:get/get.dart';
import 'package:flutter/material.dart';

class LoginController extends GetxController {
  final emailOrPhoneController = TextEditingController();
  final passwordController = TextEditingController();

  // Observables for state management
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var errorMessage = ''.obs;

  // Validation Regex Patterns
  final RegExp _emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  final RegExp _phoneRegex = RegExp(r'^\+?[0-9]{10,15}$'); // Supports international format
  final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9]+$'); // Alphanumeric only

  // Password: At least 1 letter, 1 number, 1 special char, min 8 chars
  final RegExp _passwordStrictRegex = RegExp(r'^(?=.*[a-zA-Z])(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$');

  /// Determines the input type and validates accordingly
  String? validateUserField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your username, phone, or email';
    }

    // Dynamic switching of validation logic based on input pattern
    if (value.contains('@')) {
      // Input function: Email
      if (!_emailRegex.hasMatch(value)) return 'Invalid email address format';
    } else if (RegExp(r'^[0-9+]+$').hasMatch(value)) {
      // Input function: Phone
      if (!_phoneRegex.hasMatch(value)) return 'Phone number must be 10-15 digits';
    } else {
      // Input function: Alphanumeric Username
      if (!_usernameRegex.hasMatch(value)) return 'Username must be alphanumeric only';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (!_passwordStrictRegex.hasMatch(value)) {
      return 'Password must contain letters, numbers, and a special character';
    }
    return null;
  }

  Future<void> login() async {
    // Reset previous errors
    errorMessage.value = '';

    if (!Get.nestedKey(1)!.currentState!.validate()) {
      return; // Stop if form is invalid
    }

    isLoading.value = true;

    try {
      // Simulation of ERPNext API Call
      // Endpoint: POST /api/method/login
      // Body: { "usr": emailOrPhoneController.text, "pwd": passwordController.text }

      await Future.delayed(const Duration(seconds: 2)); // Simulating network delay

      // Mock Success
      Get.snackbar('Success', 'Logged in successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green
      );

      // Navigate to Dashboard
      // Get.offAllNamed('/home');

    } catch (e) {
      // Descriptive error handling for the user
      errorMessage.value = 'Connection failed. Please check your internet or credentials.';
    } finally {
      isLoading.value = false;
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  @override
  void onClose() {
    emailOrPhoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}