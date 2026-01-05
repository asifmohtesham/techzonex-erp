import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dashboard_controller.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Dependency Injection
    final DashboardController controller = Get.put(DashboardController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true, // Common practice in enterprise apps
      ),
      drawer: _buildNavigationDrawer(context, controller),
      body: const Center(
        child: Text(
          'Welcome to the Enterprise Dashboard',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context, DashboardController controller) {
    return Drawer(
      child: Column(
        children: [
          // User Profile Header
          Obx(() => UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                controller.fullName.value.isNotEmpty
                    ? controller.fullName.value[0].toUpperCase()
                    : 'U',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            accountName: Text(
              controller.fullName.value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(controller.userId.value),
          )),

          // Navigation Items
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Overview'),
            onTap: () => Get.back(), // Close drawer
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Inventory'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('HR & Payroll'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {},
          ),
          const Spacer(), // Pushes Logout to the bottom
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: controller.logout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}