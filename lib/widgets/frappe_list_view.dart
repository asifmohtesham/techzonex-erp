import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techzonex_erp/services/api_service.dart';
import 'package:techzonex_erp/widgets/global_snackbar.dart';
import 'package:techzonex_erp/widgets/frappe_form_view.dart';

/// Configuration class to map DocType fields to UI elements dynamically
class FrappeListConfig {
  String titleField;
  String subtitleField;
  String? statusField; // Nullable: Not all docs have status
  String? imageField;  // Nullable: Not all docs have images

  FrappeListConfig({
    this.titleField = 'name',
    this.subtitleField = 'modified',
    this.statusField, // Defaults to null to prevent "Field not permitted" errors
    this.imageField, // Defaults to null
  });
}

/// Helper Class for Global Status Handling (Separation of Concerns)
class FrappeStatusHelper {
  /// Parses dynamic status values (int or String) into a displayable label
  static String getLabel(dynamic value) {
    if (value == null) return '';

    // Handle standard ERPNext DocStatus integers
    if (value is int) {
      switch (value) {
        case 0: return 'Draft';
        case 1: return 'Submitted';
        case 2: return 'Cancelled';
        default: return value.toString();
      }
    }
    // Handle String statuses (e.g., Workflow states)
    return value.toString();
  }

  /// Returns the appropriate color based on the status label
  static Color getColour(String status) {
    switch (status.toLowerCase()) {
    // Success / Good State
      case 'paid':
      case 'completed':
      case 'active':
      case 'converted':
      case 'submitted':
        return Colors.green;
    // Info / Neutral State
      case 'open':
      case 'draft':
      case 'pending':
      case 'partly paid':
        return Colors.orange;
    // Danger / Bad State
      case 'overdue':
      case 'unpaid':
      case 'cancelled':
      case 'suspended':
      case 'error':
        return Colors.red;
    // Default
      default:
        return Colors.grey;
    }
  }
}

/// A Generic Controller handling Pagination, Pull-to-Refresh, and Dynamic Fetching
class FrappeListController extends GetxController {
  final String docType;
  final ApiService _apiService = Get.find();

  // Config is now an observable that starts with defaults
  var config = FrappeListConfig().obs;

  var itemList = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs; // Starts true for metadata fetch
  var isMoreLoading = false.obs;

  // Pagination State
  int _limitStart = 0;
  final int _pageLength = 20;
  bool _hasReachedEnd = false;

  final ScrollController scrollController = ScrollController();

  FrappeListController({required this.docType});

