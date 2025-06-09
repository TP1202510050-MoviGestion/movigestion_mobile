import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';
import 'report_model.dart';

class ReportService {
  Future<List<ReportModel>> getAllReports() async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(response.body);
      return list.map((item) => ReportModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load reports (status ${response.statusCode})');
    }
  }

  Future<ReportModel?> getReportById(int id) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}/$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return ReportModel.fromJson(json.decode(response.body));
    } else {
      return null;
    }
  }

  Future<bool> createReport(ReportModel report) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(report.toJson()),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Nuevo: PUT completo para actualizar cualquier campo del reporte
  Future<bool> updateReport(ReportModel report) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}/${report.id}');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(report.toJson()),
    );
    return response.statusCode == 200;
  }

  /// (Opcional) atajo para solo cambiar estado, si quieres seguir usando PATCH:
  Future<bool> updateReportStatus(int id, String status) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}/$id');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteReport(int id) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}/$id');
    final response = await http.delete(url);
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
