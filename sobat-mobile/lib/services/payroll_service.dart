import 'package:dio/dio.dart';
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
    try {
      final response = await _dio.get(
        '/payrolls',
        queryParameters: {if (year != null) 'year': year},
      );

      if (response.statusCode == 200) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat data payroll: $e');
    }
  }

  Future<void> downloadSlip(int payrollId, String filename) async {
    try {
      final token = await StorageService.getToken();
      final response = await _dio.get(
        '/payrolls/$payrollId/slip',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(response.data);
        await OpenFile.open(file.path);
      } else {
        throw Exception('Gagal mengunduh slip gaji');
      }
    } catch (e) {
      throw Exception('Gagal download slip: $e');
    }
  }
}
