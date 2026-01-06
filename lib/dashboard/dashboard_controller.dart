import 'package:flutter/material.dart'; // Added for Icons/Colours if needed in logic, though mostly for View
import 'package:get/get.dart';
import 'package:techzonex_erp/widgets/frappe_list_view.dart';
import 'package:techzonex_erp/login/login_view.dart';
import 'package:techzonex_erp/widgets/global_snackbar.dart';

class DashboardController extends GetxController {
  // Observables for User Profile
  var fullName = ''.obs;
  var userId = ''.obs;

  // State to track if the User Profile menu is expanded
  var isAccountMenuExpanded = false.obs;

  // Data: Standard ERPNext Modules & DocTypes
  final Map<String, List<String>> erpModules = {
    'Accounting': ['Journal Entry', 'Sales Invoice', 'Purchase Invoice', 'Payment Entry'],
    'Stock': ['Item', 'Material Request', 'Stock Entry', 'Delivery Note', 'Purchase Receipt'],
    'Buying': ['Supplier', 'Purchase Order', 'Purchase Request'],
    'Selling': ['Customer', 'Quotation', 'Sales Order'],
    'HR': ['Employee', 'Leave Application', 'Expense Claim', 'Attendance'],
    'CRM': ['Lead', 'Opportunity', 'Contact'],
    'Projects': ['Project', 'Task', 'Timesheet'],
    'Support': ['Issue', 'Warranty Claim'],
  };

  // UI: Module Icons Mapping
  final Map<String, IconData> moduleIcons = {
    'Accounting': Icons.account_balance_wallet_outlined,
    'Stock': Icons.inventory_2_outlined,
    'Buying': Icons.shopping_bag_outlined,
    'Selling': Icons.sell_outlined,
    'HR': Icons.people_outline,
    'CRM': Icons.groups_outlined,
    'Projects': Icons.rocket_launch_outlined,
    'Support': Icons.support_agent_outlined,
  };

  @override
  void onInit() {
    super.onInit();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    // Retrieve arguments passed from LoginController
    if (Get.arguments != null && Get.arguments is Map) {
      final args = Get.arguments as Map<String, dynamic>;
      fullName.value = args['full_name'] ?? 'Guest User';
      userId.value = args['user_id'] ?? '';
    }
  }

  /// Toggles the visibility of account-specific drawer items
  void toggleAccountMenu() {
    isAccountMenuExpanded.value = !isAccountMenuExpanded.value;
  }

  /// Navigation Handler for DocTypes
  /// Maps specific DocTypes to relevant UI configurations for the Generic ListView
  /// Updated Navigation: Just pass the DocType, the View handles the config!
  void navigateToDocTypeList(String module, String docType) {
    Get.back(); // Close Drawer
    Get.to(() => FrappeListView(docType: docType));
  }

  // --- Profile Context Actions ---

  void navigateToProfile() {
    // Placeholder for future implementation
    GlobalSnackbar.showInfo(title: 'Navigation', message: 'Profile module not implemented yet.');
  }

  void openSessionDefaults() {
    // Placeholder: Could open a Dialog or BottomSheet
    GlobalSnackbar.showInfo(title: 'Settings', message: 'Session Defaults module not implemented yet.');
  }

  void showAboutDialog() {
    Get.defaultDialog(
      title: "About TechZoneX ERP",
      middleText: "Enterprise Resource Planning Solution\nVersion 1.0.0",
      textConfirm: "OK",
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(),
    );
  }

  void logout() {
    // In a real enterprise app, clear tokens/storage here
    Get.offAll(() => LoginView());
    GlobalSnackbar.showInfo(
      title: 'Session Ended',
      message: 'You have been logged out successfully.',
    );
  }
}