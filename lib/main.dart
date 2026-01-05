import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techzonex_erp/login/login_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // using GetMaterialApp is essential for GetX navigation and snackbars
    return GetMaterialApp(
      title: 'ERPNext Enterprise App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Enterprise-grade standard blue theme
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        // Global input decoration theme for consistency
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      // Sets the LoginView as the initial screen
      home: LoginView(),
    );
  }
}
