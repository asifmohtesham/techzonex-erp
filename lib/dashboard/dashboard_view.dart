import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techzonex_erp/dashboard/dashboard_controller.dart';

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
            // Shows arrow icon and handles toggle interaction
            onDetailsPressed: controller.toggleAccountMenu,
          )),

          // Dynamic Menu Content
          Expanded(
            child: Obx(() => controller.isAccountMenuExpanded.value
                ? _buildAccountMenu(controller)
                : _buildMainMenu(controller)),
          ),
        ],
      ),
    );
  }

  /// The Main Navigation (Modules & Overview)
  /// Dynamically builds ExpansionTiles for ERP Modules
  Widget _buildMainMenu(DashboardController controller) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ListTile(
          leading: const Icon(Icons.dashboard_outlined),
          title: const Text('Overview'),
          onTap: () => Get.back(),
        ),
        const Divider(),

        // Iterate through the Modules map defined in the Controller
        ...controller.erpModules.entries.map((entry) {
          final String moduleName = entry.key;
          final List<String> docTypes = entry.value;

          return ExpansionTile(
            leading: Icon(controller.moduleIcons[moduleName] ?? Icons.folder_open),
            title: Text(moduleName),
            childrenPadding: const EdgeInsets.only(left: 16.0),
            children: docTypes.map((docType) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.article_outlined, size: 20, color: Colors.grey),
                title: Text(docType),
                onTap: () => controller.navigateToDocTypeList(moduleName, docType),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  /// The Profile Context Menu (Profile, Settings, Logout)
  Widget _buildAccountMenu(DashboardController controller) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Profile'),
          onTap: controller.navigateToProfile,
        ),
        ListTile(
          leading: const Icon(Icons.tune_outlined),
          title: const Text('Session Defaults'),
          onTap: controller.openSessionDefaults,
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          onTap: controller.showAboutDialog,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.red),
          ),
          onTap: controller.logout,
        ),
      ],
    );
  }
}