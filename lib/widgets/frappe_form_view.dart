import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:techzonex_erp/services/api_service.dart';
import 'package:techzonex_erp/widgets/global_snackbar.dart';

class FrappeFormController extends GetxController {
  final String docType;
  final String? name; // If null, we are in 'Create' mode
  final ApiService _apiService = Get.find();

  var isLoading = true.obs;
  var isSaving = false.obs;

  // Stores the field definitions from DocType
  var fieldsMeta = <Map<String, dynamic>>[].obs;

  // Stores the actual values of the form
  var formValues = <String, dynamic>{}.obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  FrappeFormController({required this.docType, this.name});

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  Future<void> _initData() async {
    isLoading.value = true;
    try {
      // 1. Fetch Metadata to build the UI
      await _fetchMeta();

      // 2. If editing, fetch existing document data
      if (name != null) {
        await _fetchDoc();
      } else {
        // Set defaults for new docs if necessary
        _setDefaults();
      }
    } catch (e) {
      GlobalSnackbar.showError(title: 'Error', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchMeta() async {
    final response = await _apiService.get('/api/resource/DocType/$docType');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      List<dynamic> rawFields = data['fields'];

      // Filter supported field types only
      fieldsMeta.value = rawFields.cast<Map<String, dynamic>>().where((f) {
        final type = f['fieldtype'];
        // Add more types as needed (e.g., 'Link', 'Text Editor')
        return ['Data', 'Select', 'Check', 'Int', 'Float', 'Currency', 'Date', 'Small Text', 'Text'].contains(type)
            && (f['hidden'] != 1);
      }).toList();
    }
  }

  Future<void> _fetchDoc() async {
    final response = await _apiService.get('/api/resource/$docType/$name');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      formValues.addAll(data);
    }
  }

  void _setDefaults() {
    // Loop through fields and set default values if configured in meta
    for (var field in fieldsMeta) {
      if (field.containsKey('default')) {
        formValues[field['fieldname']] = field['default'];
      }
    }
  }

  /// Handles both Create (POST) and Update (PUT)
  Future<void> saveDoc() async {
    if (!formKey.currentState!.validate()) return;
    formKey.currentState!.save();

    isSaving.value = true;
    try {
      http.Response response;

      // Filter out nulls to avoid sending unnecessary data
      final Map<String, dynamic> payload = Map.from(formValues)..removeWhere((k, v) => v == null);

      if (name == null) {
        // CREATE
        response = await _apiService.post('/api/resource/$docType', body: jsonEncode(payload));
      } else {
        // UPDATE
        response = await _apiService.put('/api/resource/$docType/$name', body: jsonEncode(payload));
      }

      if (response.statusCode == 200) {
        GlobalSnackbar.showSuccess(title: 'Success', message: 'Document saved successfully');
        Get.back(result: true); // Return true to trigger list refresh
      } else {
        _handleError(response);
      }
    } catch (e) {
      GlobalSnackbar.showError(title: 'Exception', message: e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteDoc() async {
    if (name == null) return;

    // Confirmation Dialog
    Get.defaultDialog(
        title: 'Confirm Delete',
        middleText: 'Are you sure you want to delete this document?',
        textConfirm: 'Delete',
        confirmTextColor: Colors.white,
        buttonColor: Colors.red,
        onConfirm: () async {
          Get.back(); // Close dialog
          isSaving.value = true;
          try {
            final response = await _apiService.delete('/api/resource/$docType/$name');
            if (response.statusCode == 202 || response.statusCode == 200) {
              GlobalSnackbar.showSuccess(title: 'Deleted', message: 'Document deleted.');
              Get.back(result: true); // Back to list
              Get.back(result: true); // Back to previous screen (if double stacked)
            } else {
              _handleError(response);
            }
          } catch (e) {
            GlobalSnackbar.showError(title: 'Error', message: e.toString());
          } finally {
            isSaving.value = false;
          }
        }
    );
  }

  void _handleError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      // ERPNext usually sends errors in 'exception' or '_server_messages'
      String msg = body['exception'] ?? 'Unknown Error';
      // Clean up python tracebacks for UI
      if (msg.contains(':')) msg = msg.split(':').last.trim();
      GlobalSnackbar.showError(title: 'Server Error', message: msg);
    } catch (_) {
      GlobalSnackbar.showError(title: 'Error', message: 'Status Code: ${response.statusCode}');
    }
  }
}

class FrappeFormView extends StatelessWidget {
  final String docType;
  final String? name;

  const FrappeFormView({super.key, required this.docType, this.name});

  @override
  Widget build(BuildContext context) {
    // Unique tag to prevent controller conflicts
    final controller = Get.put(FrappeFormController(docType: docType, name: name), tag: '${docType}_${name ?? "new"}');

    return Scaffold(
      appBar: AppBar(
        title: Text(name ?? 'New $docType'),
        actions: [
          if (name != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: controller.deleteDoc,
            ),
          Obx(() => IconButton(
            icon: controller.isSaving.value
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            onPressed: controller.isSaving.value ? null : controller.saveDoc,
          ))
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Form(
          key: controller.formKey,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.fieldsMeta.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (ctx, index) {
              final field = controller.fieldsMeta[index];
              return _buildDynamicField(field, controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildDynamicField(Map<String, dynamic> field, FrappeFormController controller) {
    final String fieldType = field['fieldtype'];
    final String label = field['label'];
    final String fieldName = field['fieldname'];
    final bool isReqd = field['reqd'] == 1;

    // 1. SELECT FIELD (Robust Fix)
    if (fieldType == 'Select') {
      // Parse options, trim whitespace, and remove empty entries
      List<String> options = (field['options'] ?? '')
          .toString()
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Retrieve the current value from the controller
      String? currentValue = controller.formValues[fieldName]?.toString();

      // CRITICAL FIX: Ensure currentValue exists in the options list.
      // If the backend sends a value (e.g., 'EMP/') that isn't in the options list,
      // we must add it temporarily to prevent the "exactly one item" crash.
      if (currentValue != null &&
          currentValue.isNotEmpty &&
          !options.contains(currentValue)) {
        options.add(currentValue);
      }

      // If options are completely empty (edge case), add a placeholder to prevent crash
      if (options.isEmpty) {
        return TextFormField(
          initialValue: currentValue,
          decoration: InputDecoration(labelText: label, helperText: 'No options defined'),
          readOnly: true,
        );
      }

      // Ensure value is null if it's an empty string not in options
      if (currentValue == '') currentValue = null;

      return DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label),
        value: currentValue,
        items: options.map((opt) {
          return DropdownMenuItem<String>(
            value: opt,
            child: Text(opt),
          );
        }).toList(),
        onChanged: (val) => controller.formValues[fieldName] = val,
        validator: (val) => isReqd && (val == null || val.isEmpty) ? 'Required' : null,
      );
    }

    // 2. CHECKBOX (Check)
    if (fieldType == 'Check') {
      // ERPNext stores Check as 0 or 1
      bool isChecked = (controller.formValues[fieldName] == 1 || controller.formValues[fieldName] == true);
      return SwitchListTile(
        title: Text(label),
        value: isChecked,
        onChanged: (val) => controller.formValues[fieldName] = val ? 1 : 0,
      );
    }

    // 3. DATE FIELD
    if (fieldType == 'Date') {
      final TextEditingController dateCtrl = TextEditingController(
          text: controller.formValues[fieldName]?.toString() ?? ''
      );
      return TextFormField(
        controller: dateCtrl,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        readOnly: true,
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: Get.context!,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            // Format: YYYY-MM-DD
            String formatted = "${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}";
            dateCtrl.text = formatted;
            controller.formValues[fieldName] = formatted;
          }
        },
        validator: (val) => isReqd && (val == null || val.isEmpty) ? 'Required' : null,
      );
    }

    // 4. NUMERIC FIELDS
    if (['Int', 'Float', 'Currency'].contains(fieldType)) {
      return TextFormField(
        initialValue: controller.formValues[fieldName]?.toString(),
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onSaved: (val) => controller.formValues[fieldName] = val, // ERPNext handles string-to-number often, but ideally parse here
        validator: (val) => isReqd && (val == null || val.isEmpty) ? 'Required' : null,
      );
    }

    // 5. STANDARD TEXT (Data, Text, Small Text)
    return TextFormField(
      initialValue: controller.formValues[fieldName]?.toString(),
      decoration: InputDecoration(labelText: label),
      maxLines: fieldType == 'Small Text' || fieldType == 'Text' ? 3 : 1,
      onSaved: (val) => controller.formValues[fieldName] = val,
      validator: (val) => isReqd && (val == null || val.isEmpty) ? 'Required' : null,
    );
  }
}