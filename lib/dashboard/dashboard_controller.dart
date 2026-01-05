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
  void navigateToDocTypeList(String module, String docType) {
    Get.back(); // Close Drawer

    FrappeListConfig config;

    switch (docType) {
    // --- Accounting ---
      case 'Sales Invoice':
      case 'Purchase Invoice':
        config = FrappeListConfig(titleField: 'customer_name', subtitleField: 'grand_total', statusField: 'status');
        break;
      case 'Journal Entry':
        config = FrappeListConfig(titleField: 'voucher_type', subtitleField: 'posting_date', statusField: 'docstatus');
        break;
      case 'Payment Entry':
        config = FrappeListConfig(titleField: 'party_name', subtitleField: 'paid_amount', statusField: 'payment_type');
        break;

    // --- Stock ---
      case 'Item':
        config = FrappeListConfig(titleField: 'item_name', subtitleField: 'item_code', imageField: 'image');
        break;
      case 'Material Request':
        config = FrappeListConfig(titleField: 'transaction_date', subtitleField: 'schedule_date');
        break;
      case 'Stock Entry':
        config = FrappeListConfig(titleField: 'stock_entry_type', subtitleField: 'purpose');
        break;
      case 'Delivery Note':
      case 'Purchase Receipt':
        config = FrappeListConfig(titleField: 'customer_name', subtitleField: 'grand_total');
        break;

    // --- Buying & Selling ---
      case 'Customer':
        config = FrappeListConfig(titleField: 'customer_name', subtitleField: 'customer_group', imageField: 'image');
        break;
      case 'Supplier':
        config = FrappeListConfig(titleField: 'supplier_name', subtitleField: 'supplier_group', imageField: 'image');
        break;
      case 'Quotation':
      case 'Sales Order':
      case 'Purchase Order':
      case 'Purchase Request':
        config = FrappeListConfig(titleField: 'transaction_date', subtitleField: 'grand_total');
        break;

    // --- HR ---
      case 'Employee':
        config = FrappeListConfig(titleField: 'employee_name', subtitleField: 'department', imageField: 'image');
        break;
      case 'Leave Application':
        config = FrappeListConfig(titleField: 'employee_name', subtitleField: 'leave_type');
        break;
      case 'Expense Claim':
        config = FrappeListConfig(titleField: 'employee_name', subtitleField: 'total_claimed_amount');
        break;
      case 'Attendance':
        config = FrappeListConfig(titleField: 'employee_name', subtitleField: 'attendance_date', statusField: 'status');
        break;

    // --- CRM ---
      case 'Lead':
        config = FrappeListConfig(titleField: 'lead_name', subtitleField: 'company_name', statusField: 'status');
        break;
      case 'Opportunity':
        config = FrappeListConfig(titleField: 'customer_name', subtitleField: 'opportunity_amount');
        break;
      case 'Contact':
        config = FrappeListConfig(titleField: 'first_name', subtitleField: 'email_id', statusField: 'status');
        break;

    // --- Projects ---
      case 'Project':
        config = FrappeListConfig(titleField: 'project_name', subtitleField: 'percent_complete', statusField: 'status');
        break;
      case 'Task':
        config = FrappeListConfig(titleField: 'subject', subtitleField: 'exp_end_date', statusField: 'status');
        break;
      case 'Timesheet':
        config = FrappeListConfig(titleField: 'employee_name', subtitleField: 'total_hours', statusField: 'status');
        break;

    // --- Support ---
      case 'Issue':
        config = FrappeListConfig(titleField: 'subject', subtitleField: 'raised_by', statusField: 'status');
        break;

      default:
      // Default fallback: assumes standard 'name' and 'modified' fields exist
        config = FrappeListConfig();
    }

    // Pass the tailored config to the Global ListView
    Get.to(() => FrappeListView(docType: docType, config: config));
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