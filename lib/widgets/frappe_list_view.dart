import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techzonex_erp/services/api_service.dart';
import 'package:techzonex_erp/widgets/global_snackbar.dart';

/// Configuration class to map DocType fields to UI elements dynamically
class FrappeListConfig {
  final String titleField;
  final String subtitleField;
  final String statusField;
  final String imageField;

  FrappeListConfig({
    this.titleField = 'name',
    this.subtitleField = 'modified',
    this.statusField = 'status',
    this.imageField = 'image',
  });
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
      // Construct Fields JSON
      final List<String> fields = [
        'name', config.titleField, config.subtitleField, config.statusField, config.imageField
      ].toSet().toList(); // Remove duplicates

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
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => GlobalSnackbar.showInfo(title: 'Action', message: 'Create New $docType'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item, FrappeListConfig config) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
        child: Text(
          (item[config.titleField] ?? '?').toString().substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        item[config.titleField] ?? 'No Title',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (config.subtitleField != 'modified')
            Text(item[config.subtitleField]?.toString() ?? ''),
          Text(
            item['name'], // Always show ID
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      trailing: item[config.statusField] != null
          ? Chip(
        label: Text(
          item[config.statusField],
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        backgroundColor: _getStatusColor(item[config.statusField]),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      )
          : null,
      onTap: () {
        GlobalSnackbar.showInfo(title: 'Details', message: 'Opened ${item['name']}');
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open': return Colors.green;
      case 'submitted': return Colors.blue;
      case 'cancelled': return Colors.red;
      case 'draft': return Colors.orange;
      default: return Colors.grey;
    }
  }
}