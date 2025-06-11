import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/profile/profile_screen2.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/reports/reports_carrier_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/shipments/shipments_screen2.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';

class VehicleDetailCarrierScreenScreen extends StatefulWidget {
  final String name;
  final String lastName;

  const VehicleDetailCarrierScreenScreen({
    Key? key,
    required this.name,
    required this.lastName,
  }) : super(key: key);

  @override
  _VehicleDetailCarrierScreenScreenState createState() =>
      _VehicleDetailCarrierScreenScreenState();
}

class _VehicleDetailCarrierScreenScreenState
    extends State<VehicleDetailCarrierScreenScreen>
    with SingleTickerProviderStateMixin {
  VehicleModel? _vehicle;
  bool _isLoading = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final _fmtDate = DateFormat('yyyy-MM-dd');
  final _fmtDateTime = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _fetchAssignedVehicle();
  }

  Future<void> _fetchAssignedVehicle() async {
    final url = Uri.parse('${const String.fromEnvironment("API_BASE")}/api/vehicles');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List;
        final found = list
            .map((j) => VehicleModel.fromJson(j))
            .cast<VehicleModel?>()
            .firstWhere((v) => v?.driverName == widget.name, orElse: () => null);
        setState(() {
          _vehicle = found;
          _isLoading = false;
        });
        if (found != null) _animCtrl.forward();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F38),
        title: Row(children: [
          const Icon(Icons.directions_car, color: Colors.amber),
          const SizedBox(width: 8),
          const Text('Vehículo Asignado',
              style: TextStyle(color: Colors.grey, fontSize: 22, fontWeight: FontWeight.w600)),
        ]),
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _vehicle == null
          ? const Center(
          child: Text('No tienes un vehículo asignado.',
              style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)))
          : FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _section(_vehicleImage(_vehicle!.vehicleImage)),
              const SizedBox(height: 16),
              _section(_infoRow('Placa', _vehicle!.licensePlate)),
              _section(_infoRow('Marca', _vehicle!.brand)),
              _section(_infoRow('Modelo', _vehicle!.model)),
              _section(_infoRow('Año', _vehicle!.year.toString())),
              _section(_infoRow('Color', _vehicle!.color)),
              _section(_infoRow('Capacidad', '${_vehicle!.seatingCapacity} pax')),
              _section(_infoRow('Estado', _vehicle!.status)),
              _section(_infoRow('Asignado el', _fmtDateTime.format(_vehicle!.assignedAt!))),
              if (_vehicle!.dateToGoTheWorkshop != null)
                _section(_infoRow(
                    'Taller', _fmtDate.format(_vehicle!.dateToGoTheWorkshop!))),
              const SizedBox(height: 8),
              _section(_docPreview('SOAT', _vehicle!.documentSoat)),
              _section(_docPreview('Tarjeta Propiedad', _vehicle!.documentVehicleOwnershipCard)),
              const SizedBox(height: 8),
              _section(_infoLocation()),
              const SizedBox(height: 8),
              _section(_infoSpeed()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF2F353F),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 3))],
    ),
    child: child,
  );

  Widget _vehicleImage(String b64) {
    if (b64.isEmpty) {
      return Container(
        height: 200,
        color: const Color(0xFF3A414B),
        child: const Center(child: Text('No hay imagen', style: TextStyle(color: Colors.white70))),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        base64Decode(b64),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        Flexible(child: Text(value, style: const TextStyle(color: Colors.amber), textAlign: TextAlign.end)),
      ],
    );
  }

  Widget _docPreview(String title, String b64) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        b64.isEmpty
            ? Container(
          height: 100,
          color: const Color(0xFF3A414B),
          child: const Center(child: Text('No disponible', style: TextStyle(color: Colors.white54))),
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(b64),
            height: 100,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _infoLocation() {
    final loc = _vehicle!.lastLocation;
    return _infoRow(
      'Última Ubicación',
      loc != null
          ? 'Lat ${loc.latitude}, Lon ${loc.longitude}\n${_fmtDateTime.format(loc.timestamp)}'
          : 'Sin datos',
    );
  }

  Widget _infoSpeed() {
    final sp = _vehicle!.lastSpeed;
    return _infoRow(
      'Última Velocidad',
      sp != null
          ? '${sp.kmh} km/h\n${_fmtDateTime.format(sp.timestamp)}'
          : 'Sin datos',
    );
  }

  Drawer _buildDrawer() => Drawer(
    backgroundColor: const Color(0xFF2C2F38),
    child: ListView(padding: EdgeInsets.zero, children: [
      DrawerHeader(
        child: Column(
          children: [
            Image.asset('assets/images/login_logo.png', height: 100),
            const SizedBox(height: 10),
            Text('${widget.name} ${widget.lastName} - Transportista',
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
      _drawerItem(Icons.person, 'PERFIL',
          ProfileScreen2(name: widget.name, lastName: widget.lastName)),
      _drawerItem(Icons.report, 'REPORTES',
          ReportsCarrierScreen(name: widget.name, lastName: widget.lastName)),
      _drawerItem(Icons.directions_car, 'VEHÍCULO',
          VehicleDetailCarrierScreenScreen(name: widget.name, lastName: widget.lastName)),
      _drawerItem(Icons.local_shipping, 'ENVIOS',
          ShipmentsScreen2(name: widget.name, lastName: widget.lastName)),
      const SizedBox(height: 160),
      ListTile(
        leading: const Icon(Icons.logout, color: Colors.white),
        title: const Text('CERRAR SESIÓN', style: TextStyle(color: Colors.white)),
        onTap: () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                LoginScreen(onLoginClicked: (_, __) {}, onRegisterClicked: () {}),
          ),
              (_) => false,
        ),
      ),
    ]),
  );

  Widget _drawerItem(IconData icon, String title, Widget page) => ListTile(
    leading: Icon(icon, color: Colors.white),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
  );
}
