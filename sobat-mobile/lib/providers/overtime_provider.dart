import 'package:flutter/material.dart';
import '../services/overtime_service.dart';

class OvertimeProvider with ChangeNotifier {
  final OvertimeService _overtimeService = OvertimeService();

  List<dynamic> _overtimeHistory = [];
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _error;

  List<dynamic> get overtimeHistory => _overtimeHistory;
  bool get isLoading => _isLoading;
  bool get isDownloading => _isDownloading;
  String? get error => _error;

  Future<void> fetchOvertimeHistory({String? status, String? startDate, String? endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _overtimeHistory = await _overtimeService.getOvertimeHistory(
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> downloadSummaryPdf({String? status, String? startDate, String? endDate}) async {
    _isDownloading = true;
    _error = null;
    notifyListeners();

    try {
      await _overtimeService.downloadOvertimeSummaryPdf(
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _error = e.toString();
      throw Exception(_error);
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }
}
