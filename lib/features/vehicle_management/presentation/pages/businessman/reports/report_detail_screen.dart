import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_service.dart';

import '../../../../../../core/widgets/app_drawer.dart';

// TODO: Asegúrate de que la ruta de importación para tu AppDrawer sea correcta.
// Si creaste la carpeta 'widgets', esta ruta debería funcionar.

// --- THEME CONSTANTS (Idealmente, esto iría en un archivo de tema separado) ---
class AppColors {
  static const Color background = Color(0xFF1E1F24);
  static const Color surface = Color(0xFF2C2F38);
  static const Color primary = Colors.amber;
  static const Color text = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color success = Colors.green;
  static const Color danger = Colors.red;
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.bold);
  static const TextStyle subheading = TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w600);
  static const TextStyle body = TextStyle(color: AppColors.text, fontSize: 16);
  static const TextStyle bodySecondary = TextStyle(color: AppColors.textSecondary, fontSize: 14);
}
// -----------------------------------------------------------------------------


class ReportDetailScreen extends StatefulWidget {
  final ReportModel report;
  final String name;
  final String lastName;

  const ReportDetailScreen({
    Key? key,
    required this.name,
    required this.lastName,
    required this.report,
  }) : super(key: key);






  @override
  _ReportDetailScreenState createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final ReportService _reportService = ReportService();
  final ProfileService _profileService = ProfileService();

  late ReportModel _report;
  String _phone = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _markInProgress();
    _fetchPhone();
  }

  // --- LÓGICA DE NEGOCIO (Preservada del original, con mejoras de seguridad) ---
  Future<void> _markInProgress() async {
    if (_report.status != 'En Proceso') {
      final updated = _report.copyWith(status: 'En Proceso');
      final ok = await _reportService.updateReport(updated);
      if (ok && mounted) setState(() => _report = updated);
    }
  }

  Future<void> _fetchPhone() async {
    // 1. Verificamos que el nombre del conductor no esté vacío.
    if (_report.driverName.trim().isEmpty) {
      return;
    }

    // 2. Usamos el nuevo método del servicio, pasándole el nombre completo directamente.
    final profile = await _profileService.getProfileByFullName(_report.driverName);

    // 3. Actualizamos el estado con el resultado. La lógica aquí no cambia.
    if (mounted) {
      setState(() {
        _phone = profile?.phone ?? '';
      });
    }
  }

  // --- ACCIONES DEL USUARIO CON FEEDBACK Y CONTROL DE ESTADO ---
  Future<void> _markResolved() async {
    if (_isLoading || _report.status == 'Resuelto') return;

    setState(() => _isLoading = true);
    try {
      final updated = _report.copyWith(status: 'Resuelto');
      final ok = await _reportService.updateReport(updated);
      if (ok && mounted) {
        setState(() => _report = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte marcado como Resuelto'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        throw Exception('Error al actualizar');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al marcar como resuelto'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReport() async {
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirmar Eliminación', style: AppTextStyles.subheading),
        content: const Text('¿Estás seguro de que quieres eliminar este reporte? Esta acción no se puede deshacer.', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final ok = await _reportService.deleteReport(_report.id!);
      if (ok && mounted) {
        Navigator.pop(context, true);
      } else {
        throw Exception('Error al eliminar');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el reporte'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _callDriver() async {
    if (_phone.isEmpty) return;
    final uri = Uri.parse('tel:$_phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se puede realizar la llamada')),
        );
      }
    }
  }

  // --- MÉTODO BUILD PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle del Reporte'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      drawer: AppDrawer(
        name: widget.name,
        lastName: widget.lastName,
        companyName: _report.companyName, // Usamos el dato del reporte actual
        companyRuc: _report.companyRuc,     // Usamos el dato del reporte actual
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportHeader(),
                const SizedBox(height: 24),
                if (_report.photoOrVideo.isNotEmpty) ...[
                  _buildMediaDisplay(),
                  const SizedBox(height: 24),
                ],
                _buildInfoCard(
                  title: 'Detalles del Reporte',
                  icon: Icons.description,
                  data: {
                    'Descripción': _report.description,
                    'Ubicación': _report.location,
                    'Fecha de Creación': '${_report.createdAt.toLocal()}'.split('.')[0],
                  },
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Información del Conductor',
                  icon: Icons.person,
                  data: {
                    'Conductor': _report.driverName,
                    'Empresa': _report.companyName,
                    'RUC': _report.companyRuc,
                    'Placa del Vehículo': _report.vehiclePlate,
                  },
                ),
                const SizedBox(height: 32),
                _buildActionButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGETS DE UI REFACTORIZADOS ---
  Widget _buildReportHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_report.type, style: AppTextStyles.heading),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            label: Text(_report.status, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: _report.status == 'Resuelto' ? AppColors.success : AppColors.primary,
            avatar: Icon(
              _report.status == 'Resuelto' ? Icons.check_circle : Icons.hourglass_top,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Evidencia', style: AppTextStyles.subheading),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(_report.photoOrVideo),
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 220,
                color: AppColors.surface,
                child: const Center(child: Icon(Icons.error_outline, color: AppColors.danger, size: 40)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Map<String, String> data,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.subheading),
              ],
            ),
            const Divider(color: Colors.white24, height: 24, thickness: 1),
            ...data.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildInfoRow(title: entry.key, value: entry.value),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.bodySecondary),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.body),
      ],
    );
  }
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_report.status != 'Resuelto')
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _markResolved,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('MARCAR COMO RESUELTO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

        if (_report.status != 'Resuelto') const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading || _phone.isEmpty ? null : _callDriver,
                icon: const Icon(Icons.phone),
                label: const Text('Llamar'),
                style: OutlinedButton.styleFrom(
                  // CAMBIO CLAVE 1: Usamos un color de alto contraste.
                  // AppColors.textSecondary (blanco con 70% de opacidad) es perfecto.
                  // Es muy visible sin ser tan llamativo como el blanco puro.
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.amber,
                  side: const BorderSide(color: Colors.amber), // Borde del mismo color
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _deleteReport,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar'),
                style: OutlinedButton.styleFrom(
                  // CAMBIO CLAVE 2: Mantenemos el color de peligro, que ya tiene
                  // un contraste aceptable, pero aseguramos que se aplique correctamente.
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger), // Borde del mismo color
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Divider(color: Colors.white24),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.arrow_back),
          label: const Text('Volver a Reportes'),
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        )
      ],
    );
  }
}