import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_service.dart';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../../core/widgets/app_drawer.dart';

/// ------------------------------------------------------------------
///           PANTALLA DE REGISTRO DE VEHÍCULO - VERSIÓN MEJORADA
/// ------------------------------------------------------------------
/// Esta pantalla permite registrar un nuevo vehículo. Características de usabilidad:
/// - Formulario agrupado en secciones lógicas para reducir la carga cognitiva.
/// - Previsualización de la imagen del vehículo una vez cargada.
/// - Opción para ver los documentos (SOAT, Tarjeta de Propiedad) antes de enviarlos.
/// - Feedback claro sobre el estado de la carga de archivos y el proceso de guardado.
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
  // --- Services & Keys ---
  final _svc = VehicleService();
  final _profile = ProfileService();
  final _fmt = DateFormat('yyyy-MM-dd');
  final _formKey = GlobalKey<FormState>();

  // --- UI State ---
  bool _saving = false;

  // --- Controllers ---
  final _plateC = TextEditingController();
  final _brandC = TextEditingController();
  final _modelC = TextEditingController();
  final _yearC = TextEditingController();
  final _colorC = TextEditingController();
  final _seatC = TextEditingController();
  final _gpsC = TextEditingController();
  final _spdC = TextEditingController();
  final _drvC = TextEditingController();
  late final TextEditingController _inspC;

  // --- File State ---
  PlatformFile? _vehicleImageFile;
  PlatformFile? _soatFile;
  PlatformFile? _ownershipCardFile;

  // --- Company Data ---
  String _companyName = '';
  String _companyRuc = '';

  @override
  void initState() {
    super.initState();
    _inspC = TextEditingController(text: _fmt.format(DateTime.now()));
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    final prof = await _profile.getProfileByNameAndLastName(
      widget.name,
      widget.lastName,
    );
    if (!mounted) return;
    setState(() {
      _companyName = prof?.companyName ?? '';
      _companyRuc = prof?.companyRuc ?? '';
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

  // ===================== UI Helper Widgets =====================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFFEA8E00),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label),
        validator: isRequired ? (v) => v == null || v.trim().isEmpty ? 'Este campo es requerido' : null : null,
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label).copyWith(
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xFFEA8E00)),
            onPressed: () => _pickDate(controller),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Seleccione una fecha' : null,
      ),
    );
  }

  Widget _buildImageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () => _pickFile(
              (file) => setState(() => _vehicleImageFile = file),
          type: FileType.image,
        ),
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF2F353F),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: _vehicleImageFile == null
              ? const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 40),
              SizedBox(height: 8),
              Text('Subir Imagen del Vehículo', style: TextStyle(color: Colors.white70)),
            ],
          )
              : Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(_vehicleImageFile!.bytes!, fit: BoxFit.cover),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => setState(() => _vehicleImageFile = null),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileInput({
    required String label,
    required IconData icon,
    required PlatformFile? currentFile,
    required void Function(PlatformFile?) onFilePicked,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2F353F),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white24),
        ),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFFEA8E00)),
          title: Text(
            currentFile == null ? label : currentFile.name,
            style: TextStyle(color: currentFile == null ? Colors.white70 : Colors.white, fontStyle: currentFile == null ? FontStyle.italic : FontStyle.normal),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: currentFile != null
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blueAccent),
                tooltip: 'Ver archivo',
                onPressed: () => _viewFile(currentFile),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                tooltip: 'Quitar archivo',
                onPressed: () => onFilePicked(null),
              ),
            ],
          )
              : const Icon(Icons.upload_file, color: Colors.white70),
          onTap: currentFile == null ? () => _pickFile(onFilePicked, type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg']) : null,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF2F353F),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFEA8E00))),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }

  // ===================== Logic Helpers =====================

  Future<void> _pickDate(TextEditingController ctl) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFEA8E00), onPrimary: Colors.white, surface: Color(0xFF2C2F38), onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) ctl.text = _fmt.format(d);
  }

  Future<void> _pickFile(void Function(PlatformFile?) onFilePicked, {FileType type = FileType.any, List<String>? allowedExtensions}) async {
    final result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() => onFilePicked(result.files.single));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.files.single.name} cargado.'), backgroundColor: Colors.green),
        );
      }
    }
  }

