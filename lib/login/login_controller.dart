import 'dart:convert';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginController extends GetxController {
  // Key to access the form state from the View
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  final emailOrPhoneController = TextEditingController();
  final passwordController = TextEditingController();

  // Default to a known instance or empty
  final serverUrlController = TextEditingController(text: 'https://demo.erpnext.com');

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

  /// UX Utility: Auto-corrects URL and saves it
  void configureServerUrl() {
    String url = serverUrlController.text.trim();
    if (url.isEmpty) {
      Get.snackbar('Error', 'Server URL cannot be empty', backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
      return;
    }
    // Auto-append https if missing for better UX
    if (!url.startsWith('http')) {
      url = 'https://$url';
      serverUrlController.text = url;
    }
    // Remove trailing slash to prevent double slashes in API calls
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    serverUrlController.text = url;
    Get.back(); // Close Dialog
    Get.snackbar('Configuration', 'Server connected: $url',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        colorText: Colors.blue
    );
  }

  Future<void> login() async {
    errorMessage.value = '';

    // 1. Input Validation
    if (!loginFormKey.currentState!.validate()) return;

    isLoading.value = true;

    final String baseUrl = serverUrlController.text;
    // ERPNext Standard Login Endpoint
    final Uri uri = Uri.parse('$baseUrl/api/method/login');

    try {
      // 2. Perform API Call
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'usr': emailOrPhoneController.text.trim(),
          'pwd': passwordController.text,
        },
      ).timeout(const Duration(seconds: 10)); // Fail fast on timeout

      // 3. Handle Response
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        // ERPNext login success usually returns: { "message": "Logged In", "full_name": "..." }
        if (body['message'] == 'Logged In') {

          // CRITICAL: Capture Session Cookie (sid) for future requests
          String? rawCookie = response.headers['set-cookie'];
          if (rawCookie != null) {
            // In a real app, store this securely (e.g., flutter_secure_storage)
            print('Session ID captured: $rawCookie');
          }

          Get.snackbar('Success', 'Welcome, ${body['full_name']}',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              colorText: Colors.green
          );

          // Proceed to Dashboard
          // Get.offAllNamed('/home');

        } else {
          errorMessage.value = body['message'] ?? 'Login failed due to an unknown error.';
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        errorMessage.value = 'Invalid credentials. Please check your username and password.';
      } else {
        // Try to parse specific server errors (often in 'exception' field)
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage.value = errorBody['exception'] ?? 'Server Error: ${response.statusCode}';
        } catch (_) {
          errorMessage.value = 'Server Error: ${response.statusCode}. Please try again later.';
        }
      }

    } catch (e) {
      // 4. Handle Network Exceptions
      if (e.toString().contains('SocketException')) {
        errorMessage.value = 'Could not connect to server. Check URL or Internet.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage.value = 'Connection timed out. Server is slow to respond.';
      } else {
        errorMessage.value = 'An unexpected error occurred: $e';
      }
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
    serverUrlController.dispose(); // Dispose new controller
    super.onClose();
  }
}