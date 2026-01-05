import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techzonex_erp/services/api_service.dart';
import 'package:techzonex_erp/widgets/global_snackbar.dart';

/// Configuration class to map DocType fields to UI elements dynamically
class FrappeListConfig {
  final String titleField;
  final String subtitleField;
  final String? statusField; // Nullable: Not all docs have status
  final String? imageField;  // Nullable: Not all docs have images

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
  final FrappeListConfig config;
  final ApiService _apiService = Get.find();

  var itemList = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isMoreLoading = false.obs;

  // Pagination State
  int _limitStart = 0;
  final int _pageLength = 20;
  bool _hasReachedEnd = false;

  final ScrollController scrollController = ScrollController();

  FrappeListController({required this.docType, required this.config});

  @override
  void onInit() {
    super.onInit();
    fetchItems(isRefresh: true);
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
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
      isLoading.value = true;
    } else {
      isMoreLoading.value = true;
    }

    try {
      // Construct Fields List dynamically, filtering out nulls
      final List<String> fields = [
        'name',
        config.titleField,
        config.subtitleField,
        if (config.statusField != null) config.statusField!,
        if (config.imageField != null) config.imageField!,
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
      isLoading.value = false;
      isMoreLoading.value = false;
    }
  }
}

/// The Reusable View Widget
class FrappeListView extends StatelessWidget {
  final String docType;
  final FrappeListConfig? config;

  const FrappeListView({
    super.key,
    required this.docType,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    // Unique Tag to allow multiple list views (e.g. Items and Customers) to exist simultaneously
    final controller = Get.put(
      FrappeListController(
        docType: docType,
        config: config ?? FrappeListConfig(),
      ),
      tag: docType,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('$docType List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => GlobalSnackbar.showInfo(title: 'Filters', message: 'Not implemented yet'),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async => await controller.fetchItems(isRefresh: true),
          child: SafeArea(
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
                return _buildListItem(item, controller.config);
              },
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => GlobalSnackbar.showInfo(title: 'Action', message: 'Create New $docType'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item, FrappeListConfig config) {
    // Use the title field, or fallback to 'name' (ID)
    final String title = item[config.titleField] != null ? item[config.titleField].toString() : (item['name'] ?? 'No Title');
    final String subtitle = item[config.subtitleField] != null ? item[config.subtitleField].toString() : '';

    // SAFE STATUS HANDLING: Fetch as dynamic, then parse via Helper
    final dynamic rawStatus = config.statusField != null ? item[config.statusField] : null;
    final String statusLabel = FrappeStatusHelper.getLabel(rawStatus);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
        child: Text(
          title.isNotEmpty ? title.substring(0, 1).toUpperCase() : '?',
          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle.isNotEmpty) Text(subtitle),
          if (config.titleField != 'name') // Don't duplicate if title is already ID
            Text(
              item['name'],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
      trailing: statusLabel.isNotEmpty
          ? Chip(
        label: Text(
          statusLabel,
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        backgroundColor: FrappeStatusHelper.getColour(statusLabel),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      )
          : null,
      onTap: () {
        GlobalSnackbar.showInfo(title: 'Details', message: 'Opened ${item['name']}');
      },
    );
  }
}