// lib/features/route_management/presentation/pages/businessman/route/route_detail_screen.dart
/* -------------------------------------------------------------- */
/*               DETALLE / EDICIÓN DE UNA RUTA EXISTENTE          */
/* -------------------------------------------------------------- */
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../../core/widgets/app_drawer.dart';
import '../../../../data/remote/route_model.dart';
import '../../../../data/remote/route_service.dart';

/* --- colores --- */
const _kBg = Color(0xFF1E1F24);
const _kCard = Color(0xFF2F353F);
const _kBar = Color(0xFF2C2F38);
const _kAction = Color(0xFFEA8E00);
const _kTextMain = Colors.white;
const _kTextSub = Colors.white70;
const _kRadius = 12.0;

class RouteDetailScreen extends StatefulWidget {
  final RouteModel route;
  final String name, lastName;
  const RouteDetailScreen({
    super.key,
    required this.route,
    required this.name,
    required this.lastName,
  });

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  final _svc = RouteService();
  final _fmtTime = DateFormat('HH:mm');
  final _formKey = GlobalKey<FormState>();

  late String _type;
  late TextEditingController _customerC, _shiftC, _departureC, _arrivalC;
  late List<Waypoint> _waypoints;

  GoogleMapController? _mapCtrl;

  @override
  void initState() {
    super.initState();
    final r = widget.route;
    _type = r.type;
    _customerC = TextEditingController(text: r.customer);
    _shiftC    = TextEditingController(text: r.shift);
    _departureC= TextEditingController(text: _fmtTime.format(r.departureTime!));
    _arrivalC  = TextEditingController(text: _fmtTime.format(r.arrivalTime!));
    _waypoints = List.of(r.waypoints);
  }

  /* ================= helpers ================= */
  Future<void> _pickTime(TextEditingController ctl) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      final dt = DateTime(2000, 1, 1, picked.hour, picked.minute);
      ctl.text = _fmtTime.format(dt);
    }
  }

  void _onMapTap(LatLng pos) async {
    final name = await _askForText('Nombre del punto');
    if (name == null) return;
    setState(() {
      _waypoints.add(Waypoint(
        order: _waypoints.length + 1,
        name: name,
        latitude: pos.latitude,
        longitude: pos.longitude,
      ));
    });
  }

  Future<String?> _askForText(String title) async {
    final ctl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        title: Text(title, style: const TextStyle(color: _kTextMain)),
        content: TextField(
          controller: ctl,
          style: const TextStyle(color: _kTextMain),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kAction),
            child: const Text('Aceptar', style: TextStyle(color: Colors.black)),
            onPressed: () => Navigator.pop(context, ctl.text),
          ),
        ],
      ),
    );
  }

  /* ================= submit ================= */
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.route.copyWith(
      type        : _type,
      customer    : _customerC.text.trim(),
      shift       : _shiftC.text.trim(),
      departureTime: _fmtTime.parse(_departureC.text),
      arrivalTime  : _fmtTime.parse(_arrivalC.text),
      waypoints   : _waypoints,
      lastLatitude: _waypoints.first.latitude,
      lastLongitude: _waypoints.first.longitude,
      nameRoute   : '${_waypoints.first.name} – ${_waypoints.last.name}',
      updatedAt   : DateTime.now(),
    );

    final ok = await _svc.updateRoute(updated.id!, updated);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta actualizada'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar'), backgroundColor: Colors.redAccent),
      );
    }
  }

  /* ================= build ================= */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBar,
        title: const Text('Detalle de Ruta', style: TextStyle(color: _kTextMain)),
        iconTheme: const IconThemeData(color: _kTextMain),
      ),
      drawer: AppDrawer(name: widget.name, lastName: widget.lastName),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                'regular','reten','express','evento','mantenimiento'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              decoration: _dec('Tipo'),
              onChanged: (v) => setState(() => _type = v!),
            ),
            _txt('Cliente', _customerC),
            _txt('Shift', _shiftC, kb: TextInputType.number),
            _txt('Salida', _departureC, readOnly: true, icon: Icons.schedule, onTap: () => _pickTime(_departureC)),
            _txt('Llegada', _arrivalC,  readOnly: true, icon: Icons.schedule, onTap: () => _pickTime(_arrivalC)),

            const SizedBox(height: 16),
            const Text('Waypoints (tap para añadir)', style: TextStyle(color: _kAction, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_kRadius),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_waypoints.first.latitude, _waypoints.first.longitude),
                    zoom: 12,
                  ),
                  markers: {
                    for (final w in _waypoints)
                      Marker(markerId: MarkerId('${w.order}'),
                          position: LatLng(w.latitude, w.longitude),
                          infoWindow: InfoWindow(title: w.name))
                  },
                  onTap: _onMapTap,
                  onMapCreated: (c) => _mapCtrl = c,
                ),
              ),
            ),
            ..._waypoints
                .map((w) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _kAction,
                child: Text('${w.order}', style: const TextStyle(color: Colors.black)),
              ),
              title: Text(w.name, style: const TextStyle(color: _kTextMain)),
              subtitle: Text('${w.latitude.toStringAsFixed(5)}, ${w.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(color: _kTextSub)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => setState(() => _waypoints.remove(w)),
              ),
            ))
                .toList(),

            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kTextSub,
                    side: const BorderSide(color: _kTextSub),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save, color: Colors.black),
                  label: const Text('Guardar', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: _kAction),
                  onPressed: _save,
                ),
              )
            ]),
          ],
        ),
      ),
    );
  }

  /* ---------- helpers UI ---------- */
  Widget _txt(String lbl, TextEditingController c,
      {TextInputType kb = TextInputType.text,
        bool readOnly = false,
        IconData? icon,
        VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: c,
        readOnly: readOnly,
        keyboardType: kb,
        style: const TextStyle(color: _kTextMain),
        decoration: _dec(lbl).copyWith(
          suffixIcon: icon != null ? Icon(icon, color: _kAction) : null,
        ),
        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
        onTap: onTap,
      ),
    );
  }

  InputDecoration _dec(String lbl) => InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(color: _kTextSub),
    filled: true,
    fillColor: _kCard,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(_kRadius), borderSide: BorderSide.none),
    focusedBorder:
    OutlineInputBorder(borderRadius: BorderRadius.circular(_kRadius), borderSide: const BorderSide(color: _kAction)),
  );
}
