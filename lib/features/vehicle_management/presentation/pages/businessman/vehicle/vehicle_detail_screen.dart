import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';


import '../../../../data/remote/vehicle_model.dart';
import '../../../../data/remote/vehicle_service.dart';
import '../profile/profile_screen.dart';
import '../carrier_profiles/carrier_profiles.dart';
import '../reports/reports_screen.dart';
import '../vehicle/vehicles_screen.dart';
import '../shipments/shipments_screen.dart';
import '../../login_register/login_screen.dart';

const _kBg          = Color(0xFF1E1F24);
const _kCard        = Color(0xFF2F353F);
const _kBar         = Color(0xFF2C2F38);
const _kAction      = Color(0xFFEA8E00);
const _kTextMain    = Colors.white;
const _kTextSub     = Colors.white70;
const _kRadius      = 12.0;

class VehicleDetailScreen extends StatefulWidget {
  final VehicleModel vehicle;
  final String name, lastName;

  const VehicleDetailScreen({
    super.key,
    required this.vehicle,
    required this.name,
    required this.lastName,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  /* ───────────────── controllers / services ───────────────── */
  late final _plateC  = TextEditingController(text: v.licensePlate);
  late final _brandC  = TextEditingController(text: v.brand);
  late final _modelC  = TextEditingController(text: v.model);
  late final _yearC   = TextEditingController(text: v.year.toString());
  late final _colorC  = TextEditingController(text: v.color);
  late final _seatC   = TextEditingController(text: v.seatingCapacity.toString());
  late final _statusC = TextEditingController(text: v.status);
  late final _gpsC    = TextEditingController(text: v.gpsSensorId);
  late final _speedC  = TextEditingController(text: v.speedSensorId);
  late final _driverC = TextEditingController(text: v.driverName);
  late final _inspC   = TextEditingController(text: _fmt.format(v.lastTechnicalInspectionDate));

  final _formKey     = GlobalKey<FormState>();
  final _fmt         = DateFormat('yyyy-MM-dd');
  final _picker      = ImagePicker();
  final _svc         = VehicleService();

  File? _pickedImg, _pickedSoat, _pickedCard;

  VehicleModel get v => widget.vehicle;

  /* ───────────────────── helpers ───────────────────── */
  ImageProvider? _thumbnail(String raw) {
    if (raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return NetworkImage(raw);
    try   { return MemoryImage(base64Decode(base64.normalize(raw))); }
    catch (_) { return null; }
  }

  Future<void> _pickDate(TextEditingController c) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(c.text) ?? DateTime.now(),
      firstDate : DateTime(2000),
      lastDate  : DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
              primary: _kAction, surface: _kCard,
              onSurface: _kTextMain, onPrimary: _kTextMain),
        ),
        child: child!,
      ),
    );
    if (d != null) c.text = _fmt.format(d);
  }

  Future<File?> _pickFile() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    return x != null ? File(x.path) : null;
  }

  InputDecoration _dec(String lbl, {bool date = false}) => InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(color: _kTextSub),
    filled: true,
    fillColor: _kCard,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(_kRadius)),
    suffixIcon: date
        ? IconButton(
      icon: const Icon(Icons.calendar_today, color: _kAction),
      onPressed: () => _pickDate(_inspC),
    )
        : null,
  );

  /* ────────────────── persistencia ────────────────── */
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = v.copyWith(
      licensePlate : _plateC.text.trim(),
      brand        : _brandC.text.trim(),
      model        : _modelC.text.trim(),
      year         : int.tryParse(_yearC.text.trim()) ?? v.year,
      color        : _colorC.text.trim(),
      seatingCapacity: int.tryParse(_seatC.text.trim()) ?? v.seatingCapacity,
      status       : _statusC.text.trim(),
      gpsSensorId  : _gpsC.text.trim(),
      speedSensorId: _speedC.text.trim(),
      driverName   : _driverC.text.trim(),
      lastTechnicalInspectionDate: _fmt.parse(_inspC.text),
      vehicleImage : _pickedImg  != null ? base64Encode(_pickedImg!.readAsBytesSync())  : v.vehicleImage,
      documentSoat : _pickedSoat != null ? base64Encode(_pickedSoat!.readAsBytesSync()) : v.documentSoat,
      documentVehicleOwnershipCard: _pickedCard != null ? base64Encode(_pickedCard!.readAsBytesSync()) : v.documentVehicleOwnershipCard,
    );

    final ok = await _svc.updateVehicle(v.id!, updated);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? Colors.green : Colors.redAccent,
        content: Text(ok ? 'Vehículo actualizado' : 'Error al guardar'),
      ),
    );
    if (ok) Navigator.pop(context, updated);
  }

  /* ────────────────────── UI ────────────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBar,
        title: const Text('Detalle del Vehículo', style: TextStyle(color: _kTextMain)),
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /* foto ─────────────────────────── */
              GestureDetector(
                onTap: () async {
                  final f = await _pickFile();
                  if (f != null) setState(() => _pickedImg = f);
                },
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(_kRadius),
                    image: _pickedImg != null
                        ? DecorationImage(image: FileImage(_pickedImg!), fit: BoxFit.cover)
                        : (_thumbnail(v.vehicleImage) != null
                        ? DecorationImage(image: _thumbnail(v.vehicleImage)!, fit: BoxFit.cover)
                        : null),
                  ),
                  alignment: Alignment.center,
                  child: (_pickedImg == null && _thumbnail(v.vehicleImage) == null)
                      ? const Text('Toca para añadir foto', style: TextStyle(color: _kTextSub))
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              /* datos básicos ────────────────── */
              _sectionLabel('Datos generales'),
              _field('Placa',  _plateC, validator: _required),
              Row(children: [
                Expanded(child: _field('Marca', _brandC, validator: _required)),
                const SizedBox(width: 12),
                Expanded(child: _field('Modelo', _modelC, validator: _required)),
              ]),
              Row(children: [
                Expanded(child: _field('Año', _yearC, kb: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _field('Color', _colorC)),
              ]),
              Row(children: [
                Expanded(child: _field('Capacidad (pax)', _seatC, kb: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _field('Estado', _statusC)),
              ]),

              /* mantenimiento ────────────────── */
              const SizedBox(height: 10),
              _sectionLabel('Mantenimiento'),
              _field('Última inspección', _inspC, readOnly: true),
              Row(children: [
                Expanded(child: _field('GPS Sensor ID', _gpsC)),
                const SizedBox(width: 12),
                Expanded(child: _field('Speed Sensor ID', _speedC)),
              ]),

              /* asignación ───────────────────── */
              const SizedBox(height: 10),
              _sectionLabel('Asignación'),
              _field('Conductor', _driverC),

              /* documentos ───────────────────── */
              const SizedBox(height: 10),
              _sectionLabel('Documentos'),
              Wrap(
                runSpacing: 8,
                spacing: 8,
                children: [
                  _docButton('SOAT', _pickedSoat, (f) => setState(() => _pickedSoat = f)),
                  _docButton('Tarjeta Prop.', _pickedCard, (f) => setState(() => _pickedCard = f)),
                ],
              ),

              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save, color: Colors.black),
                  label: const Text('Guardar cambios', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAction,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ───────────────── widgets auxiliares ───────────────── */
  Widget _field(String lbl, TextEditingController c,
      {TextInputType kb = TextInputType.text,
        bool readOnly = false,
        String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        readOnly: readOnly,
        keyboardType: kb,
        validator: validator,
        style: const TextStyle(color: _kTextMain),
        decoration: _dec(lbl, date: readOnly),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(color: _kTextSub, fontSize: 13)),
  );

  Widget _docButton(String lbl, File? f, void Function(File) setFile) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await _pickFile();
        if (picked != null) setFile(picked);
      },
      icon: Icon(f == null ? Icons.upload : Icons.check_circle, color: _kAction),
      label: Text(lbl, style: const TextStyle(color: _kTextSub)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _kAction),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
      ),
    );
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  /* ---------------- Drawer ---------------- */
  Drawer _buildDrawer() => Drawer(
    backgroundColor: const Color(0xFF2C2F38),
    child: ListView(padding: EdgeInsets.zero, children: [
      DrawerHeader(
        child: Column(children: [
          Image.asset('assets/images/login_logo.png', height: 100),
          const SizedBox(height: 10),
          Text('${widget.name} ${widget.lastName} - Gerente',
              style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ]),
      ),
      _dItem(Icons.person, 'PERFIL',
          ProfileScreen(name: widget.name, lastName: widget.lastName)),
      _dItem(
          Icons.people,
          'TRANSPORTISTAS',
          CarrierProfilesScreen(
              name: widget.name, lastName: widget.lastName)),
      _dItem(Icons.report, 'REPORTES',
          ReportsScreen(name: widget.name, lastName: widget.lastName)),
      _dItem(Icons.directions_car, 'VEHÍCULOS',
          VehiclesScreen(name: widget.name, lastName: widget.lastName)),
      _dItem(Icons.local_shipping, 'ENVIOS',
          ShipmentsScreen(name: widget.name, lastName: widget.lastName)),
      const SizedBox(height: 160),
      ListTile(
        leading: const Icon(Icons.logout, color: Colors.white),
        title: const Text('CERRAR SESIÓN',
            style: TextStyle(color: Colors.white)),
        onTap: () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(
                onLoginClicked: (_, __) {}, onRegisterClicked: () {}),
          ),
              (_) => false,
        ),
      ),
    ]),
  );

  Widget _dItem(IconData i, String t, Widget p) => ListTile(
    leading: Icon(i, color: Colors.white),
    title: Text(t, style: const TextStyle(color: Colors.white)),
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => p)),
  );
}
