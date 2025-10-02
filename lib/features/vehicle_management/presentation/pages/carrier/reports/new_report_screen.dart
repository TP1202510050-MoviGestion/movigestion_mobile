// lib/features/vehicle_management/presentation/pages/carrier/reports/new_report_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_service.dart';
import '../../../../../../core/widgets/app_drawer2.dart';

// PASO 1: Usar las constantes de estilo unificadas
const _kBg = Color(0xFF1E1F24);
const _kCard = Color(0xFF2F353F);
const _kBar = Color(0xFF2C2F38);
const _kAction = Color(0xFFEA8E00);
const _kTextMain = Colors.white;
const _kTextSub = Colors.white70;
const _kRadius = 12.0;

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

class _NewReportScreenState extends State<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedReportType;
  File? _pickedMediaFile;
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _reportTypes = [
    'Problemas con el vehículo',
    'Tráfico',
    'Accidente en autopista',
    'Otro'
  ];

  final ReportService _reportService = ReportService();
  bool _loadingProfile = true;
  bool _isCreating = false;
  String _companyName = '';
  String _companyRuc = '';
  int? _userId;


  // PASO 2: Añadir estado para los datos del gerente
  String? _managerName;
  String? _managerPhone;
  String? _managerPhotoB64;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // PASO 3: Actualizar la carga de datos para incluir al gerente
  Future<void> _loadProfileData() async {
    const base = '${AppConstants.baseUrl}${AppConstants.profile}';
    try {
      final res = await http.get(Uri.parse(base));
      if (res.statusCode == 200) {
        final decodedBody = utf8.decode(res.bodyBytes);
        final list = json.decode(decodedBody) as List;

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

          // Ahora, buscar al gerente de la misma empresa
          final manager = list.firstWhere(
                (e) =>
            e['companyName'] == _companyName &&
                e['companyRuc']  == _companyRuc  &&
                e['type'] == 'Gerente',
            orElse: () => null,
          );

          if (manager != null) {
            _managerName = '${manager['name']} ${manager['lastName']}';
            _managerPhone = manager['phone'];
            _managerPhotoB64 = manager['profilePhoto'];
          }
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
    _descriptionController.dispose();
    super.dispose();
  }


  // PASO 4: Crear la función para realizar llamadas
  Future<void> _makeCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showMessage('Número de teléfono no disponible.');
      return;
    }
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showMessage('No se pudo realizar la llamada.');
    }
  }

  Future<String> _getLocation() async => 'Ubicación no encontrada';

  Future<String> _getVehiclePlate() async {
    // Lógica para obtener placa sin cambios...
    try {
      final res = await http.get(Uri.parse('${AppConstants.baseUrl}${AppConstants.vehicle}'));
      if (res.statusCode == 200) {
        final decodedBody = utf8.decode(res.bodyBytes);
        final list = json.decode(decodedBody) as List;
        final match = list.firstWhere(
              (v) => (v['driverName'] ?? '').toString().trim().toLowerCase() == '${widget.name} ${widget.lastName}'.toLowerCase(),
          orElse: () => null,
        );
        if (match != null && match['licensePlate'] != null) {
          return match['licensePlate'];
        }
      }
    } catch (_) {}
    return 'No se encontró vehículo registrado';
  }

  Future<void> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.media);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedMediaFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _createReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedMediaFile == null) {
      _showMessage('Por favor, adjunta una foto o video como evidencia.');
      return;
    }

    setState(() => _isCreating = true);

    final newReport = ReportModel(
      userId:       _userId!,
      type:         _selectedReportType!,
      description:  _descriptionController.text.trim(),
      driverName:   '${widget.name} ${widget.lastName}',
      createdAt:    DateTime.now(),
      photoOrVideo: base64Encode(_pickedMediaFile!.readAsBytesSync()),
      status:       'Pendiente',
      location:     await _getLocation(),
      vehiclePlate: await _getVehiclePlate(),
      companyName:  _companyName,
      companyRuc:   _companyRuc,
    );

    try {
      final success = await _reportService.createReport(newReport);
      if (success) {
        _showMessage('Reporte creado exitosamente', isError: false);
        Navigator.pop(context, true);
      } else {
        _showMessage('Error al crear el reporte. Inténtalo de nuevo.');
      }
    } catch (e) {
      _showMessage('Error de conexión al crear el reporte: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showMessage(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      // PASO 2: Rediseñar la AppBar
      appBar: AppBar(
        backgroundColor: _kBar,
        title: const Text('Nuevo Reporte', style: TextStyle(color: _kTextMain)),
        iconTheme: const IconThemeData(color: _kTextMain),
      ),
      drawer: AppDrawer2(name: widget.name, lastName: widget.lastName),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: _kAction))
          : _buildForm(),
      // PASO 4: Rediseñar el botón de envío
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  // PASO 3: Refactorizar completamente el formulario
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildEmergencyCallsCard(),
          _buildSectionCard(
            title: 'Detalles del Reporte',
            icon: Icons.edit_note,
            children: [
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Tipo de Reporte'),
                dropdownColor: _kCard,
                value: _selectedReportType,
                items: _reportTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _selectedReportType = v),
                style: const TextStyle(color: _kTextMain),
                validator: (v) => v == null ? 'Por favor, selecciona un tipo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: _inputDecoration('Descripción del incidente'),
                style: const TextStyle(color: _kTextMain),
                validator: (v) => v == null || v.trim().isEmpty ? 'La descripción es requerida' : null,
              ),
            ],
          ),
          _buildSectionCard(
            title: 'Evidencia',
            icon: Icons.camera_alt_outlined,
            children: [
              Center(
                child: OutlinedButton.icon(
                  onPressed: _pickMedia,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Adjuntar Foto o Video'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kAction,
                    side: const BorderSide(color: _kAction),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
              if (_pickedMediaFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: Chip(
                      avatar: const Icon(Icons.check_circle, color: Colors.green),
                      label: Text(
                        _pickedMediaFile!.path.split('/').last,
                        style: const TextStyle(color: _kTextSub),
                      ),
                      backgroundColor: _kBg,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }


  // PASO 5 (cont.): Implementar el widget para la nueva tarjeta de llamadas
  Widget _buildEmergencyCallsCard() {
    ImageProvider managerImage = const AssetImage('assets/images/Gerente.png'); // Imagen por defecto
    if (_managerPhotoB64 != null && _managerPhotoB64!.isNotEmpty) {
      managerImage = MemoryImage(base64Decode(_managerPhotoB64!));
    }

    return Card(
      color: _kCard,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.contact_phone_outlined, color: _kAction, size: 20),
                SizedBox(width: 8),
                Text('Contactos de Emergencia', style: TextStyle(color: _kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24, color: _kBg),
            ListTile(
              leading: const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.local_hospital, color: _kTextMain),
              ),
              title: const Text('Llamar a Emergencias', style: TextStyle(color: _kTextMain, fontWeight: FontWeight.w500)),
              subtitle: const Text('Número Nacional', style: TextStyle(color: _kTextSub)),
              trailing: const Icon(Icons.call, color: Colors.redAccent),
              onTap: () => _makeCall('112'), // Número de emergencia genérico
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: managerImage,
                backgroundColor: _kBg,
              ),
              title: Text(_managerName ?? 'Gerente', style: const TextStyle(color: _kTextMain, fontWeight: FontWeight.w500)),
              subtitle: Text(_managerPhone ?? 'Número no disponible', style: TextStyle(color: _kTextSub)),
              trailing: Icon(Icons.call, color: _kAction),
              onTap: () => _makeCall(_managerPhone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      color: _kCard,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _kAction, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: _kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24, color: _kBg),
            ...children,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kTextSub),
      filled: true,
      fillColor: _kBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_kRadius), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_kRadius), borderSide: const BorderSide(color: _kAction)),
    );
  }

  Widget _buildSubmitButton() {
    // ESTE ES EL DISEÑO ADAPTADO DE RouteDriverDetailScreen
    return Padding(
      // Usamos un padding para separar el botón de los bordes de la pantalla
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kAction,
          foregroundColor: Colors.black, // Color del texto y el icono
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        // Construimos el contenido del botón con un Row centrado
        child: _isCreating
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.black,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send),
            SizedBox(width: 12),
            Text(
              'Enviar Reporte',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}