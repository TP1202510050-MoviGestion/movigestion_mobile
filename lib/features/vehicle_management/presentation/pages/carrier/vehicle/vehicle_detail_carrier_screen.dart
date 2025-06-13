// lib/features/vehicle_management/presentation/pages/carrier/vehicle/vehicle_detail_carrier_screen.dart
//
// Muestra el vehículo asignado al transportista con la misma
// línea visual que la pantalla “VehicleDetailScreen” (Gerente).
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../../core/widgets/app_drawer2.dart';
import '../../../../data/remote/vehicle_model.dart';
import '../../../../data/remote/vehicle_service.dart';

import '../../../../data/repository/vehicle_repository.dart';
import '../profile/profile_screen2.dart';
import '../reports/reports_carrier_screen.dart';
import '../shipments/shipments_screen2.dart';
import '../../login_register/login_screen.dart';



// ──────────────────── Constantes de Estilo ───────────────────
const _kBg       = Color(0xFF1E1F24);
const _kCard     = Color(0xFF2F353F);
const _kBar      = Color(0xFF2C2F38);
const _kAction   = Color(0xFFEA8E00);
const _kTextMain = Colors.white;
const _kTextSub  = Colors.white70;
const _kRadius   = 12.0;



class VehicleDetailCarrierScreen extends StatefulWidget {
  final String name;
  final String lastName;

  const VehicleDetailCarrierScreen({
    Key? key,
    required this.name,
    required this.lastName,
  }) : super(key: key);

  @override
  State<VehicleDetailCarrierScreen> createState() =>
      _VehicleDetailCarrierScreenState();
}

