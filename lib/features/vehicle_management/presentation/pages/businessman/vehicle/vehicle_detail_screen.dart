import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../../core/widgets/app_drawer.dart';
import '../../../../data/remote/profile_service.dart';
import '../../../../data/remote/vehicle_model.dart';
import '../../../../data/remote/vehicle_service.dart';

/* ---------- Constantes visuales ---------- */
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
  /* ───────────────── Controllers & State ───────────────── */
  late final _plateC    = TextEditingController(text: v.licensePlate);
  late final _brandC    = TextEditingController(text: v.brand);
  late final _modelC    = TextEditingController(text: v.model);
  late final _yearC     = TextEditingController(text: v.year.toString());
  late final _colorC    = TextEditingController(text: v.color);
  late final _seatC     = TextEditingController(text: v.seatingCapacity.toString());
  late       String     _status   = v.status;
  late final _driverC   = TextEditingController(text: v.driverName);
  late final _inspC     = TextEditingController(text: _fmt.format(v.lastTechnicalInspectionDate!));
  late final _workshopC = TextEditingController(
    text: v.dateToGoTheWorkshop != null ? _fmt.format(v.dateToGoTheWorkshop!) : '',
  );

  final _formKey = GlobalKey<FormState>();
  final _fmt     = DateFormat('yyyy-MM-dd');
  final _picker  = ImagePicker();
  final _svc     = VehicleService();
  final _profileSvc = ProfileService();

  File? _pickedImg, _pickedSoat, _pickedCard;
  bool _editMode = false;
  final _shot = ScreenshotController();

  // Lista de conductores filtrada
  List<Map<String, dynamic>> _drivers = [];

  VehicleModel get v => widget.vehicle;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      final prof = await _profileSvc.getProfileByNameAndLastName(widget.name, widget.lastName);
      final all = await _profileSvc.getAllCarriers();
      final filtered = all.where((c) =>
      c.companyName == prof?.companyName &&
          c.companyRuc  == prof?.companyRuc
      ).toList();
      if (!mounted) return;
      setState(() {
        _drivers = filtered.map((c) => {
          'id': c.id,
          'name': '${c.name} ${c.lastName}',
        }).toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final ctl in [_plateC,_brandC,_modelC,_yearC,_colorC,_seatC,_driverC,_inspC,_workshopC]) {
      ctl.dispose();
    }
    super.dispose();
  }

  /* ───────────────── Helpers UI/Files ───────────────── */
  ImageProvider? _thumbnail(String raw) {
    if (raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return NetworkImage(raw);
    try { return MemoryImage(base64Decode(base64.normalize(raw))); }
    catch (_) { return null; }
  }

  Future<void> _pickDate(TextEditingController c) async {
    if (!_editMode) return;
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(c.text) ?? DateTime.now(),
      firstDate : DateTime(2000), lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
                primary: _kAction, surface: _kCard,
                onSurface: _kTextMain, onPrimary: Colors.black
            ),
          ), child: child!),
    );
    if (d != null) c.text = _fmt.format(d);
  }

  Future<File?> _pickImageFile() async {
    if (!_editMode) return null;
    final x = await _picker.pickImage(source: ImageSource.gallery);
    return x != null ? File(x.path) : null;
  }

  Future<File?> _pickDocumentFile() async {
    if (!_editMode) return null;
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf','doc','docx','png','jpg','jpeg']);
    if (res != null && res.files.single.path != null) {
      return File(res.files.single.path!);
    }
    return null;
  }

  Future<void> _viewFile(dynamic data, String name) async {
    try {
      final dir = await getTemporaryDirectory();
      final tmp = File('${dir.path}/$name');
      if      (data is File)   await tmp.writeAsBytes(await data.readAsBytes());
      else if (data is String) await tmp.writeAsBytes(base64Decode(base64.normalize(data)));
      await OpenFilex.open(tmp.path);
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir archivo: \$e'), backgroundColor: Colors.red),
      );
    }
  }

  /* ───────────────── Guardar ───────────────── */
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _kAction)),
    );

    final updated = v.copyWith(
      licensePlate: _plateC.text.trim(), brand: _brandC.text.trim(), model: _modelC.text.trim(),
      year: int.tryParse(_yearC.text.trim()) ?? v.year, color: _colorC.text.trim(),
      seatingCapacity: int.tryParse(_seatC.text.trim()) ?? v.seatingCapacity,
      status: _status,
      driverName: _driverC.text.trim(),
      lastTechnicalInspectionDate: _fmt.parse(_inspC.text),
      dateToGoTheWorkshop: _workshopC.text.isNotEmpty ? _fmt.parse(_workshopC.text) : null,
      vehicleImage: _pickedImg!=null ? base64Encode(_pickedImg!.readAsBytesSync()) : v.vehicleImage,
      documentSoat: _pickedSoat!=null ? base64Encode(_pickedSoat!.readAsBytesSync()) : v.documentSoat,
      documentVehicleOwnershipCard: _pickedCard!=null ? base64Encode(_pickedCard!.readAsBytesSync()) : v.documentVehicleOwnershipCard,
    );

    final ok = await _svc.updateVehicle(v.id!, updated);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: ok?Colors.green:Colors.redAccent, content: Text(ok?'Vehículo actualizado con éxito':'Error al guardar los cambios'))
    );
    if (ok) setState(() => _editMode = false);
  }

  /* ───────────────── Compartir (PNG + QR) ───────────────── */
  Future<void> _share() async {
    try {
      final bytes = await _shot.capture(pixelRatio:2.5);
      if (bytes == null) return;
      final qrPainter = QrPainter(data: base64Encode(bytes), version: QrVersions.auto, color: _kBg, emptyColor: Colors.white);
      final ui.Image qrImg = await qrPainter.toImage(600);
      final byteData = await qrImg.toByteData(format: ui.ImageByteFormat.png);
      final qrBytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final imgPath = '\${dir.path}/veh_\${v.id}.png';
      final qrPath  = '\${dir.path}/veh_\${v.id}_qr.png';
      await File(imgPath).writeAsBytes(bytes);
      await File(qrPath).writeAsBytes(qrBytes);
      await Share.shareXFiles([XFile(imgPath), XFile(qrPath)], text:'Información del vehículo \${v.licensePlate}');
    } catch(e){ if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir: \$e'), backgroundColor: Colors.redAccent)
    );}
  }

  /* ───────────────── Eliminar ───────────────── */
