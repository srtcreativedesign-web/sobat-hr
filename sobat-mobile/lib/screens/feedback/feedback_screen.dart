import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// http removed
import 'dart:convert';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../services/storage_service.dart';
import '../../l10n/app_localizations.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'bug';
  File? _screenshot;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _screenshot = File(image.path);
      });
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final token = await StorageService.getToken();

      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Accept'] = 'application/json';

      final formData = FormData.fromMap({
        'subject': _subjectController.text,
        'category': _selectedCategory,
        'description': _descriptionController.text,
      });

      if (_screenshot != null) {
        formData.files.add(
          MapEntry(
            'screenshot',
            await MultipartFile.fromFile(_screenshot!.path),
          ),
        );
      }

      final response = await dio.post(
        '${ApiConfig.baseUrl}/feedbacks',
        data: formData,
      );

      // Dio throws DioException on error status codes by default depending on config,
      // assuming standard usage or 2xx success check:
      if (response.statusCode == 201 && response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.feedbackSuccess),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to submit feedback',
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        final message = e.response?.data['message'] ?? e.message ?? 'Error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.sendFeedback),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Subject Field
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.feedbackSubject,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.required;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.feedbackCategory,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'bug',
                  child: Text(AppLocalizations.of(context)!.feedbackBug),
                ),
                DropdownMenuItem(
                  value: 'feature_request',
                  child: Text(AppLocalizations.of(context)!.feedbackFeature),
                ),
                DropdownMenuItem(
                  value: 'complaint',
                  child: Text(AppLocalizations.of(context)!.feedbackComplaint),
                ),
                DropdownMenuItem(
                  value: 'question',
                  child: Text(AppLocalizations.of(context)!.feedbackQuestion),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text(AppLocalizations.of(context)!.feedbackOther),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.feedbackDescription,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.required;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Screenshot Attachment
            InkWell(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      _screenshot != null
                          ? Icons.check_circle
                          : Icons.attach_file,
                      color: _screenshot != null
                          ? Colors.green
                          : AppTheme.textLight,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _screenshot != null
                            ? _screenshot!.path.split('/').last
                            : AppLocalizations.of(context)!.feedbackScreenshot,
                        style: TextStyle(
                          color: _screenshot != null
                              ? AppTheme.textDark
                              : AppTheme.textLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_screenshot != null)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() => _screenshot = null);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colorCyan,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.feedbackSubmit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
