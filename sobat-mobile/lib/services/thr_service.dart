import 'package:dio/dio.dart';
import 'storage_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../utils/error_handler.dart';
import '../config/divisions_config.dart';
import 'base_service.dart';

class ThrService extends BaseService {
  Future<List<dynamic>> getThrs() async {
    try {
      final response = await dio.get('thrs');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      // Return mock data for UI development if API is not ready
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
      final endpoint = DivisionsConfig.getThrSlipEndpoint(id);
      final Response response;

      if (employeeSignature != null) {
        response = await dio.post(
          endpoint,
          data: {'employee_signature': employeeSignature},
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      } else {
        response = await dio.get(
          endpoint,
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
          throw Exception('Gagal membuka file PDF');
        }
      } else {
        throw Exception('Gagal mengunduh slip THR');
      }
    } on DioException catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }
}
