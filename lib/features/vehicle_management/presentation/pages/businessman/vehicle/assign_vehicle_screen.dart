import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_service.dart';

/*  pantallas para el Drawer */
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/profile/profile_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/carrier_profiles/carrier_profiles.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/reports/reports_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/vehicle/vehicles_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/shipments/shipments_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';

/// ------------------------------------------------------------------
///                        ASSIGN  VEHICLE  SCREEN
/// ------------------------------------------------------------------
class AssignVehicleScreen extends StatefulWidget {
  final void Function(VehicleModel) onVehicleAdded;
  final String name, lastName;

  const AssignVehicleScreen({
    super.key,
    required this.onVehicleAdded,
    required this.name,
    required this.lastName,
  });

  @override
  State<AssignVehicleScreen> createState() => _AssignVehicleScreenState();
}

class _AssignVehicleScreenState extends State<AssignVehicleScreen> {
  /* ------------ services & utils ------------ */
  final _svc     = VehicleService();
  final _profile = ProfileService();
  final _fmt     = DateFormat('yyyy-MM-dd');
  final _formKey = GlobalKey<FormState>();

  /* ------------- UI state ------------- */
  bool _saving = false;                       // ← indicador de carga

  /* ------------- text-controllers ------------- */
  final _plateC = TextEditingController();
  final _brandC = TextEditingController();
  final _modelC = TextEditingController();
  final _yearC  = TextEditingController();
  final _colorC = TextEditingController();
  final _seatC  = TextEditingController();
  final _gpsC   = TextEditingController();
  final _spdC   = TextEditingController();
  final _drvC   = TextEditingController();
  late final TextEditingController _inspC;    // fecha última inspección

  /* ------------- archivos en base-64 ------------- */
  String? _img64, _soat64, _card64;

  /* ------------- datos empresa ------------- */
  String _companyName = '';
  String _companyRuc  = '';

  /* ====================== init ====================== */
  @override
  void initState() {
    super.initState();
    _inspC = TextEditingController(text: _fmt.format(DateTime.now()));
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    final prof = await _profile.getProfileByNameAndLastName(
      widget.name, widget.lastName,
    );
    if (!mounted) return;
    setState(() {
      _companyName = prof?.companyName ?? '';
      _companyRuc  = prof?.companyRuc  ?? '';
    });
  }

  @override
  void dispose() {
    for (final c in [
      _plateC, _brandC, _modelC, _yearC, _colorC,
      _seatC, _gpsC, _spdC, _drvC, _inspC,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /* ===================== helpers UI ===================== */
  Future<void> _pickDate(TextEditingController ctl) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate : DateTime(2000),
      lastDate  : DateTime(2100),
      builder   : (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary  : Color(0xFFEA8E00),
            onPrimary: Colors.white,
            surface  : Color(0xFF2C2F38),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) ctl.text = _fmt.format(d);
  }

  Future<void> _pickFile(void Function(String) save) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (res?.files.single.bytes != null) {
      save(base64Encode(res!.files.single.bytes!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Archivo cargado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /* ---------- campos de texto y fecha ---------- */
  Widget _txt(String lbl, TextEditingController c,
      {TextInputType kb = TextInputType.text}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: kb,
          style: const TextStyle(color: Colors.white),
          decoration: _dec(lbl),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Ingrese $lbl'
              : null,
        ),
      );

  Widget _date(String lbl, TextEditingController c) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          readOnly: true,
          style: const TextStyle(color: Colors.white),
          decoration: _dec(lbl).copyWith(
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today,
                  color: Color(0xFFEA8E00)),
              onPressed: () => _pickDate(c),
            ),
          ),
          validator: (v) => v == null || v.isEmpty
              ? 'Seleccione $lbl'
              : null,
        ),
      );

