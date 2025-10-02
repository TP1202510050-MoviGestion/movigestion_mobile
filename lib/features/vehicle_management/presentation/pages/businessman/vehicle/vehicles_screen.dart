/* --------------  IMPORTS -------------- */
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;                                      // ⬅️ NUEVO
import 'package:movigestion_mobile/core/app_constants.dart';                 // ⬅️ NUEVO
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/vehicle/assign_vehicle_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/vehicle/vehicle_detail_screen.dart';
import '../../../../../../core/widgets/app_drawer.dart';

class VehiclesScreen extends StatefulWidget {
  final String name;
  final String lastName;
  const VehiclesScreen({
    super.key,
    required this.name,
    required this.lastName,
  });

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  /* --------------  SERVICIOS Y ESTADO -------------- */
  final _svc = VehicleService();
  final List<VehicleModel> _vehicles = [];
  bool _loading = true;

  // Datos de la empresa del usuario (se obtienen al vuelo)
  String _companyName = '';
  String _companyRuc = '';

  // End-point de perfiles para averiguar la empresa del usuario
  final String _profileApiUrl =
      '${AppConstants.baseUrl}${AppConstants.profile}';                        // ⬅️ NUEVO

  /* ------------ CARGA ------------ */
  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  /// Obtiene la empresa del usuario y luego filtra los vehículos
  Future<void> _fetchVehicles() async {
    setState(() => _loading = true);

    try {
      /* -------- 1) OBTENER EMPRESA DEL USUARIO -------- */
      final profileResp = await http.get(Uri.parse(_profileApiUrl));
      if (profileResp.statusCode == 200) {
        final profiles = jsonDecode(profileResp.body) as List<dynamic>;
        final managerProfile = profiles.firstWhere(
              (p) =>
          p['name'].toString().toLowerCase() ==
              widget.name.toLowerCase() &&
              p['lastName'].toString().toLowerCase() ==
                  widget.lastName.toLowerCase(),
          orElse: () => null,
        );

        if (managerProfile != null) {
          _companyName = (managerProfile['companyName'] ?? '').toString();
          _companyRuc = (managerProfile['companyRuc'] ?? '').toString();
        }
      }

      /* -------- 2) CARGAR VEHÍCULOS Y FILTRAR -------- */
      final all = await _svc.getAllVehicles();
      _vehicles
        ..clear()
        ..addAll(all.where((v) =>
        v.companyName.toLowerCase() == _companyName.toLowerCase() &&
            v.companyRuc == _companyRuc));
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

  void _addVehicle(VehicleModel v) => setState(() => _vehicles.insert(0, v));

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
            Text('Vehículos',
                style: textTheme.titleLarge?.copyWith(color: Colors.white70)),
          ],
        ),
      ),
      drawer: AppDrawer(
        name: widget.name,
        lastName: widget.lastName,
        companyName: _companyName, // Usamos la variable de estado de la pantalla
        companyRuc: _companyRuc,     // Usamos la variable de estado de la pantalla
      ),
      body: RefreshIndicator(
        onRefresh: _fetchVehicles,
        color: Colors.amber,
        child: _loading
            ? const Center(
            child: CircularProgressIndicator(color: Colors.amber))
            : _vehicles.isEmpty
            ? ListView(
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
        label: const Text('Asignar vehículo',
            style: TextStyle(color: Colors.black)),
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
}

/* ═════════════  CARD DE VEHÍCULO  ════════════ */
class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.onTap});

  final VehicleModel vehicle;
  final VoidCallback onTap;

  ImageProvider? _thumbnail() {
    final raw = vehicle.vehicleImage.trim();
    if (raw.isEmpty) return null;

    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme && uri.hasAbsolutePath) {
      return NetworkImage(raw);
    }

    final cleaned = raw.contains(',') ? raw.split(',').last : raw;
    try {
      final bytes = base64Decode(base64.normalize(cleaned));
      return MemoryImage(bytes);
    } catch (_) {
      return null;
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
                  const Icon(Icons.directions_car,
                      size: 60, color: Colors.grey),
                )
                    : const Icon(Icons.directions_car,
                    size: 60, color: Colors.grey),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${vehicle.brand} • ${vehicle.model} (${vehicle.year})',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    _info('Placa', vehicle.licensePlate),
                    _info('Estado', vehicle.status),
                    _info('Capacidad', '${vehicle.seatingCapacity} pax'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Colors.amber, size: 26)
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
