// lib/features/route_management/presentation/pages/businessman/route/assign_route_screen.dart
// -----------------------------------------------------------------------------
//            PANTALLA  ▸  CREAR / ASIGNAR RUTA
// -----------------------------------------------------------------------------

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../../../../../../../../core/widgets/app_drawer.dart';
import '../../../../../../../../core/google_maps_config.dart'
    show kMapsApiKey, googlePlace;

import '../../../../data/remote/profile_service.dart';
import '../../../../data/remote/route_model.dart';
import '../../../../data/remote/route_service.dart';
import '../../../../data/remote/vehicle_model.dart';
import '../../../../data/remote/vehicle_service.dart';

/* -------------------  Estilos  ------------------- */
const _kBg = Color(0xFF1E1F24);
const _kCard = Color(0xFF2F353F);
const _kBar = Color(0xFF2C2F38);
const _kAction = Color(0xFFEA8E00);
const _kTextMain = Colors.white;
const _kTextSub = Colors.white70;
const _kRadius = 12.0;

/* =========================================================================== */
/*                              VIEW-MODEL LIGERO                              */
/* =========================================================================== */
class _RouteVM with ChangeNotifier {
  _RouteVM(this.profileSvc, this.vehicleSvc);

  final ProfileService profileSvc;
  final VehicleService vehicleSvc;
  final DateFormat fmtTime = DateFormat('HH:mm');

  bool loading = true;
  String? error;

  String companyName = '';
  String companyRuc = '';

  final List<Map<String, dynamic>> carriers = [];
  final Map<int, VehicleModel> _vehicleByDriver = {};

  Future<void> bootstrap(String n, String l) async {
    try {
      loading = true;
      notifyListeners();

      final results = await Future.wait([
        profileSvc.getProfileByNameAndLastName(n, l),
        profileSvc.getAllCarriers(),
        vehicleSvc.getAllVehicles(),
      ]);

      final prof = results[0] as dynamic;      // o ProfileModel? si prefieres tipar

      companyName = prof?.companyName ?? '';
      companyRuc  = prof?.companyRuc  ?? '';

      final cList = results[1] as List<dynamic>;
      carriers
        ..clear()
        ..addAll(cList.map((p) => {
          'id': p.id,
          'name': '${p.name} ${p.lastName}',
        }));

      for (final v in (results[2] as List<VehicleModel>)) {
        if (v.assignedDriverId != null) {
          _vehicleByDriver[v.assignedDriverId!] = v;
        }
      }
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  VehicleModel? vehicleForDriver(int id) => _vehicleByDriver[id];
}

/* =========================================================================== */
/*                     MODELO PARA CADA PUNTO / PARADA                         */
/* =========================================================================== */
class StopPoint {
  StopPoint(this.label) {
    controller = TextEditingController();
  }
  final String label;
  late final TextEditingController controller;
  LatLng? latLng;
  void dispose() => controller.dispose();
}

/* =========================================================================== */
/*                              WIDGET PRINCIPAL                               */
/* =========================================================================== */
class AssignRouteScreen extends StatelessWidget {
  final String name;
  final String lastName;
  const AssignRouteScreen(
      {super.key, required this.name, required this.lastName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      _RouteVM(ProfileService(), VehicleService())..bootstrap(name, lastName),
      child: _AssignRouteBody(userName: name, userLastName: lastName),
    );
  }
}

class _AssignRouteBody extends StatefulWidget {
  final String userName, userLastName;
  const _AssignRouteBody(
      {required this.userName, required this.userLastName});

  @override
  State<_AssignRouteBody> createState() => _AssignRouteBodyState();
}

class _AssignRouteBodyState extends State<_AssignRouteBody> {
/* ──────────────────────── Controllers ──────────────────────── */
  final _formKey = GlobalKey<FormState>();
  final _customerC = TextEditingController();
  final _shiftC = TextEditingController();
  final _depC = TextEditingController();
  final _arrC = TextEditingController();

  final _start = StopPoint('Inicio');
  final _end = StopPoint('Destino');
  final List<StopPoint> _stops = [];

  String? _routeType;
  int? _driverId;
  String? _driverName;
  VehicleModel? _vehicle;

/* ──────────────────────── Mapa ──────────────────────── */
  GoogleMapController? _mapCtrl;
  final Set<Marker> _markers = {};
  final List<LatLng> _polyline = [];

/* ──────────────────────── Debounce helpers ──────────────────────── */
  Timer? _debouncer;
  void _debounce(VoidCallback cb, [int ms = 350]) {
    _debouncer?.cancel();
    _debouncer = Timer(Duration(milliseconds: ms), cb);
  }

/* ──────────────────────── UI utils ──────────────────────── */
  InputDecoration _dec(String l, [IconData? ic]) => InputDecoration(
    labelText: l,
    labelStyle: const TextStyle(color: _kTextSub),
    filled: true,
    fillColor: _kCard,
    suffixIcon: ic == null ? null : Icon(ic, color: _kAction),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kRadius),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kRadius),
      borderSide: const BorderSide(color: _kAction),
    ),
  );

  Future<void> _pickTime(TextEditingController c) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      final vm = context.read<_RouteVM>();
      c.text = vm.fmtTime
          .format(DateTime(2000, 1, 1, picked.hour, picked.minute));
    }
  }

