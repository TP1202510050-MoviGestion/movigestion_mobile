/* --------------  IMPORTS -------------- */
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/vehicle/assign_vehicle_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/vehicle/vehicle_detail_screen.dart';
import '../../login_register/login_screen.dart';
import '../carrier_profiles/carrier_profiles.dart';
import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';
import '../shipments/shipments_screen.dart';
/* -------------------------------------- */

class VehiclesScreen extends StatefulWidget {
  final String name;
  final String lastName;
  const VehiclesScreen({super.key, required this.name, required this.lastName});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final _svc = VehicleService();
  final List<VehicleModel> _vehicles = [];
  bool _loading = true;

  /* ------------ CARGA ------------ */
  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() => _loading = true);
    try {
      _vehicles
        ..clear()
        ..addAll(await _svc.getAllVehicles());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al cargar vehículos'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addVehicle(VehicleModel v) =>
      setState(() => _vehicles.insert(0, v));

  /* ------------ UI ------------ */
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1E24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F38),
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.directions_car, color: Colors.amber),
            const SizedBox(width: 12),
            Text('Vehículos', style: textTheme.titleLarge?.copyWith(color: Colors.white70)),
          ],
        ),
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchVehicles,
        color: Colors.amber,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : _vehicles.isEmpty
            ? ListView( // permite pull-to-refresh
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text('No hay vehículos disponibles',
                  style: TextStyle(color: Colors.grey)),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _vehicles.length,
          itemBuilder: (_, i) => _VehicleCard(
            vehicle: _vehicles[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VehicleDetailScreen(
                  vehicle: _vehicles[i],
                  name: widget.name,
                  lastName: widget.lastName,
                ),
              ),
            ),
          ),
        ),
      ),

      /* ------------ FAB ------------- */
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addVehicle',
        backgroundColor: const Color(0xFFFFA000),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Asignar vehículo', style: TextStyle(color: Colors.black)),
        onPressed: () async {
          final created = await Navigator.push<VehicleModel?>(
            context,
            MaterialPageRoute(
              builder: (_) => AssignVehicleScreen(
                name: widget.name,
                lastName: widget.lastName,
                onVehicleAdded: _addVehicle,
              ),
            ),
          );
          if (created != null) _addVehicle(created);
        },
      ),
    );
  }

  /* ------------ DRAWER ------------ */
  Drawer _buildDrawer() {
    Widget item(IconData icon, String label, Widget page) => ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );

    return Drawer(
      backgroundColor: const Color(0xFF2C2F38),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Column(
              children: [
                Image.asset('assets/images/login_logo.png', height: 90),
                const SizedBox(height: 10),
                Text('${widget.name} ${widget.lastName} – Gerente',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          item(Icons.person, 'PERFIL',
              ProfileScreen(name: widget.name, lastName: widget.lastName)),
          item(Icons.people, 'TRANSPORTISTAS',
              CarrierProfilesScreen(name: widget.name, lastName: widget.lastName)),
          item(Icons.report, 'REPORTES',
              ReportsScreen(name: widget.name, lastName: widget.lastName)),
          item(Icons.directions_car, 'VEHÍCULOS',
              VehiclesScreen(name: widget.name, lastName: widget.lastName)),
          item(Icons.local_shipping, 'ENVIOS',
              ShipmentsScreen(name: widget.name, lastName: widget.lastName)),
          const SizedBox(height: 140),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('CERRAR SESIÓN', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) =>
                  LoginScreen(onLoginClicked: (_, __) {}, onRegisterClicked: () {})),
                  (_) => false,
            ),
          ),
        ],
      ),
    );
  }
}

/* ═════════════  CARD DE VEHÍCULO  ════════════ */
class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.onTap});

  final VehicleModel vehicle;
  final VoidCallback onTap;

  ImageProvider? _thumbnail() {
    final raw = vehicle.vehicleImage.trim();
    if (raw.isEmpty) return null;

    // ¿URL absoluta?
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme && uri.hasAbsolutePath) {
      return NetworkImage(raw);
    }

    // Asumimos Base-64 (quitamos posible prefijo Data-URI)
    final cleaned = raw.contains(',')
        ? raw.split(',').last
        : raw;
    try {
      final bytes = base64Decode(base64.normalize(cleaned));
      return MemoryImage(bytes);
    } catch (_) {
      return null; // provocará que se vea el icono de fallback
    }
  }


  @override
  Widget build(BuildContext context) {
    final img = _thumbnail();
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF2F353F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: img != null
                    ? Image(
                  image: img,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.directions_car, size: 60, color: Colors.grey),
                )
                    : const Icon(Icons.directions_car, size: 60, color: Colors.grey),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${vehicle.brand} • ${vehicle.model} (${vehicle.year})',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    _info('Placa', vehicle.licensePlate),
                    _info('Estado', vehicle.status),
                    _info('Capacidad', '${vehicle.seatingCapacity} pax'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.amber, size: 26)
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text('$label: $value',
        style: const TextStyle(color: Colors.white70, fontSize: 13)),
  );
}
