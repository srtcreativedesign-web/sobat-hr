import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../utils/error_handler.dart';
import 'base_service.dart';

class OvertimeService extends BaseService {
  Future<List<dynamic>> getOvertimeHistory({String? status, String? startDate, String? endDate}) async {
    try {
      final response = await dio.get(
        'requests',
        queryParameters: {
          'type': 'overtime',
          if (status != null && status != 'Semua') 'status': status,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> downloadOvertimeSummaryPdf({String? status, String? startDate, String? endDate}) async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/Rekap-Lembur-${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Build query params
      final queryParams = <String, String>{};
      if (status != null && status != 'Semua') queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      
      final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      final url = '${ApiConfig.baseUrl}/requests/export/overtime-pdf${queryString.isNotEmpty ? '?$queryString' : ''}';

      await dio.download(
        url,
        filePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/pdf',
          },
        ),
      );

      await OpenFile.open(filePath);
    } catch (e) {
      throw Exception('Gagal mengunduh rekap lembur: $e');
    }
  }
}