/* ─────────────────────── Eliminar ─────────────────────── */
  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        title  : const Text('Confirmar', style: TextStyle(color: _kTextMain)),
        content: const Text('¿Está seguro que quiere eliminar el vehículo de su flota de transporte?',
            style: TextStyle(color: _kTextSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: _kTextSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Confirmar'),
            onPressed: () => Navigator.pop(context, true),
          )
        ],
      ),
    );
    if (ok != true) return;

    final deleted = await _svc.deleteVehicle(v.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: deleted ? Colors.green : Colors.redAccent,
        content: Text(deleted ? 'Vehículo eliminado' : 'No se pudo eliminar'),
      ),
    );
    if (deleted) Navigator.pop(context, true);
  }

  /* ───────────────── BUILD ───────────────── */
  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller:_shot,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(backgroundColor:_kBar,title: const Text('Detalle del Vehículo',style:TextStyle(color:_kTextMain)),iconTheme:const IconThemeData(color:_kTextMain),actions:[
          PopupMenuButton<String>(icon:const Icon(Icons.more_vert,color:_kTextMain),onSelected:(v){
            switch(v){case'edit':setState(()=>_editMode=!_editMode);break;case'share':_share();break;case'delete':_confirmDelete();break;}
          },itemBuilder:(_)=>[
            PopupMenuItem(value:'edit',child:Text(_editMode?'Cancelar edición':'Editar')),
            const PopupMenuItem(value:'share',child:Text('Compartir')),
            const PopupMenuDivider(),
            const PopupMenuItem(value:'delete',textStyle:TextStyle(color:Colors.redAccent),child:Text('Eliminar'))
          ])
        ]),
        drawer: AppDrawer(
          name: widget.name,
          lastName: widget.lastName,
          companyName: v.companyName, // Usamos la propiedad 'v' que es un alias de widget.vehicle
          companyRuc: v.companyRuc,     // Usamos la propiedad 'v'
        ),
        body:SafeArea(child:Form(key:_formKey,child:ListView(padding:const EdgeInsets.all(16),children:[
          _buildVehicleImage(),
          const SizedBox(height:24),
          _buildSectionLabel('Datos generales'),
          _field('Placa',_plateC,validator:_required),
          const SizedBox(height:12),
          Wrap(spacing:12,runSpacing:12,children:[
            _buildHalfWidthField(_field('Marca',_brandC,validator:_required)),
            _buildHalfWidthField(_field('Modelo',_modelC,validator:_required)),
            _buildHalfWidthField(_field('Año',_yearC,kb:TextInputType.number)),
            _buildHalfWidthField(_field('Color',_colorC)),
            _buildHalfWidthField(_field('Capacidad (pax)',_seatC,kb:TextInputType.number)),
            SizedBox(width:(MediaQuery.of(context).size.width/2)-1,child:_buildStatusDropdown()),
          ]),
          _buildSectionLabel('Mantenimiento'),
          Wrap(spacing:12,runSpacing:12,children:[
            _buildHalfWidthField(_field('Última inspección',_inspC,isDate:true)),
            _buildHalfWidthField(_field('Próxima visita taller',_workshopC,isDate:true)),
          ]),
          _buildSectionLabel('Asignación'),
          // Dropdown de conductores
          Padding(
            padding: const EdgeInsets.symmetric(vertical:8.0),
            child: DropdownButtonFormField<String>(
              value: _driverC.text.isEmpty? null : _driverC.text,
              decoration: _dec('Conductor'),

              items: _drivers.map((d) => DropdownMenuItem<String>(value:d['name'] as String,child:Text(d['name'] as String, style: const TextStyle(color: _kTextMain)))).toList(),
              onChanged: _editMode? (name) => setState(()=> _driverC.text = name ?? '') : null,
              validator: _editMode? (v) => v == null || v.isEmpty? 'Seleccione conductor': null : null,
              dropdownColor: _kCard,
              style: const TextStyle(color: _kTextMain),
            ),
          ),
          _buildSectionLabel('Info de seguimiento'),
          _buildTelemetryInfo(),
          _buildSectionLabel('Documentos'),
          _buildDocumentTile(label:'SOAT',existingData:v.documentSoat,pickedFile:_pickedSoat,onFilePicked:(f)=>setState(()=>_pickedSoat=f)),
          _buildDocumentTile(label:'Tarjeta de Propiedad',existingData:v.documentVehicleOwnershipCard,pickedFile:_pickedCard,onFilePicked:(f)=>setState(()=>_pickedCard=f)),
          const SizedBox(height:32),
          _editMode? _buildSaveCancel() : _buildClose(),
          const SizedBox(height:16),
        ]))),
      ),
    );
  }