/* ────────────────────────  AUTOCOMPLETE  ──────────────────────── */

// quitamos genérico para evitar error del compilador
  final _acKey = GlobalKey();
  /// Debouncer que **devuelve** el `Future<Iterable<>>` exigido
  Completer<Iterable<AutocompletePrediction>>? _searchCompleter;
  Timer? _searchTimer;
  Future<List<AutocompletePrediction>> _searchPlaces(String q) async {
    if (q.trim().isEmpty) return [];       //  <-- añade esta línea
    final res = await googlePlace.autocomplete.get(
      q,
      components: [Component('country', 'pe')],
      language: 'es',
      types: 'geocode',
    );
    return res?.predictions ?? [];
  }

  Future<void> _selectPrediction(
      StopPoint p, AutocompletePrediction choice) async {
    final det = await googlePlace.details.get(choice.placeId!);
    final loc = det?.result?.geometry?.location;
    if (loc == null) return;
    setState(() {
      p.controller.text =
          det?.result?.formattedAddress ?? choice.description ?? '';
      p.latLng = LatLng(loc.lat!, loc.lng!);
      _refreshRoute();
    });
  }

/* ────────────────────────  Paradas  ──────────────────────── */
  void _addStop() => setState(
          () => _stops.add(StopPoint('Parada ${_stops.length + 1}')));

  void _removeStop(StopPoint p) {
    setState(() {
      p.dispose();
      _stops.remove(p);
      _refreshRoute();
    });
  }

/* ────────────────────────  Mapa  ──────────────────────── */
  Future<void> _refreshRoute() async {
    _markers.clear();
    _polyline.clear();

    final pts = [
      if (_start.latLng != null) _start.latLng!,
      ..._stops.where((s) => s.latLng != null).map((s) => s.latLng!),
      if (_end.latLng != null) _end.latLng!,
    ];

    for (var i = 0; i < pts.length; i++) {
      _markers.add(Marker(
        markerId: MarkerId('p$i'),
        position: pts[i],
        infoWindow: InfoWindow(
            title: i == 0
                ? 'Inicio'
                : (i == pts.length - 1 ? 'Destino' : 'Parada')),
      ));
    }

    if (pts.length >= 2) {
      final dir = PolylinePoints();
      final res = await dir.getRouteBetweenCoordinates(
        kMapsApiKey,
        PointLatLng(pts.first.latitude, pts.first.longitude),
        PointLatLng(pts.last.latitude, pts.last.longitude),
        travelMode: TravelMode.driving,
        wayPoints: pts
            .sublist(1, pts.length - 1)
            .map((e) => PolylineWayPoint(location: '${e.latitude},${e.longitude}'))
            .toList(),
      );
      if (res.points.isNotEmpty) {
        _polyline.addAll(
            res.points.map((e) => LatLng(e.latitude, e.longitude)));
      } else {
        _polyline.addAll(pts);
      }
      // encuadrar
      final neLat = pts.map((e) => e.latitude).reduce((a, b) => a > b ? a : b);
      final neLng = pts.map((e) => e.longitude).reduce((a, b) => a > b ? a : b);
      final swLat = pts.map((e) => e.latitude).reduce((a, b) => a < b ? a : b);
      final swLng = pts.map((e) => e.longitude).reduce((a, b) => a < b ? a : b);
      await _mapCtrl?.animateCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(
              northeast: LatLng(neLat, neLng),
              southwest: LatLng(swLat, swLng)),
          60));
    }
    setState(() {});
  }

