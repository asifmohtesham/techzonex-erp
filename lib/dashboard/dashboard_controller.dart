import 'package:get/get.dart';
import 'package:techzonex_erp/login/login_view.dart';
import 'package:techzonex_erp/widgets/global_snackbar.dart';

class DashboardController extends GetxController {
  // Observables for User Profile
  var fullName = ''.obs;
  var userId = ''.obs;

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

  void logout() {
    // In a real enterprise app, clear tokens/storage here
    Get.offAll(() => LoginView());
    GlobalSnackbar.showInfo(
      title: 'Session Ended',
      message: 'You have been logged out successfully.',
    );
  }
}