  InputDecoration _dec(String lbl) => InputDecoration(
    labelText : lbl,
    labelStyle: const TextStyle(color: Colors.white70),
    filled    : true,
    fillColor : const Color(0xFF2F353F),
    border    : OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
    ),
  );

  /* ---------- botón reutilizable para subir archivos ---------- */
  Widget _fileButton(String lbl, IconData icon,
      void Function(String) save) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _pickFile(save),
          icon : Icon(icon, color: Colors.white),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(lbl),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEA8E00),
            foregroundColor: Colors.black,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      );

  /* ---------- fila de acciones Cerrar / Registrar ---------- */
  Widget _actionButtons() => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white60),
            padding:
            const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('Cerrar'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEA8E00),
            foregroundColor: Colors.black,
            padding:
            const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('Registrar'),
        ),
      ),
    ],
  );

  /* ===================== SUBMIT ===================== */
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final vehicle = VehicleModel(
      licensePlate : _plateC.text.trim(),
      brand        : _brandC.text.trim(),
      model        : _modelC.text.trim(),
      year         : int.parse(_yearC.text.trim()),
      color        : _colorC.text.trim(),
      seatingCapacity: int.parse(_seatC.text.trim()),
      lastTechnicalInspectionDate: _fmt.parse(_inspC.text),
      gpsSensorId  : _gpsC.text.trim(),
      speedSensorId: _spdC.text.trim(),
      status       : 'Activo',
      driverName   : _drvC.text.trim(),
      companyName  : _companyName,
      companyRuc   : _companyRuc,
      assignedDriverId: null,
      assignedAt   : DateTime.now(),
      vehicleImage : _img64 ?? '',
      documentSoat : _soat64 ?? '',
      documentVehicleOwnershipCard: _card64 ?? '',
      dateToGoTheWorkshop: null,
      lastLocation : null,
      lastSpeed    : null,
    );

    final ok = await _svc.createVehicle(vehicle);
    if (!mounted) return;

    setState(() => _saving = false);

    if (ok) {
      widget.onVehicleAdded(vehicle);
      Navigator.pop(context);   // regresa a VehiclesScreen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehículo creado'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al crear vehículo'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /* ===================== BUILD ===================== */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F38),
        title: const Text('Asignar Vehículo',
            style: TextStyle(color: Colors.white)),
      ),
      drawer: _buildDrawer(),
      body: IgnorePointer(
        ignoring: _saving,
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _txt('Placa', _plateC),
                  _txt('Marca', _brandC),
                  _txt('Modelo', _modelC),
                  _txt('Año', _yearC, kb: TextInputType.number),
                  _txt('Color', _colorC),
                  _txt('Capacidad (pax)', _seatC,
                      kb: TextInputType.number),
                  _txt('GPS Sensor ID', _gpsC),
                  _txt('Speed Sensor ID', _spdC),
                  _txt('Nombre del conductor', _drvC),
                  const SizedBox(height: 12),
                  _date('Última inspección', _inspC),
                  const SizedBox(height: 12),

                  _fileButton('Imagen del vehículo',
                      Icons.camera_alt, (b) => setState(() => _img64 = b)),
                  const SizedBox(height: 12),
                  _fileButton('Documento SOAT',
                      Icons.upload, (b) => setState(() => _soat64 = b)),
                  const SizedBox(height: 12),
                  _fileButton('Tarjeta de Propiedad',
                      Icons.upload_file, (b) => setState(() => _card64 = b)),

                  const SizedBox(height: 32),
                  _actionButtons(),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            if (_saving)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFEA8E00)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /* ===================== Drawer ===================== */
  Drawer _buildDrawer() => Drawer(
    backgroundColor: const Color(0xFF2C2F38),
    child: ListView(padding: EdgeInsets.zero, children: [
      DrawerHeader(
        child: Column(children: [
          Image.asset('assets/images/login_logo.png', height: 100),
          const SizedBox(height: 10),
          Text('${widget.name} ${widget.lastName} - Gerente',
              style:
              const TextStyle(color: Colors.grey, fontSize: 16)),
        ]),
      ),
      _dItem(Icons.person, 'PERFIL',
          ProfileScreen(name: widget.name, lastName: widget.lastName)),
      _dItem(Icons.people, 'TRANSPORTISTAS',
          CarrierProfilesScreen(name: widget.name, lastName: widget.lastName)),
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
              onLoginClicked: (_, __) {},
              onRegisterClicked: () {},
            ),
          ),
              (_) => false,
        ),
      ),
    ]),
  );

  Widget _dItem(IconData i, String t, Widget p) => ListTile(
    leading: Icon(i, color: Colors.white),
    title: Text(t, style: const TextStyle(color: Colors.white)),
    onTap: () =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => p)),
  );
}
