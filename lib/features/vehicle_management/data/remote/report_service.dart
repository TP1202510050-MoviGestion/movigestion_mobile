import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';
import 'report_model.dart';

class ReportService {
  Future<List<ReportModel>> getAllReports() async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}'); // Usa AppConstants.report aquí
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => ReportModel.fromJson(json)).toList();
      } else {
        print('Failed to load reports. Status code: ${response.statusCode}');
        throw Exception('Failed to load reports');
      }
    } catch (e) {
      print('Error fetching reports: $e');
      rethrow;
    }
  }

  Future<ReportModel?> getReportById(int id) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}/$id');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return ReportModel.fromJson(json.decode(response.body));
      } else {
        print('Failed to load report. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching report by ID: $e');
      return null;
    }
  }

  Future<bool> createReport(ReportModel report) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(report.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to create report. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error creating report: $e');
      return false;
    }
  }

  Future<bool> deleteReport(int id) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}/$id');
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to delete report. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting report: $e');
      return false;
    }
  }
}
