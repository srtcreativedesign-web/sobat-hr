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

    // Try to fetch from generic endpoint
    try {
      final response = await _dio.get(
        '/payrolls',
        queryParameters: {if (year != null) 'year': year},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final genericData = response.data['data'];
        if (genericData is List) {
          allPayrolls.addAll(genericData);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch generic payrolls: $e');
      // Continue to try FnB endpoint
    }

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
      // Continue with whatever data we have
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

      // Use division-specific endpoint if FnB
      final endpoint = division == 'fnb'
          ? '/payrolls/fnb/$payrollId/slip'
          : '/payrolls/$payrollId/slip';

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
