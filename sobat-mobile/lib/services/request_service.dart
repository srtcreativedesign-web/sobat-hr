import 'package:dio/dio.dart';
import '../utils/error_handler.dart';
import 'base_service.dart';

class RequestService extends BaseService {
  Future<Map<String, dynamic>> getLeaveBalance() async {
    try {
      final response = await dio.get('requests/leave-balance');
      return response.data;
    } on DioException catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> data) async {
    
    try {
      final response = await dio.post('requests', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw Exception('Data pengajuan tidak valid');
      }
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  Future<List<dynamic>> getRequests({String? type, String? status}) async {
    
    try {
      final response = await dio.get(
        'requests',
        queryParameters: {
          ?'type': type,
          if (status != null && status != 'Semua') 'status': status,
        },
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }
}
