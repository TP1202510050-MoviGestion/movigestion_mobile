// lib/features/route_management/presentation/pages/businessman/route/assign_route_screen.dart
/* -------------------------------------------------------------- */
/*                     PANTALLA: ALTA DE RUTA                     */
/* -------------------------------------------------------------- */
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/widgets/app_drawer.dart';
// 🔑 6 niveles arriba hasta lib/, luego core/
import '../../../../../../../../core/google_maps_config.dart';


import '../../../../data/remote/profile_service.dart';
import '../../../../data/remote/route_model.dart';
import '../../../../data/remote/route_service.dart';
import '../../../../data/remote/vehicle_model.dart';
import '../../../../data/remote/vehicle_service.dart';

/* ---------- Constantes visuales ---------- */
const _kBg       = Color(0xFF1E1F24);
const _kCard     = Color(0xFF2F353F);
const _kBar      = Color(0xFF2C2F38);
const _kAction   = Color(0xFFEA8E00);
const _kTextMain = Colors.white;
const _kTextSub  = Colors.white70;
const _kRadius   = 12.0;

class AssignRouteScreen extends StatefulWidget {
  final String name;
  final String lastName;
  const AssignRouteScreen({super.key, required this.name, required this.lastName});

  @override
  State<AssignRouteScreen> createState() => _AssignRouteScreenState();
}

class _AssignRouteScreenState extends State<AssignRouteScreen> {
  /* -------- servicios -------- */
  final _routeSvc   = RouteService();
  final _profileSvc = ProfileService();
  final _vehicleSvc = VehicleService();

  /* -------- form & utils -------- */
  final _formKey = GlobalKey<FormState>();
  final _fmtTime = DateFormat('HH:mm');

  /* -------- controllers -------- */
  final _customerC   = TextEditingController();
  final _shiftC      = TextEditingController();
  final _departureC  = TextEditingController();   // hora salida
  final _arrivalC    = TextEditingController();   // hora llegada

  // Dirección inicio / destino
  final _startC      = TextEditingController();
  final _endC        = TextEditingController();
  // Paradas dinámicas
  final List<TextEditingController> _stopCs = [];

  /* -------- selección & estado -------- */
  String? _type;           // regular, reten, express, evento, mantenimiento
  String? _driverName;
  int?    _driverId;
  int?    _vehicleId;
  String? _vehiclePlate;

  /* -------- empresa del creador -------- */
  String _companyName = '';
  String _companyRuc  = '';

  /* -------- transportistas dropdown -------- */
  List<Map<String, dynamic>> _transportistas = []; // {id, fullName}

  /* -------- coordenadas elegidas -------- */
  final Map<TextEditingController, LatLng> _coords = {}; // controller → LatLng

  /* -------- mapa -------- */
  GoogleMapController? _mapCtrl;
  final List<LatLng> _polylinePoints = [];

  /* ============================ INIT ============================ */
  @override
  void initState() {
    super.initState();
    _loadProfileAndDrivers();
  }

  Future<void> _loadProfileAndDrivers() async {
    /* creador */
    final creator =
    await _profileSvc.getProfileByNameAndLastName(widget.name, widget.lastName);
    _companyName = creator?.companyName ?? '';
    _companyRuc  = creator?.companyRuc  ?? '';

    /* transportistas */
    final carriers = await _profileSvc.getAllCarriers();
    setState(() {
      _transportistas = carriers
          .map((p) => {'id': p.id, 'fullName': '${p.name} ${p.lastName}'})
          .toList();
    });
  }

