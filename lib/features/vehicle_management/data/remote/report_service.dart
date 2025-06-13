import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';
import 'report_model.dart';

class ReportService {
  /* ───────────────── GET TODOS ───────────────── */
  Future<List<ReportModel>> getAllReports() async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      // ——► decodificación explícita en UTF-8
      final decodedBody = utf8.decode(res.bodyBytes);
      final List<dynamic> list = json.decode(decodedBody);
      return list.map((item) => ReportModel.fromJson(item)).toList();
    } else {
      throw Exception(
          'Failed to load reports (status ${res.statusCode})');
    }
  }

  /* ───────────────── GET POR ID ───────────────── */
  Future<ReportModel?> getReportById(int id) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}/$id');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final decodedBody = utf8.decode(res.bodyBytes);
      return ReportModel.fromJson(json.decode(decodedBody));
    } else {
      return null;
    }
  }

  /* ───────────────── CREATE ───────────────── */
  Future<bool> createReport(ReportModel report) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(report.toJson()),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  /* ───────────────── UPDATE COMPLETO (PUT) ───────────────── */
  Future<bool> updateReport(ReportModel report) async {
    final url =
    Uri.parse('${AppConstants.baseUrl}${AppConstants.report}/${report.id}');
    final res = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(report.toJson()),
    );
    return res.statusCode == 200;
  }

  /* ───────────────── PATCH SOLO ESTADO (opcional) ───────────────── */
  Future<bool> updateReportStatus(int id, String status) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}/$id');
    final res = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );
    return res.statusCode == 200;
  }

  /* ───────────────── DELETE ───────────────── */
  Future<bool> deleteReport(int id) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.report}/$id');
    final res = await http.delete(url);
    return res.statusCode == 200 || res.statusCode == 204;
  }
}
