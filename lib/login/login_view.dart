import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart';

class LoginView extends StatelessWidget {
  final LoginController controller = Get.put(LoginController());

  LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Minimalist AppBar for Configuration Actions
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            tooltip: 'Configure Server',
            onPressed: () => _showServerDialog(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: controller.loginFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // USERNAME / EMAIL / PHONE FIELD
                TextFormField(
                  controller: controller.emailOrPhoneController,
                  // Use email keyboard to support @ (email), numbers (phone), and text (username)
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Username, Phone, or Email',
                    hintText: 'Enter your credentials',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: controller.validateUserField,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 20),

                // PASSWORD FIELD
                Obx(() => TextFormField(
                  controller: controller.passwordController,
                  obscureText: !controller.isPasswordVisible.value,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isPasswordVisible.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  ),
                  validator: controller.validatePassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                )),

                const SizedBox(height: 10),

                // ERROR MESSAGE DISPLAY
                Obx(() => controller.errorMessage.isNotEmpty
                    ? Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                )
                    : const SizedBox.shrink()
                ),

                const SizedBox(height: 10),

                // LOGIN BUTTON
                Obx(() => SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    // Logic is simplified: Controller handles validation check
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.login,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Best UX: Use a dialog to keep context, rather than navigating away
  void _showServerDialog(BuildContext context) {
    Get.defaultDialog(
      title: 'Server Configuration',
      titlePadding: const EdgeInsets.only(top: 20),
      contentPadding: const EdgeInsets.all(24),
      radius: 8,
      content: Column(
        children: [
          const Text(
            'Enter the URL of your ERPNext instance.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: controller.serverUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'https://example.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.dns_outlined),
              isDense: true,
            ),
          ),
        ],
      ),
      confirm: SizedBox(
        width: 120,
        child: ElevatedButton(
          onPressed: controller.configureServerUrl,
          child: const Text('Save'),
        ),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    );
  }
}