  /* ============================ TIME PICKER ============================ */
  Future<void> _pickTime(TextEditingController ctl) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      final dt = DateTime(2000, 1, 1, picked.hour, picked.minute);
      ctl.text = _fmtTime.format(dt);
    }
  }

  /* ============================ DRIVER SELECTION ============================ */
  Future<void> _onDriverSelected(String? fullName) async {
    if (fullName == null) return;
    setState(() => _driverName = fullName);

    final prof = _transportistas.firstWhere((e) => e['fullName'] == fullName);
    _driverId = prof['id'] as int;

    final vehicles = await _vehicleSvc.getAllVehicles();
    final VehicleModel? veh = vehicles.firstWhereOrNull(
          (v) => v.driverName.toLowerCase().trim() == fullName.toLowerCase().trim(),
    );

    setState(() {
      _vehicleId    = veh?.id;
      _vehiclePlate = veh?.licensePlate;
    });
  }

  /* ============================ AUTOCOMPLETE ============================ */
  Future<void> _showAddressAutocomplete(TextEditingController ctl) async {
    final predictions = await googlePlace.autocomplete.get(
      ctl.text,
      components: [Component('country', 'pe')],
      language: 'es',
      types: 'geocode',
    );

    if (predictions == null || predictions.predictions == null) return;
    final list = predictions.predictions!;

    final String? chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _kCard,
      isScrollControlled: true,
      builder: (_) => ListView(
        padding: const EdgeInsets.only(top: 16),
        children: list
            .map(
              (p) => ListTile(
            title: Text(p.description ?? '',
                style: const TextStyle(color: _kTextMain)),
            onTap: () => Navigator.pop(context, p.placeId),
          ),
        )
            .toList(),
      ),
    );

    if (chosen == null) return;

    final details = await googlePlace.details.get(chosen);
    final loc = details?.result?.geometry?.location;
    if (loc == null) return;

    setState(() {
      ctl.text = details?.result?.formattedAddress ?? ctl.text;
      _coords[ctl] = LatLng(loc.lat ?? 0, loc.lng ?? 0);

      _rebuildPolyline();
    });
  }

  void _rebuildPolyline() {
    _polylinePoints
      ..clear()
      ..addAll(_orderedCoords());
  }

  List<LatLng> _orderedCoords() {
    final list = <LatLng>[];
    if (_coords.containsKey(_startC)) list.add(_coords[_startC]!);
    for (final c in _stopCs) {
      if (_coords.containsKey(c)) list.add(_coords[c]!);
    }
    if (_coords.containsKey(_endC)) list.add(_coords[_endC]!);
    return list;
  }

  /* ============================ SUBMIT ============================ */
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _msg('Complete todos los campos obligatorios');
      return;
    }
    if (!_coords.containsKey(_startC) || !_coords.containsKey(_endC)) {
      _msg('Seleccione un punto de partida y de llegada válidos');
      return;
    }

    // construir waypoints
    final List<Waypoint> wps = [];
    int order = 1;
    void addW(String name, LatLng pos) {
      wps.add(Waypoint(
        order    : order++,
        name     : name,
        latitude : pos.latitude,
        longitude: pos.longitude,
      ));
    }

    addW('Inicio', _coords[_startC]!);
    for (final c in _stopCs) {
      if (_coords.containsKey(c)) addW('Parada', _coords[c]!);
    }
    addW('Destino', _coords[_endC]!);

    final nameRoute = '${_startC.text} – ${_endC.text}';
    final now       = DateTime.now();

    final route = RouteModel(
      type         : _type!,
      customer     : _customerC.text.trim(),
      nameRoute    : nameRoute,
      status       : 'asignado',
      shift        : _shiftC.text.trim(),
      driverId     : _driverId,
      driverName   : _driverName,
      vehicleId    : _vehicleId,
      vehiclePlate : _vehiclePlate,
      departureTime: _fmtTime.parse(_departureC.text),
      arrivalTime  : _fmtTime.parse(_arrivalC.text),
      waypoints    : wps,
      lastLatitude : wps.first.latitude,
      lastLongitude: wps.first.longitude,
      createdAt    : now,
      updatedAt    : null,
      companyName  : _companyName,
      companyRuc   : _companyRuc,
    );

    final ok = await _routeSvc.createRoute(route);
    if (!mounted) return;
    Navigator.pop(context, ok);
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  /* ============================ BUILD ============================ */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Crear Ruta', style: TextStyle(color: _kTextMain)),
        backgroundColor: _kBar,
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
              decoration: _dec('Tipo'),
              items: const [
                'regular','reten','express','evento','mantenimiento'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _type = v),
              validator: (v) => v == null ? 'Seleccione tipo' : null,
            ),
            _txt('Cliente (empresa)', _customerC),
            _txt('Personal recogido (Shift)', _shiftC, kb: TextInputType.number),

            DropdownButtonFormField<String>(
              value: _driverName,
              decoration: _dec('Conductor'),
              items: _transportistas
                  .map((p) => DropdownMenuItem(
                  value: p['fullName'] as String,
                  child: Text(p['fullName'] as String)))
                  .toList(),
              onChanged: _onDriverSelected,
              validator: (v) => v == null ? 'Seleccione conductor' : null,
            ),

            const SizedBox(height: 12),
            _txt('Hora de salida',  _departureC,
                readOnly: true, icon: Icons.schedule,
                onTap: () => _pickTime(_departureC)),
            _txt('Hora de llegada', _arrivalC,
                readOnly: true, icon: Icons.schedule,
                onTap: () => _pickTime(_arrivalC)),

            const SizedBox(height: 18),
            const Text('Direcciones',
                style: TextStyle(color: _kAction, fontWeight: FontWeight.bold)),

            _addressField('Punto de partida', _startC),
            ..._stopCs
                .mapIndexed((i,c)=> Row(
                children:[
                  Expanded(child: _addressField('Parada ${i+1}', c)),
                  const SizedBox(width:8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        _stopCs.remove(c);   // 1) quitamos el controlador del array de paradas
                        _coords.remove(c);   // 2) quitamos también sus coordenadas asociadas
                        _rebuildPolyline();  // 3) actualizamos la línea del mapa
                      });
                    },
                  ),
                ])),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: (){
                  setState(()=> _stopCs.add(TextEditingController()));
                },
                icon: const Icon(Icons.add,color:_kAction),
                label: const Text('Agregar parada',
                    style: TextStyle(color:_kAction)),
              ),
            ),
            _addressField('Punto de llegada', _endC),

            const SizedBox(height: 18),
            SizedBox(
              height: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_kRadius),
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                      target: LatLng(-12.06,-77.04), zoom: 11),
                  markers: {
                    for (final entry in _coords.entries)
                      Marker(
                        markerId: MarkerId(entry.key.hashCode.toString()),
                        position: entry.value,
                        infoWindow: InfoWindow(
                            title: entry.key == _startC
                                ? 'Inicio'
                                : entry.key == _endC
                                ? 'Destino'
                                : 'Parada'),
                      )
                  },
                  polylines: _polylinePoints.length<2 ? {} : {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      color: Colors.amber,
                      width: 4,
                      points: _polylinePoints,
                    )
                  },
                  onMapCreated: (c)=> _mapCtrl=c,
                  myLocationEnabled: true,
                ),
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save, color: Colors.black),
              label: const Text('Guardar Ruta',
                  style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAction,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ============================ HELPERS ============================ */
  Widget _txt(
      String lbl,
      TextEditingController c, {
        TextInputType kb = TextInputType.text,
        bool readOnly = false,
        IconData? icon,
        VoidCallback? onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller : c,
        readOnly   : readOnly,
        keyboardType: kb,
        style      : const TextStyle(color: _kTextMain),
        decoration : _dec(lbl).copyWith(
          suffixIcon: icon != null ? Icon(icon, color: _kAction) : null,
        ),
        validator  : (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
        onTap      : onTap,
      ),
    );
  }

  Widget _addressField(String lbl, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: c,
        style: const TextStyle(color: _kTextMain),
        decoration: _dec(lbl).copyWith(
            suffixIcon: const Icon(Icons.place_outlined, color: _kAction)),
        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
        onChanged: (_) {
          if (c.text.isEmpty) _coords.remove(c);
        },
        onTap: () async {
          await Future.delayed(const Duration(milliseconds: 100));
          _showAddressAutocomplete(c);
        },
        onFieldSubmitted: (_) => _showAddressAutocomplete(c),
      ),
    );
  }

  InputDecoration _dec(String lbl) => InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(color: _kTextSub),
    filled: true,
    fillColor: _kCard,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: _kAction)),
  );
}