class _VehicleDetailCarrierScreenState
    extends State<VehicleDetailCarrierScreen> with SingleTickerProviderStateMixin {
  VehicleModel? _vehicle;
  bool _isLoading = true;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;

  final _fmtDate     = DateFormat('yyyy-MM-dd');
  final _fmtDateTime = DateFormat('yyyy-MM-dd HH:mm');

  // ────────────────────── Ciclo de vida ──────────────────────
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

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }



  // ────────────────────── LÓGICA principal ───────────────────
  /// Normaliza cadenas: minúsculas, un solo espacio y sin acentos
  String _normalize(String s) {
    final noExtraSpaces =
    s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

    const from = 'áàäâãéèëêíìïîóòöôõúùüûñ';
    const to   = 'aaaaaeeeeiiiiooooouuuun';

    return noExtraSpaces.split('').map((ch) {
      final idx = from.indexOf(ch);
      return (idx == -1) ? ch : to[idx];
    }).join();
  }

  Future<void> _fetchAssignedVehicle() async {
    setState(() => _isLoading = true);

    try {
      final repo = VehicleRepository(vehicleService: VehicleService());
      final list = await repo.getAllVehicles();

      final userKey = _normalize('${widget.name} ${widget.lastName}');

      // collection package → firstWhereOrNull evita excepción si no hay match
      final found = list.firstWhereOrNull(
            (v) => _normalize(v.driverName) == userKey,
      );

      if (!mounted) return;
      setState(() {
        _vehicle   = found;
        _isLoading = false;
      });
      if (found != null) _animCtrl.forward();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  // ────────────────────── Helpers de UI ──────────────────────
  ImageProvider? _thumbnail(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return MemoryImage(base64Decode(base64.normalize(raw)));
    } catch (_) {
      return null;
    }
  }

  Future<void> _viewFile(String base64Data, String fileName) async {
    if (base64Data.isEmpty) return;
    try {
      final dir      = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/$fileName');
      await tempFile.writeAsBytes(
        base64Decode(base64.normalize(base64Data)),
      );

      final res = await OpenFilex.open(tempFile.path);
      if (res.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir: ${res.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al previsualizar ($e)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  // ────────────────────────── Build ──────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBar,
        title: const Text('Mi Vehículo Asignado',
            style: TextStyle(color: _kTextMain)),
        iconTheme: const IconThemeData(color: _kTextMain),
      ),
      drawer: AppDrawer2(name: widget.name, lastName: widget.lastName),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _kAction, strokeWidth: 3),
      );
    }

    if (_vehicle == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No tienes un vehículo asignado actualmente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kTextSub, fontSize: 18),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ───────────── Imagen ─────────────
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(_kRadius),
              image: _thumbnail(_vehicle!.vehicleImage) != null
                  ? DecorationImage(
                  image: _thumbnail(_vehicle!.vehicleImage)!,
                  fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: _thumbnail(_vehicle!.vehicleImage) == null
                ? const Icon(Icons.directions_car,
                color: _kTextSub, size: 60)
                : null,
          ),
          const SizedBox(height: 20),

          // ───────────── Detalle ─────────────
          _sectionLabel('Datos generales'),
          _displayField('Placa', _vehicle!.licensePlate),
          Row(children: [
            Expanded(child: _displayField('Marca', _vehicle!.brand)),
            const SizedBox(width: 12),
            Expanded(child: _displayField('Modelo', _vehicle!.model)),
          ]),
          Row(children: [
            Expanded(child: _displayField('Año', _vehicle!.year.toString())),
            const SizedBox(width: 12),
            Expanded(child: _displayField('Color', _vehicle!.color)),
          ]),
          _displayField(
              'Capacidad', '${_vehicle!.seatingCapacity} pasajeros'),
          _displayField('Estado', _vehicle!.status),

          _sectionLabel('Mantenimiento'),
          _displayField('Última inspección',
              _fmtDate.format(_vehicle!.lastTechnicalInspectionDate)),
          if (_vehicle!.dateToGoTheWorkshop != null)
            _displayField('Próximo taller',
                _fmtDate.format(_vehicle!.dateToGoTheWorkshop!)),

          _sectionLabel('Asignación'),
          _displayField('Conductor', _vehicle!.driverName),
          _displayField('Asignado el',
              _vehicle!.assignedAt != null
                  ? _fmtDateTime.format(_vehicle!.assignedAt!)
                  : '—'),

          _sectionLabel('Telemetría'),
          _displayField(
              'Última ubicación',
              _vehicle!.lastLocation != null
                  ? '${_vehicle!.lastLocation!.latitude}, ${_vehicle!.lastLocation!.longitude}'
                  : 'Sin datos'),
          _displayField(
              'Última velocidad',
              _vehicle!.lastSpeed != null
                  ? '${_vehicle!.lastSpeed!.kmh} km/h'
                  : 'Sin datos'),

          _sectionLabel('Documentos'),
          _readOnlyDocTile(
            label: 'SOAT',
            data:  _vehicle!.documentSoat,
          ),
          _readOnlyDocTile(
            label: 'Tarjeta de Propiedad',
            data:  _vehicle!.documentVehicleOwnershipCard,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }



  // ───────────────── Widgets auxiliares ──────────────────
  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(t,
        style: const TextStyle(
            color: _kAction, fontWeight: FontWeight.bold, fontSize: 14)),
  );

  /// Campo de solo lectura con la misma estética de los TextFormField
  /// de “VehicleDetailScreen”.
  Widget _displayField(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      readOnly: true,
      initialValue: value,
      style: const TextStyle(
          color: _kTextMain, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kTextSub),
        filled: true,
        fillColor: _kCard,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_kRadius),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_kRadius),
            borderSide: const BorderSide(color: _kAction)),
      ),
    ),
  );

  Widget _readOnlyDocTile({required String label, required String data}) {
    final hasData = data.isNotEmpty;
    return Card(
      color: _kCard,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
      child: ListTile(
        leading: Icon(hasData ? Icons.description : Icons.description_outlined,
            color: _kAction),
        title: Text(label, style: const TextStyle(color: _kTextMain)),
        subtitle: Text(
          hasData ? 'Documento disponible' : 'No disponible',
          style: const TextStyle(color: _kTextSub),
        ),
        trailing: hasData
            ? IconButton(
          icon: const Icon(Icons.visibility, color: Colors.blueAccent),
          tooltip: 'Ver documento',
          onPressed: () => _viewFile(
              data, '${label.replaceAll(' ', '_').toLowerCase()}.pdf'),
        )
            : null,
      ),
    );
  }



  // ───────────────────────── Drawer ────────────────────────
  Drawer _buildDrawer() => Drawer(
    backgroundColor: _kBar,
    child: ListView(padding: EdgeInsets.zero, children: [
      DrawerHeader(
        child: Column(children: [
          Image.asset('assets/images/login_logo.png', height: 100),
          const SizedBox(height: 10),
          Text('${widget.name} ${widget.lastName} - Transportista',
              style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ]),
      ),
      _dItem(Icons.person, 'PERFIL',
          ProfileScreen2(name: widget.name, lastName: widget.lastName)),
      _dItem(Icons.report, 'REPORTES',
          ReportsCarrierScreen(name: widget.name, lastName: widget.lastName)),
      _dItem(Icons.directions_car, 'MI VEHÍCULO',
          VehicleDetailCarrierScreen(
              name: widget.name, lastName: widget.lastName)),
      _dItem(Icons.local_shipping, 'MIS ENVIOS',
          ShipmentsScreen2(name: widget.name, lastName: widget.lastName)),
      const SizedBox(height: 160),
      ListTile(
        leading: const Icon(Icons.logout, color: Colors.white),
        title: const Text('CERRAR SESIÓN',
            style: TextStyle(color: Colors.white)),
        onTap: () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => LoginScreen(
                  onLoginClicked: (_, __) {}, onRegisterClicked: () {})),
              (_) => false,
        ),
      ),
    ]),
  );

  Widget _dItem(IconData ic, String t, Widget p) => ListTile(
    leading: Icon(ic, color: Colors.white),
    title: Text(t, style: const TextStyle(color: Colors.white)),
    onTap: () {
      Navigator.pop(context);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => p));
    },
  );
}
