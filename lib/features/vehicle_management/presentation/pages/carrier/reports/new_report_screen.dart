import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/reports/reports_carrier_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/shipments/shipments_screen2.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/vehicle/vehicle_detail_carrier_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/profile/profile_screen2.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';

import '../../../../../../core/widgets/app_drawer2.dart';

class NewReportScreen extends StatefulWidget {
  final String name;
  final String lastName;

  const NewReportScreen({
    Key? key,
    required this.name,
    required this.lastName,
  }) : super(key: key);

  @override
  _NewReportScreenState createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen>
    with SingleTickerProviderStateMixin {
  // form state
  String? _selectedReportType;
  String? _mediaBase64;
  String _mediaFileName = '';
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _reportTypes = [
    'Problemas con el vehículo',
    'Tráfico',
    'Accidente en autopista',
    'Otro'
  ];

  // servicio de reportes
  final ReportService _reportService = ReportService();

  // datos heredados del perfil
  bool _loadingProfile = true;
  String _companyName = '';
  String _companyRuc = '';
  int?  _userId;

  // animación
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    // arrancamos la carga de companyName, companyRuc y userId
    _loadManagerData();
  }

  Future<void> _loadManagerData() async {
    const base = '${AppConstants.baseUrl}${AppConstants.profile}';
    try {
      final res = await http.get(Uri.parse(base));
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List;
        final me = list.firstWhere(
              (e) =>
          e['name'].toString().toLowerCase()     == widget.name.toLowerCase() &&
              e['lastName'].toString().toLowerCase() == widget.lastName.toLowerCase(),
          orElse: () => null,
        );
        if (me != null) {
          _companyName = me['companyName'] ?? '';
          _companyRuc  = me['companyRuc']  ?? '';
          _userId      = me['id']          as int?;
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String> _getLocation() async {
    // futuro: implementar GPS
    return 'Ubicación no encontrada';
  }

  Future<String> _getVehiclePlate() async {
    try {
      final res = await http.get(
          Uri.parse('${AppConstants.baseUrl}${AppConstants.vehicle}')
      );
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List;
        final match = list.firstWhere(
              (v) => v['driverName']
              .toString()
              .trim()
              .toLowerCase() ==
              '${widget.name} ${widget.lastName}'.toLowerCase(),
          orElse: () => null,
        );
        if (match != null && match['licensePlat'] != null) {
          return match['licensePlat'];
        }
      }
    } catch (_) {}
    return 'No se encontró vehículo registrado';
  }

  Future<void> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      withData: true,
    );
    if (result != null) {
      final file = result.files.single;
      setState(() {
        _mediaFileName =
            file.name;
        _mediaBase64 =
        file.bytes != null ? base64Encode(file.bytes!) : null;
      });
    }
  }

  Future<void> _createReport() async {
    if (_loadingProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargando datos de la empresa…')),
      );
      return;
    }
    if (_selectedReportType == null ||
        _descriptionController.text.isEmpty ||
        _mediaBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Por favor, completa tipo, descripción y adjunta foto/video'
          ),
        ),
      );
      return;
    }

    final driverName  = '${widget.name} ${widget.lastName}';
    final status      = 'Pendiente';
    final location    = await _getLocation();
    final vehiclePlate= await _getVehiclePlate();

    final newReport = ReportModel(
      id: null,
      userId:       _userId ?? 1,
      type:         _selectedReportType!,
      description:  _descriptionController.text,
      driverName:   driverName,
      createdAt:    DateTime.now(),
      photoOrVideo: _mediaBase64!,
      status:       status,
      location:     location,
      vehiclePlate: vehiclePlate,
      companyName:  _companyName,
      companyRuc:   _companyRuc,
    );

    final success = await _reportService.createReport(newReport);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte creado exitosamente')),
      );
      Navigator.pop(context, newReport);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear el reporte')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // mientras cargan los datos del perfil mostramos un loader
    if (_loadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1F24),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFEA8E00)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Reporte', style: TextStyle(color: Colors.grey)),
        backgroundColor: const Color(0xFF2C2F38),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1A1F24),
      drawer: AppDrawer2(name: widget.name, lastName: widget.lastName),
      body: FadeTransition(
        opacity: _animationController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Expanded(child: _buildReportForm()),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportForm() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2F38),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'Detalles del Reporte',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Tipo de Reporte',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF1A1F24),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            dropdownColor: const Color(0xFF1A1F24),
            value: _selectedReportType,
            items: _reportTypes.map((t) {
              return DropdownMenuItem(
                value: t,
                child: Text(t, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedReportType = v),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Descripción',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF1A1F24),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Foto/Video de incidencia',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _pickMedia,
            icon: const Icon(Icons.attach_file),
            label: const Text('Seleccionar archivo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA8E00),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)
              ),
            ),
          ),
          if (_mediaFileName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _mediaFileName,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildSubmitButton() => ElevatedButton(
    onPressed: _createReport,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFEA8E00),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      minimumSize: const Size(double.infinity, 50),
      padding: const EdgeInsets.symmetric(vertical: 16),
      elevation: 5,
    ),
    child: const Text('Crear Nuevo Reporte', style: TextStyle(color: Colors.black)),
  );

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2C2F38),
      child: ListView(padding: EdgeInsets.zero, children: [
        DrawerHeader(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/login_logo.png', height: 80),
              const SizedBox(height: 10),
              Text('${widget.name} ${widget.lastName}',
                  style: const TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        ),
        _buildDrawerItem(Icons.person, 'PERFIL', () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen2(
                name: widget.name,
                lastName: widget.lastName,
              ),
            ),
          );
        }),
        _buildDrawerItem(Icons.report, 'REPORTES', () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportsCarrierScreen(
                name: widget.name,
                lastName: widget.lastName,
              ),
            ),
          );
        }),
        _buildDrawerItem(Icons.directions_car, 'VEHÍCULOS', () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VehicleDetailCarrierScreen(
                name: widget.name,
                lastName: widget.lastName,
              ),
            ),
          );
        }),
        _buildDrawerItem(Icons.local_shipping, 'ENVIOS', () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShipmentsScreen2(
                name: widget.name,
                lastName: widget.lastName,
              ),
            ),
          );
        }),
        const Divider(color: Colors.white54),
        _buildDrawerItem(Icons.logout, 'CERRAR SESIÓN', () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => LoginScreen(
                onLoginClicked: (_, __) {},
                onRegisterClicked: () {},
              ),
            ),
                (route) => false,
          );
        }),
      ]),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        onTap: onTap,
      );
}
