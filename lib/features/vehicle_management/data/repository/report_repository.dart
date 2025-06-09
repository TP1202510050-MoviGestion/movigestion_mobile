import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_model.dart';

class ReportRepository {
  final ReportService reportService;

  ReportRepository({required this.reportService});

  Future<List<ReportModel>> getAllReports() => reportService.getAllReports();

  Future<ReportModel?> getReportById(int id) => reportService.getReportById(id);

  Future<bool> createReport(ReportModel report) => reportService.createReport(report);

  Future<bool> updateReport(ReportModel report) => reportService.updateReport(report);

  Future<bool> updateReportStatus(int id, String status) =>
      reportService.updateReportStatus(id, status);

  Future<bool> deleteReport(int id) => reportService.deleteReport(id);
}
