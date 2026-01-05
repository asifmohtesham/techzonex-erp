import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart';

class LoginView extends StatelessWidget {
  final LoginController controller = Get.put(LoginController());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Key for validation

  LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey, // Assign the key to the Form
            id: 1, // GetX nested key for validation access
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
                    onPressed: controller.isLoading.value
                        ? null
                        : () {
                      if (_formKey.currentState!.validate()) {
                        controller.login();
                      }
                    },
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
}