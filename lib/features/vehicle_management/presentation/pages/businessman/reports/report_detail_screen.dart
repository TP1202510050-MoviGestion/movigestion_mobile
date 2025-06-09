import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_service.dart';

import '../../login_register/login_screen.dart';
import '../carrier_profiles/carrier_profiles.dart';
import '../profile/profile_screen.dart';
import '../shipments/shipments_screen.dart';
import '../vehicle/vehicles_screen.dart';
import 'reports_screen.dart';

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
  final ReportService _reportService   = ReportService();
  final ProfileService _profileService = ProfileService();

  late ReportModel _report;
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _markInProgress();
    _fetchPhone();
  }

  Future<void> _markInProgress() async {
    if (_report.status != 'En Proceso') {
      final updated = _report.copyWith(status: 'En Proceso');
      final ok = await _reportService.updateReport(updated);
      if (ok) setState(() => _report = updated);
    }
  }

  Future<void> _fetchPhone() async {
    final parts = _report.driverName.split(' ');
    final prof = await _profileService.getProfileByNameAndLastName(
      parts.first,
      parts.length > 1 ? parts.last : '',
    );
    setState(() {
      _phone = prof?.phone ?? '';
    });
  }

  Future<void> _deleteReport() async {
    final ok = await _reportService.deleteReport(_report.id!);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error al eliminar')));
    }
  }

  Future<void> _markResolved() async {
    if (_report.status != 'Resuelto') {
      final updated = _report.copyWith(status: 'Resuelto');
      final ok = await _reportService.updateReport(updated);
      if (ok) setState(() => _report = updated);
    }
  }

  Future<void> _callDriver() async {
    final uri = Uri.parse('tel:$_phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No se puede llamar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar por defecto mostrará hamburguesa si hay drawer
      appBar: AppBar(
        title: const Text('Detalle del Reporte'),
        backgroundColor: const Color(0xFF2C2F38),
      ),
      drawer: _buildDrawer(context),
      backgroundColor: const Color(0xFF1E1F24),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFF2C2F38),
              child: Column(
                children: [
                  _buildTile(Icons.person,    'Conductor', _report.driverName),
                  _divider(),
                  _buildTile(Icons.business,  'Empresa',   _report.companyName),
                  _divider(),
                  _buildTile(Icons.badge,     'RUC',       _report.companyRuc),
                  _divider(),
                  _buildTile(Icons.report,    'Tipo',      _report.type),
                  _divider(),
                  _buildTile(Icons.description,'Descripción', _report.description),
                  _divider(),
                  _buildTile(Icons.calendar_today, 'Creado',
                      '${_report.createdAt.toLocal()}'.split('.')[0]),
                  _divider(),
                  _buildTile(Icons.location_on, 'Ubicación', _report.location),
                  _divider(),
                  _buildTile(Icons.directions_car, 'Placa', _report.vehiclePlate),
                  _divider(),
                  _buildTile(Icons.info,       'Estado',    _report.status),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_report.photoOrVideo.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(_report.photoOrVideo),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF2C2F38),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text('Cerrar', style: TextStyle(color: Colors.white)),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete, size: 28, color: Colors.red),
              onPressed: _deleteReport,
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, size: 28, color: Colors.green),
              onPressed: _markResolved,
            ),
            IconButton(
              icon: const Icon(Icons.phone, size: 28, color: Colors.amber),
              onPressed: _phone.isNotEmpty ? _callDriver : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber),
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _divider() => const Divider(color: Colors.white24, height: 1);

  Drawer _buildDrawer(BuildContext ctx) => Drawer(
    backgroundColor: const Color(0xFF2C2F38),
    child: ListView(padding: EdgeInsets.zero, children: [
      DrawerHeader(
        child: Column(
          children: [
            Image.asset('assets/images/login_logo.png', height: 100),
            const SizedBox(height: 10),
            Text(
              '${widget.name} ${widget.lastName} – Gerente',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
      _drawerItem(Icons.person, 'PERFIL', () {
        Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (_) =>
                    ProfileScreen(name: widget.name, lastName: widget.lastName)));
      }),
      _drawerItem(Icons.people, 'TRANSPORTISTAS', () {
        Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (_) => CarrierProfilesScreen(
                    name: widget.name, lastName: widget.lastName)));
      }),
      _drawerItem(Icons.report, 'REPORTES', () {
        Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (_) =>
                    ReportsScreen(name: widget.name, lastName: widget.lastName)));
      }),
      _drawerItem(Icons.directions_car, 'VEHÍCULOS', () {
        Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (_) =>
                    VehiclesScreen(name: widget.name, lastName: widget.lastName)));
      }),
      _drawerItem(Icons.local_shipping, 'ENVIOS', () {
        Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (_) =>
                    ShipmentsScreen(name: widget.name, lastName: widget.lastName)));
      }),
      const SizedBox(height: 160),
      ListTile(
        leading: const Icon(Icons.logout, color: Colors.white),
        title:
        const Text('CERRAR SESIÓN', style: TextStyle(color: Colors.white)),
        onTap: () => Navigator.pushAndRemoveUntil(
          ctx,
          MaterialPageRoute(
              builder: (_) => LoginScreen(
                  onLoginClicked: (_, __) {}, onRegisterClicked: () {})),
              (route) => false,
        ),
      ),
    ]),
  );

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: Colors.white),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    onTap: onTap,
  );
}
