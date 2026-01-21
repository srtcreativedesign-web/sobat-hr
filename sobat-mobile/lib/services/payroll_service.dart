import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'storage_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PayrollService {
  late final Dio _dio;

  PayrollService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptor untuk attach token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<List<dynamic>> getPayrolls({int? year}) async {
    List<dynamic> allPayrolls = [];

    // Generic payrolls removed - fetching only division specific data
    // List<dynamic> allPayrolls = [];

    // Try to fetch from FnB endpoint
    try {
      final response = await _dio.get(
        '/payrolls/fnb',
        queryParameters: {if (year != null) 'year': year},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final fnbData = response.data['data'];
        if (fnbData is List) {
          // Mark FnB payrolls with division type
          for (var item in fnbData) {
            if (item is Map<String, dynamic>) {
              item['division'] = 'fnb';
            }
          }
          allPayrolls.addAll(fnbData);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch FnB payrolls: $e');
    }

    // Try to fetch from Minimarket endpoint
    try {
      final response = await _dio.get(
        '/payrolls/mm',
        queryParameters: {if (year != null) 'year': year},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final mmData = response.data['data'];
        if (mmData is List) {
          // Mark MM payrolls with division type
          for (var item in mmData) {
            if (item is Map<String, dynamic>) {
              item['division'] = 'minimarket';
            }
          }
          allPayrolls.addAll(mmData);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch MM payrolls: $e');
    }

    // Try to fetch from Reflexiology endpoint
    try {
      final response = await _dio.get(
        '/payrolls/ref',
        queryParameters: {if (year != null) 'year': year},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final refData = response.data['data'];
        if (refData is List) {
          // Mark Ref payrolls with division type
          for (var item in refData) {
            if (item is Map<String, dynamic>) {
              item['division'] = 'reflexiology';
            }
          }
          allPayrolls.addAll(refData);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch Ref payrolls: $e');
    }

    // Try to fetch from Wrapping endpoint
    try {
      final response = await _dio.get(
        '/payrolls/wrapping',
        queryParameters: {if (year != null) 'year': year},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final wraData = response.data['data'];
        if (wraData is List) {
          // Mark Wra payrolls with division type
          for (var item in wraData) {
            if (item is Map<String, dynamic>) {
              item['division'] = 'wrapping';
            }
          }
          allPayrolls.addAll(wraData);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch Wrapping payrolls: $e');
    }

    // Sort by period descending (latest first)
    try {
      allPayrolls.sort((a, b) {
        final aStr = a['period'] ?? a['period_start'] ?? '';
        final bStr = b['period'] ?? b['period_start'] ?? '';
        return bStr.toString().compareTo(aStr.toString());
      });
    } catch (e) {
      debugPrint('Failed to sort payrolls: $e');
    }

    return allPayrolls;
  }

  Future<void> downloadSlip(
    int payrollId,
    String filename, {
    String? division,
  }) async {
    try {
      final token = await StorageService.getToken();

      // Use division-specific endpoint
      String endpoint;
      if (division == 'minimarket') {
        endpoint = '/payrolls/mm/$payrollId/slip';
      } else if (division == 'fnb') {
        endpoint = '/payrolls/fnb/$payrollId/slip';
      } else if (division == 'reflexiology') {
        endpoint = '/payrolls/ref/$payrollId/slip';
      } else if (division == 'wrapping') {
        endpoint = '/payrolls/wrapping/$payrollId/slip';
      } else {
        // Fallback or Error? Since generic is removed, we should probably throw error or default to one
        throw Exception('Unknown Division for download');
      }

      debugPrint('Downloading slip from: $endpoint');

      final response = await _dio.get(
        endpoint,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(response.data);

        debugPrint('File saved to: ${file.path}');

        final result = await OpenFile.open(file.path);
        debugPrint('OpenFile result: ${result.message}');

        if (result.type != ResultType.done) {
          throw Exception('Gagal membuka file: ${result.message}');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Download error: $e');
      throw Exception('Gagal download slip: $e');
    }
  }
}
