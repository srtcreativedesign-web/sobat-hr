import 'package:dio/dio.dart';
import '../config/dio_factory.dart';
import 'storage_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ThrService {
  late final Dio _dio;

  ThrService() {
    _dio = DioFactory.create();

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

  Future<List<dynamic>> getThrs() async {
    try {
      final response = await _dio.get('thrs');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      // Mock data for UI development if API is not ready
      return [
        {
          'id': 1,
          'year': 2024,
          'nominal': 5000000,
          'tax': 0,
          'net_nominal': 5000000,
          'status': 'paid',
          'paid_at': '2024-04-05T10:00:00Z',
          'division': 'office',
          'details': {
            'masa_kerja': '2 Tahun 4 Bulan',
            'keterangan': 'THR Idul Fitri 1445 H',
          },
        },
        {
          'id': 2,
          'year': 2023,
          'nominal': 4500000,
          'tax': 0,
          'net_nominal': 4500000,
          'status': 'paid',
          'paid_at': '2023-04-15T09:00:00Z',
          'division': 'office',
          'details': {
            'masa_kerja': '1 Tahun 4 Bulan',
            'keterangan': 'THR Idul Fitri 1444 H',
          },
        },
      ];
    }
  }

  Future<void> downloadThrSlip(
    int id,
    String filename, {
    String? employeeSignature,
  }) async {
    try {
      final token = await StorageService.getToken();
      final Response response;

      if (employeeSignature != null) {
        // POST with employee signature
        response = await _dio.post(
          'thrs/$id/slip',
          data: {'employee_signature': employeeSignature},
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      } else {
        // GET without signature
        response = await _dio.get(
          'thrs/$id/slip',
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      }

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(response.data);

        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          throw Exception('Gagal membuka file: ${result.message}');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal download slip THR: $e');
    }
  }
}
