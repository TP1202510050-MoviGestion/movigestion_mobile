import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../../core/widgets/app_drawer.dart';
import '../../../../data/remote/vehicle_model.dart';
import '../../../../data/remote/vehicle_service.dart';


// --- Constantes de Estilo ---
const _kBg = Color(0xFF1E1F24);
const _kCard = Color(0xFF2F353F);
const _kBar = Color(0xFF2C2F38);
const _kAction = Color(0xFFEA8E00);
const _kTextMain = Colors.white;
const _kTextSub = Colors.white70;
const _kRadius = 12.0;

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
  // --- Controllers, Services & Keys ---
  late final _plateC = TextEditingController(text: v.licensePlate);
  late final _brandC = TextEditingController(text: v.brand);
  late final _modelC = TextEditingController(text: v.model);
  late final _yearC = TextEditingController(text: v.year.toString());
  late final _colorC = TextEditingController(text: v.color);
  late final _seatC = TextEditingController(text: v.seatingCapacity.toString());
  late final _statusC = TextEditingController(text: v.status);
  late final _gpsC = TextEditingController(text: v.gpsSensorId);
  late final _speedC = TextEditingController(text: v.speedSensorId);
  late final _driverC = TextEditingController(text: v.driverName);
  late final _inspC = TextEditingController(text: _fmt.format(v.lastTechnicalInspectionDate));

  final _formKey = GlobalKey<FormState>();
  final _fmt = DateFormat('yyyy-MM-dd');
  final _picker = ImagePicker();
  final _svc = VehicleService();

  // --- State for new/updated files ---
  File? _pickedImg, _pickedSoat, _pickedCard;

  VehicleModel get v => widget.vehicle;

  // ===================== Logic Helpers =====================

  ImageProvider? _thumbnail(String raw) {
    if (raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return NetworkImage(raw);
    try {
      return MemoryImage(base64Decode(base64.normalize(raw)));
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDate(TextEditingController c) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(c.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
              primary: _kAction, surface: _kCard, onSurface: _kTextMain, onPrimary: _kTextMain),
        ),
        child: child!,
      ),
    );
    if (d != null) c.text = _fmt.format(d);
  }

  Future<File?> _pickImageFile() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    return x != null ? File(x.path) : null;
  }

  Future<File?> _pickDocumentFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<void> _viewFile(dynamic fileData, String defaultFileName) async {
    try {
      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/$defaultFileName');

      if (fileData is File) {
        await tempFile.writeAsBytes(await fileData.readAsBytes());
      } else if (fileData is String && fileData.isNotEmpty) {
        await tempFile.writeAsBytes(base64Decode(base64.normalize(fileData)));
      } else {
        return;
      }

      final result = await OpenFilex.open(tempFile.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el archivo: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al previsualizar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ===================== Form Submission =====================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: _kAction)),
    );

    final updated = v.copyWith(
      licensePlate: _plateC.text.trim(),
      brand: _brandC.text.trim(),
      model: _modelC.text.trim(),
      year: int.tryParse(_yearC.text.trim()) ?? v.year,
      color: _colorC.text.trim(),
      seatingCapacity: int.tryParse(_seatC.text.trim()) ?? v.seatingCapacity,
      status: _statusC.text.trim(),
      gpsSensorId: _gpsC.text.trim(),
      speedSensorId: _speedC.text.trim(),
      driverName: _driverC.text.trim(),
      lastTechnicalInspectionDate: _fmt.parse(_inspC.text),
      vehicleImage: _pickedImg != null ? base64Encode(_pickedImg!.readAsBytesSync()) : v.vehicleImage,
      documentSoat: _pickedSoat != null ? base64Encode(_pickedSoat!.readAsBytesSync()) : v.documentSoat,
      documentVehicleOwnershipCard: _pickedCard != null ? base64Encode(_pickedCard!.readAsBytesSync()) : v.documentVehicleOwnershipCard,
    );

    final ok = await _svc.updateVehicle(v.id!, updated);

    if (!mounted) return;

    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? Colors.green : Colors.redAccent,
        content: Text(ok ? 'Vehículo actualizado con éxito' : 'Error al guardar los cambios'),
      ),
    );
    if (ok) Navigator.pop(context, updated);
  }

  // ===================== Main Build Method =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBar,
        title: const Text('Detalle del Vehículo', style: TextStyle(color: _kTextMain)),
        iconTheme: const IconThemeData(color: _kTextMain),
      ),
      drawer: AppDrawer(name: widget.name, lastName: widget.lastName),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GestureDetector(
                onTap: () async {
                  final f = await _pickImageFile();
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
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: _kTextSub, size: 40),
                      SizedBox(height: 8),
                      Text('Toca para cambiar la foto', style: TextStyle(color: _kTextSub)),
                    ],
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              _sectionLabel('Datos generales'),
              _field('Placa', _plateC, validator: _required),
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

              _sectionLabel('Mantenimiento'),
              _field('Última inspección', _inspC, isDate: true),
              Row(children: [
                Expanded(child: _field('GPS Sensor ID', _gpsC)),
                const SizedBox(width: 12),
                Expanded(child: _field('Speed Sensor ID', _speedC)),
              ]),

              _sectionLabel('Asignación'),
              _field('Conductor', _driverC),

              _sectionLabel('Documentos'),
              _buildDocumentTile(
                label: 'SOAT',
                existingData: v.documentSoat,
                pickedFile: _pickedSoat,
                onFilePicked: (file) => setState(() => _pickedSoat = file),
              ),
              _buildDocumentTile(
                label: 'Tarjeta de Propiedad',
                existingData: v.documentVehicleOwnershipCard,
                pickedFile: _pickedCard,
                onFilePicked: (file) => setState(() => _pickedCard = file),
              ),

              const SizedBox(height: 32),
              _buildActionButtons(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== UI Helper Widgets =====================

  Widget _field(String lbl, TextEditingController c, {TextInputType kb = TextInputType.text, bool isDate = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        readOnly: isDate,
        keyboardType: kb,
        validator: validator,
        style: const TextStyle(color: _kTextMain),
        decoration: InputDecoration(
          labelText: lbl,
          labelStyle: const TextStyle(color: _kTextSub),
          filled: true,
          fillColor: _kCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(_kRadius), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_kRadius), borderSide: const BorderSide(color: _kAction)),
          suffixIcon: isDate
              ? IconButton(
            icon: const Icon(Icons.calendar_today, color: _kAction),
            onPressed: () => _pickDate(c),
          )
              : const Icon(Icons.edit, color: _kTextSub, size: 20),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 12),
    child: Text(text, style: const TextStyle(color: _kAction, fontSize: 14, fontWeight: FontWeight.bold)),
  );

  Widget _buildDocumentTile({
    required String label,
    required String existingData,
    required File? pickedFile,
    required ValueChanged<File?> onFilePicked,
  }) {
    final hasExistingData = existingData.isNotEmpty;
    final hasPickedFile = pickedFile != null;
    final dataToShow = hasPickedFile ? pickedFile : (hasExistingData ? existingData : null);

    return Card(
      color: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(
          hasPickedFile ? Icons.check_circle : (hasExistingData ? Icons.description : Icons.upload_file),
          color: _kAction,
        ),
        title: Text(
          hasPickedFile ? pickedFile.path.split('/').last : label,
          style: const TextStyle(color: _kTextMain),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: hasPickedFile
            ? const Text('Nuevo archivo listo para guardar', style: TextStyle(color: Colors.greenAccent))
            : (hasExistingData
            ? const Text('Documento registrado', style: TextStyle(color: _kTextSub))
            : const Text('No hay documento cargado', style: TextStyle(color: _kTextSub))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dataToShow != null)
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blueAccent),
                tooltip: 'Ver documento',
                onPressed: () => _viewFile(dataToShow, '${label.replaceAll(' ', '_')}.pdf'),
              ),
            IconButton(
              icon: Icon(hasExistingData || hasPickedFile ? Icons.replay : Icons.upload),
              tooltip: hasExistingData || hasPickedFile ? 'Reemplazar' : 'Subir',
              color: _kTextSub,
              onPressed: () async {
                final file = await _pickDocumentFile();
                onFilePicked(file);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kTextSub),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text('Cerrar', style: TextStyle(color: _kTextSub)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, color: Colors.black),
            label: const Text(
              'Guardar cambios',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAction,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
          ),
        ),
      ],
    );
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Este campo es requerido' : null;


}