// Reemplaza tu función _viewFile existente con esta:
  Future<void> _viewFile(PlatformFile file) async {
    // Usamos getTemporaryDirectory() porque es compatible con todas las plataformas (móvil, escritorio y web).
    // Es el lugar ideal para archivos que no necesitan persistir.
    try {
      // 1. Obtener el directorio temporal
      final Directory dir = await getTemporaryDirectory();

      // 2. Crear la ruta completa del archivo temporal
      final String tempPath = '${dir.path}/${file.name}';
      final File tempFile = File(tempPath);

      // 3. Escribir los bytes del archivo cargado en el archivo temporal
      await tempFile.writeAsBytes(file.bytes!);

      // 4. Usar open_filex para abrir el archivo.
      // open_filex también necesita que la app se reinicie por completo la primera vez que se añade.
      final result = await OpenFilex.open(tempPath);

      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se encontró una aplicación para abrir este archivo: ${result.message}'), backgroundColor: Colors.orangeAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al previsualizar el archivo: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // ===================== Form Submission =====================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, complete todos los campos requeridos.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }
    if (_soatFile == null || _ownershipCardFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe cargar el SOAT y la Tarjeta de Propiedad.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    setState(() => _saving = true);

    final vehicle = VehicleModel(
      licensePlate: _plateC.text.trim(),
      brand: _brandC.text.trim(),
      model: _modelC.text.trim(),
      year: int.tryParse(_yearC.text.trim()) ?? DateTime.now().year,
      color: _colorC.text.trim(),
      seatingCapacity: int.tryParse(_seatC.text.trim()) ?? 0,
      lastTechnicalInspectionDate: _fmt.parse(_inspC.text),
      gpsSensorId: _gpsC.text.trim(),
      speedSensorId: _spdC.text.trim(),
      status: 'Activo',
      driverName: _drvC.text.trim(),
      companyName: _companyName,
      companyRuc: _companyRuc,
      vehicleImage: _vehicleImageFile != null ? base64Encode(_vehicleImageFile!.bytes!) : '',
      documentSoat: base64Encode(_soatFile!.bytes!),
      documentVehicleOwnershipCard: base64Encode(_ownershipCardFile!.bytes!),
      assignedDriverId: null,
      assignedAt: DateTime.now(),
      dateToGoTheWorkshop: null,
      lastLocation: null,
      lastSpeed: null,
    );

    final ok = await _svc.createVehicle(vehicle);
    if (!mounted) return;

    setState(() => _saving = false);

    if (ok) {
      widget.onVehicleAdded(vehicle);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehículo registrado con éxito'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar el vehículo'), backgroundColor: Colors.redAccent),
      );
    }
  }

  // ===================== Main Build Method =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F24),
      appBar: AppBar(
        title: const Text('Registrar Nuevo Vehículo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1F24),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: AppDrawer(name: widget.name, lastName: widget.lastName),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            _buildSectionHeader('Información del Vehículo'),
            _buildTextField('Placa', _plateC),
            _buildTextField('Marca', _brandC),
            _buildTextField('Modelo', _modelC),
            _buildTextField('Año', _yearC, keyboardType: TextInputType.number),
            _buildTextField('Color', _colorC),
            _buildTextField('Capacidad de Asientos', _seatC, keyboardType: TextInputType.number),
            _buildTextField('Nombre del Conductor Asignado', _drvC),



            _buildSectionHeader('Documentación'),
            _buildDateField('Fecha de Última Inspección Técnica', _inspC),
            _buildImageInput(),
            _buildFileInput(
              label: 'Documento SOAT (Obligatorio)',
              icon: Icons.shield_outlined,
              currentFile: _soatFile,
              onFilePicked: (file) => setState(() => _soatFile = file),
            ),
            _buildFileInput(
              label: 'Tarjeta de Propiedad (Obligatorio)',
              icon: Icons.description_outlined,
              currentFile: _ownershipCardFile,
              onFilePicked: (file) => setState(() => _ownershipCardFile = file),
            ),

            const SizedBox(height: 32),
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ===================== Action Buttons & Drawer =====================

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white60),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA8E00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: _saving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Registrar'),
          ),
        ),
      ],
    );
  }

}