  @override
  void onInit() {
    super.onInit();
    _initData();
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> _initData() async {
    isLoading.value = true;
    await fetchMeta();
    await fetchItems(isRefresh: true);
    isLoading.value = false;
  }

  /// 1. Fetch DocType Metadata to configure the UI dynamically
  Future<void> fetchMeta() async {
    try {
      final response = await _apiService.get('/api/resource/DocType/$docType');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];

        final newConfig = FrappeListConfig();

        // 1. Title Field
        if (data['title_field'] != null) {
          newConfig.titleField = data['title_field'];
        }

        // 2. Image Field
        if (data['image_field'] != null) {
          newConfig.imageField = data['image_field'];
        }

        // 3. Status Field Logic
        // If submittable, standard status is 'docstatus' (int).
        // Otherwise, check if a 'status' field exists in the field list.
        bool isSubmittable = data['is_submittable'] == 1;
        if (isSubmittable) {
          newConfig.statusField = 'docstatus';
        } else {
          // Check fields list for 'status'
          List<dynamic> fields = data['fields'] ?? [];
          var hasStatus = fields.any((f) => f['fieldname'] == 'status');
          if (hasStatus) {
            newConfig.statusField = 'status';
          }
        }

        // 4. Subtitle Field (Heuristic: Use first search field that isn't title)
        if (data['search_fields'] != null) {
          String searchFieldsStr = data['search_fields'];
          List<String> parts = searchFieldsStr.split(',').map((e) => e.trim()).toList();

          for (var field in parts) {
            if (field != 'name' && field != newConfig.titleField) {
              newConfig.subtitleField = field;
              break;
            }
          }
        }

        config.value = newConfig;
      }
    } catch (e) {
      print('Meta fetch error: $e');
      // Fail silently and use defaults
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200 &&
        !isMoreLoading.value &&
        !_hasReachedEnd) {
      fetchItems(isRefresh: false);
    }
  }

  Future<void> fetchItems({bool isRefresh = false}) async {
    if (isRefresh) {
      _limitStart = 0;
      _hasReachedEnd = false;
      // Note: We don't set isLoading=true here if called from _initData
      // to prevent double flickering, but useful for pull-to-refresh.
    } else {
      isMoreLoading.value = true;
    }

    try {
      final currentConfig = config.value;

      final List<String> fields = [
        'name',
        currentConfig.titleField,
        currentConfig.subtitleField,
        if (currentConfig.statusField != null) currentConfig.statusField!,
        if (currentConfig.imageField != null) currentConfig.imageField!,
      ].toSet().toList();

      final response = await _apiService.get(
        '/api/resource/$docType',
        queryParams: {
          'fields': jsonEncode(fields),
          'limit_start': '$_limitStart',
          'limit_page_length': '$_pageLength',
          'order_by': 'modified desc',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['data'];

        if (isRefresh) {
          itemList.assignAll(results.cast<Map<String, dynamic>>());
        } else {
          itemList.addAll(results.cast<Map<String, dynamic>>());
        }

        if (results.length < _pageLength) {
          _hasReachedEnd = true;
        } else {
          _limitStart += _pageLength;
        }
      } else {
        GlobalSnackbar.showError(title: 'API Error', message: 'Failed to fetch $docType list');
      }
    } catch (e) {
      GlobalSnackbar.showError(title: 'Network Error', message: e.toString());
    } finally {
      isMoreLoading.value = false;
    }
  }
}

/// The Reusable View Widget
class FrappeListView extends StatelessWidget {
  final String docType;

  const FrappeListView({super.key,required this.docType,});

  @override
  Widget build(BuildContext context) {
    // Tag is essential to separate state for different DocTypes
    final controller = Get.put(FrappeListController(docType: docType), tag: docType);

    return Scaffold(
      appBar: AppBar(
        title: Text('$docType List'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async => await controller.fetchItems(isRefresh: true),
          child: ListView.separated(
            controller: controller.scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: controller.itemList.length + (controller.isMoreLoading.value ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, index) {
              if (index == controller.itemList.length) {
                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              }
              final item = controller.itemList[index];
              return _buildListItem(item, controller.config.value);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to Form View with NO name (Create Mode)
          final bool? result = await Get.to(() => FrappeFormView(docType: docType));

          // If result is true (saved), refresh the list
          if (result == true) {
            controller.fetchItems(isRefresh: true);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item, FrappeListConfig config) {
    final String title = item[config.titleField] != null ? item[config.titleField].toString() : (item['name'] ?? 'No Title');
    final String subtitle = item[config.subtitleField] != null ? item[config.subtitleField].toString() : '';

    final dynamic rawStatus = config.statusField != null ? item[config.statusField] : null;
    final String statusLabel = FrappeStatusHelper.getLabel(rawStatus);
    final controller = Get.put(FrappeListController(docType: docType), tag: docType);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
        child: Text(
          title.isNotEmpty ? title.substring(0, 1).toUpperCase() : '?',
          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle.isNotEmpty) Text(subtitle),
          if (config.titleField != 'name')
            Text(item['name'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: statusLabel.isNotEmpty
          ? Chip(
        label: Text(statusLabel, style: const TextStyle(fontSize: 10, color: Colors.white)),
        backgroundColor: FrappeStatusHelper.getColour(statusLabel),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      )
          : null,
      // UPDATED onTap: Navigate to Edit Form
      onTap: () async {
        final bool? result = await Get.to(() => FrappeFormView(
          docType: controller.docType, // Use controller's docType context
          name: item['name'], // Pass the document name for fetching
        ));

        // If result is true (updated/deleted), refresh the list
        if (result == true) {
          controller.fetchItems(isRefresh: true);
        }
      },
    );
  }
}