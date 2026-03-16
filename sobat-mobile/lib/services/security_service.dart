import 'package:dio/dio.dart';
import '../utils/error_handler.dart';
import 'base_service.dart';

class SecurityService extends BaseService {
  Future<void> setupPin(String pin, String pinConfirmation) async {
    try {
      await dio.post(
        'security/pin/setup',
        data: {'pin': pin, 'pin_confirmation': pinConfirmation},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw Exception('PIN tidak valid');
      }
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      await dio.post(
        'security/pin/verify',
        data: {'pin': pin},
      );
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return false;
      }
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }
}