/* ────────────────────────  GUARDAR  ──────────────────────── */
  bool _sending = false;
  Future<void> _save() async {
    final vm = context.read<_RouteVM>();
    if (!_formKey.currentState!.validate()) return;
    if (_start.latLng == null || _end.latLng == null) {
      _msg('Seleccione un punto de partida y destino válidos');
      return;
    }
    if (_driverId == null) {
      _msg('Seleccione conductor');
      return;
    }

    final dep = vm.fmtTime.parse(_depC.text);
    final arr = vm.fmtTime.parse(_arrC.text);
    if (arr.isBefore(dep)) {
      _msg('La hora de llegada debe ser posterior a la de salida');
      return;
    }

    setState(() => _sending = true);

    final List<Waypoint> wps = [];
    int order = 1;
    void add(String n, StopPoint p) {
      if (p.latLng != null) {
        wps.add(Waypoint(
          order: order++,
          name: n,
          latitude: p.latLng!.latitude,
          longitude: p.latLng!.longitude,
        ));
      }
    }

    add('Inicio', _start);
    for (final s in _stops) add('Parada', s);
    add('Destino', _end);

    final route = RouteModel(
      type: _routeType!,
      customer: _customerC.text.trim(),
      nameRoute:
      '${_start.controller.text} – ${_end.controller.text}',
      status: 'asignado',
      shift: _shiftC.text.trim(),
      driverId: _driverId,
      driverName: _driverName,
      vehicleId: _vehicle?.id,
      vehiclePlate: _vehicle?.licensePlate,
      departureTime: dep,
      arrivalTime: arr,
      waypoints: wps,
      lastLatitude: wps.first.latitude,
      lastLongitude: wps.first.longitude,
      createdAt: DateTime.now(),
      updatedAt: null,
      companyName: vm.companyName,
      companyRuc: vm.companyRuc,
    );

    final ok = await RouteService().createRoute(route);
    if (!mounted) return;
    setState(() => _sending = false);
    Navigator.pop(context, ok);
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

/* ────────────────────────  BUILD  ──────────────────────── */
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<_RouteVM>();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBar,
        title: const Text('Crear Ruta', style: TextStyle(color: _kTextMain)),
        iconTheme: const IconThemeData(color: _kTextMain),
      ),
      drawer: AppDrawer(
          name: widget.userName, lastName: widget.userLastName),
      body: vm.loading
          ? const Center(
          child: CircularProgressIndicator(color: _kAction))
          : (vm.error != null
          ? Center(
          child: Text('Error: ${vm.error}',
              style: const TextStyle(color: Colors.red)))
          : _buildForm(vm)),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _sending ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: _kAction,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          icon: _sending
              ? const SizedBox(
              width: 18,
              height: 18,
              child:
              CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Icon(Icons.save, color: Colors.black),
          label: const Text('Guardar Ruta',
              style: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }

/* ----------------------------- FORM UI ---------------------------- */
  Widget _buildForm(_RouteVM vm) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /* INFO GENERAL */
          ExpansionTile(
            initiallyExpanded: true,
            backgroundColor: _kCard,
            collapsedBackgroundColor: _kCard,
            title: const Text('Información general',
                style: TextStyle(color: _kTextMain)),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              DropdownButtonFormField<String>(
                value: _routeType,
                decoration: _dec('Tipo'),
                items: const [
                  'regular',
                  'reten',
                  'express',
                  'evento',
                  'mantenimiento'
                ]
                    .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                validator: (v) => v == null ? 'Seleccione tipo' : null,
                onChanged: (v) => setState(() => _routeType = v),
                dropdownColor: _kCard,
                style: const TextStyle(color: _kTextMain),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerC,
                decoration: _dec('Cliente (empresa)'),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
                style: const TextStyle(color: _kTextMain),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shiftC,
                keyboardType: TextInputType.number,
                decoration: _dec('Personal recogido (Shift)'),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
                style: const TextStyle(color: _kTextMain),
              ),
            ],
          ),
          const SizedBox(height: 12),

          /* CONDUCTOR */
          ExpansionTile(
            backgroundColor: _kCard,
            collapsedBackgroundColor: _kCard,
            title: const Text('Conductor & Horarios',
                style: TextStyle(color: _kTextMain)),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              DropdownButtonFormField<int>(
                value: _driverId,
                decoration: _dec('Conductor'),
                items: vm.carriers
                    .map((c) => DropdownMenuItem(
                  value: c['id'] as int,
                  child: Text(c['name'] as String),
                ))
                    .toList(),
                onChanged: (id) {
                  setState(() {
                    _driverId = id;
                    _driverName = vm.carriers
                        .firstWhere((e) => e['id'] == id)['name'] as String;
                    _vehicle = vm.vehicleForDriver(id!);
                  });
                },
                validator: (v) => v == null ? 'Seleccione conductor' : null,
                dropdownColor: _kCard,
                style: const TextStyle(color: _kTextMain),
              ),
              if (_vehicle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4),
                  child: Text('Vehículo asignado: ${_vehicle!.licensePlate}',
                      style: const TextStyle(color: _kTextSub)),
                ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _depC,
                    readOnly: true,
                    decoration: _dec('Hora salida', Icons.schedule),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
                    style: const TextStyle(color: _kTextMain),
                    onTap: () => _pickTime(_depC),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _arrC,
                    readOnly: true,
                    decoration: _dec('Hora llegada', Icons.schedule),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
                    style: const TextStyle(color: _kTextMain),
                    onTap: () => _pickTime(_arrC),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 12),

          /* DIRECCIONES */
          ExpansionTile(
            initiallyExpanded: true,
            backgroundColor: _kCard,
            collapsedBackgroundColor: _kCard,
            title:
            const Text('Direcciones', style: TextStyle(color: _kTextMain)),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              _autoField(_start),
              ..._stops.map((s) => Row(children: [
                Expanded(child: _autoField(s)),
                const SizedBox(width: 6),
                IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.redAccent),
                    onPressed: () => _removeStop(s))
              ])),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addStop,
                  icon: const Icon(Icons.add, color: _kAction),
                  label: const Text('Agregar parada',
                      style: TextStyle(color: _kAction)),
                ),
              ),
              _autoField(_end),
            ],
          ),
          const SizedBox(height: 12),

          /* MAPA */
          Container(
            height: 270,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kRadius),
              color: _kCard,
            ),
            clipBehavior: Clip.antiAlias,
            child: GoogleMap(
              initialCameraPosition:
              const CameraPosition(target: LatLng(-12.06, -77.04), zoom: 11),
              markers: _markers,
              polylines: _polyline.length < 2
                  ? {}
                  : {
                Polyline(
                  polylineId: const PolylineId('route'),
                  color: Colors.amber,
                  width: 5,
                  points: _polyline,
                )
              },
              onMapCreated: (c) => _mapCtrl = c,
              myLocationEnabled: true,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

/* ---------------------- Campo Autocomplete ---------------------- */
  Widget _autoField(StopPoint p) {
    return Autocomplete<AutocompletePrediction>(
      optionsBuilder: (t) => _searchPlaces(t.text), // ✅  Devuelve Future<Iterable>
      displayStringForOption: (o) => o.description ?? '',
      onSelected: (c) => _selectPrediction(p, c),
      fieldViewBuilder: (ctx, ctl, focus, _) {
        ctl.text = p.controller.text;
        ctl.addListener(() => p.controller.text = ctl.text);
        return TextFormField(
          controller: ctl,
          focusNode: focus,
          decoration: _dec(p.label, Icons.place_outlined),
          style: const TextStyle(color: _kTextMain),
          validator: (v) =>
          v == null || v.trim().isEmpty ? 'Requerido' : null,
          onChanged: (_) {
            p.latLng = null;
            _debounce(_refreshRoute);
          },
        );
      },
      optionsViewBuilder: (ctx, onSelect, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: _kCard,
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 250,
            child: ListView(
              children: opts
                  .map((o) => ListTile(
                title: Text(o.description ?? '',
                    style: const TextStyle(color: _kTextMain)),
                onTap: () => onSelect(o),
              ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
