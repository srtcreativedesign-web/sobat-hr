import 'package:dio/dio.dart';
import 'storage_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../utils/error_handler.dart';
import '../config/divisions_config.dart';
import 'base_service.dart';

class PayrollService extends BaseService {
  Future<List<dynamic>> getPayrolls({int? year}) async {
    List<dynamic> allPayrolls = [];

    for (var division in DivisionsConfig.allDivisions) {
      try {
        final endpoint = DivisionsConfig.getBaseEndpoint(division);
        if (endpoint == null) continue;

        final response = await dio.get(
          endpoint,
          queryParameters: {if (year != null) 'year': year},
        );

        if (response.statusCode == 200 && response.data['data'] != null) {
          final data = response.data['data'] as List;
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              item['division'] = division;
            }
          }
          allPayrolls.addAll(data);
        }
      } on DioException {
        // Silently skip divisions that don't have data
      } catch (_) {
        // Continue fetching other divisions
      }
    }

    // Sort by period descending (latest first)
    allPayrolls.sort((a, b) {
      final aStr = a['period'] ?? a['period_start'] ?? '';
      final bStr = b['period'] ?? b['period_start'] ?? '';
      return bStr.toString().compareTo(aStr.toString());
    });

    return allPayrolls;
  }

  Future<void> downloadSlip(
    int payrollId,
    String filename, {
    String? division,
  }) async {
    try {
      final token = await StorageService.getToken();
      final endpoint = DivisionsConfig.getSlipEndpoint(division!, payrollId);

      final response = await dio.get(
        endpoint,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(response.data);

        final result = await OpenFile.open(file.path);

        if (result.type != ResultType.done) {
          throw Exception('Gagal membuka file PDF');
        }
      } else {
        throw Exception('Gagal mengunduh slip gaji');
      }
    } on DioException catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is! Exception) {
        throw Exception(AppErrorHandler.getErrorMessage(e));
      }
      rethrow;
    }
  }
}