/* ─────────────────────── Widgets auxiliares ─────────────────────── */
  Widget _buildHalfWidthField(Widget child) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width / 2) - 16 - 6,
      child: child,
    );
  }

  Widget _field(String lbl, TextEditingController c, {TextInputType kb = TextInputType.text, bool isDate = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      readOnly: !_editMode || isDate,
      keyboardType: kb,
      validator: _editMode ? validator : null,
      style: const TextStyle(color: _kTextMain),
      decoration: _dec(lbl).copyWith(
        suffixIcon: isDate
            ? IconButton(icon: const Icon(Icons.calendar_today, color: _kAction), onPressed: () => _pickDate(c))
            : (_editMode ? const Icon(Icons.edit, color: _kTextSub, size: 20) : null),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: _dec('Estado'),
      items: const ['Activo','En mantenimiento','Inactivo']
          .map((e)=> DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: _kTextMain)),)).toList(),
      onChanged: _editMode ? (v)=> setState(()=> _status = v ?? _status) : null,
      validator: _editMode ? (v)=> v==null||v.isEmpty? 'Seleccione estado':null : null,
      dropdownColor: _kCard,
      style: const TextStyle(color: _kTextMain),

    );
  }

  Widget _buildVehicleImage() {
    return GestureDetector(
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
    );
  }

  Widget _buildTelemetryInfo() {
    return Card(
      color: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (v.lastLatitude != null && v.lastLongitude != null)
              _MiniMap(lat: v.lastLatitude!, lon: v.lastLongitude!)
            else
              Container(
                height: 150,
                alignment: Alignment.center,
                child: const Text('No hay datos de ubicación disponibles.', style: TextStyle(color: _kTextSub)),
              ),
            const Divider(height: 24, color: _kBg),
            _readonlyInfo('Altitud', v.lastAltitudeMeters != null ? '${v.lastAltitudeMeters!.toStringAsFixed(1)} m' : '--'),
            _readonlyInfo('Velocidad', v.lastKmh != null ? '${v.lastKmh!.toStringAsFixed(1)} km/h' : '--'),
            _readonlyInfo('Última actualización', v.lastTelemetryTimestamp != null ? DateFormat('yyyy-MM-dd HH:mm').format(v.lastTelemetryTimestamp!) : '--'),
          ],
        ),
      ),
    );
  }

  Widget _readonlyInfo(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _kTextSub)),
        Text(value, style: const TextStyle(color: _kTextMain, fontWeight: FontWeight.w500)),
      ],
    ),
  );

  InputDecoration _dec(String lbl) => InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(color: _kTextSub),
    filled: true,
    fillColor: _kBg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(_kRadius), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_kRadius), borderSide: const BorderSide(color: _kAction)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _buildSectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 20),
    child: Text(t, style: const TextStyle(color: _kAction, fontSize: 16, fontWeight: FontWeight.bold)),
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
            if (_editMode)
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

  Widget _buildSaveCancel() => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () => setState(() { _editMode = false; }),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _kTextSub),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          child: const Text('Cancelar', style: TextStyle(color: _kTextSub)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save, color: Colors.black),
          label: const Text('Guardar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kAction,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
        ),
      ),
    ],
  );

  Widget _buildClose() => Center(
    child: OutlinedButton(
      onPressed: () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _kTextSub),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: const Text('Cerrar', style: TextStyle(color: _kTextSub)),
    ),
  );

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Este campo es requerido' : null;
}

class _MiniMap extends StatelessWidget {
  final double lat, lon;
  const _MiniMap({required this.lat, required this.lon});

  @override
  Widget build(BuildContext context) {
    final camera = CameraPosition(target: LatLng(lat, lon), zoom: 15);
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kRadius),
      child: SizedBox(
        height: 200,
        child: GoogleMap(
          initialCameraPosition: camera,
          liteModeEnabled: true,
          compassEnabled: false,
          zoomControlsEnabled: false,
          markers: { Marker(markerId: const MarkerId('veh'), position: LatLng(lat, lon)) },
        ),
      ),
    );
  }
}