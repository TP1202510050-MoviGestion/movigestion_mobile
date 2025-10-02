// lib/features/route_management/presentation/pages/businessman/route/assign_route_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/google_maps_config.dart';
import '../../../../../../core/widgets/app_drawer.dart';
import '../../../../data/remote/profile_service.dart';
import '../../../../data/remote/route_model.dart';
import '../../../../data/remote/route_service.dart';
import '../../../../data/remote/vehicle_model.dart';
import '../../../../data/remote/vehicle_service.dart';

/* --- Estilos --- */
const _kBg = Color(0xFF1E1F24);
const _kCard = Color(0xFF2F353F);
const _kBar = Color(0xFF2C2F38);
const _kAction = Color(0xFFEA8E00);
const _kTextMain = Colors.white;
const _kTextSub = Colors.white70;
const _kRadius = 12.0;

// ViewModel para manejar la carga de datos iniciales
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
      final res = await Future.wait([
        profileSvc.getProfileByNameAndLastName(n, l),
        profileSvc.getAllCarriers(),
        vehicleSvc.getAllVehicles(),
      ]);
      final prof = res[0] as dynamic;
      companyName = prof?.companyName ?? '';
      companyRuc = prof?.companyRuc ?? '';
      carriers
        ..clear()
        ..addAll((res[1] as List<dynamic>)
            .map((u) => {'id': u.id, 'name': '${u.name} ${u.lastName}'}));
      for (final v in (res[2] as List<VehicleModel>)) {
        if (v.assignedDriverId != null) _vehicleByDriver[v.assignedDriverId!] = v;
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

// Clase para manejar los puntos de parada
class StopPoint {
  StopPoint(this.label) {
    controller = TextEditingController();
    focusNode = FocusNode();
  }
  final String label;
  late final TextEditingController controller;
  late final FocusNode focusNode;
  LatLng? latLng;

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

// Widget principal que provee el ViewModel
class AssignRouteScreen extends StatelessWidget {
  final String name, lastName;
  const AssignRouteScreen({super.key, required this.name, required this.lastName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      _RouteVM(ProfileService(), VehicleService())..bootstrap(name, lastName),
      child: _AssignRouteBody(userName: name, userLastName: lastName),
    );
  }
}

// Widget con el estado del formulario
class _AssignRouteBody extends StatefulWidget {
  final String userName, userLastName;
  const _AssignRouteBody({required this.userName, required this.userLastName});

  @override
  State<_AssignRouteBody> createState() => _AssignRouteBodyState();
}

class _AssignRouteBodyState extends State<_AssignRouteBody> {
  final _formKey = GlobalKey<FormState>();
  final _customerC = TextEditingController();
  final _dateC = TextEditingController();
  final _depC = TextEditingController();
  final _arrC = TextEditingController();
  DateTime? _selectedDate;

  final _start = StopPoint('Inicio');
  final _end = StopPoint('Destino');
  final List<StopPoint> _stops = [];

  String? _routeType;
  int? _driverId;
  String? _driverName;
  VehicleModel? _vehicle;

  GoogleMapController? _mapCtrl;
  final Set<Marker> _markers = {};
  final PolylinePoints _polylinePoints = PolylinePoints();
  List<LatLng> _polylineCoordinates = [];
  String? _sessionToken;
  bool _sending = false;
  int _personnelCount = 1;
  late final TextEditingController _personnelC;

  @override
  void initState() {
    super.initState();
    _personnelC = TextEditingController(text: _personnelCount.toString());
  }

  @override
  void dispose() {
    _customerC.dispose();
    _dateC.dispose();
    _depC.dispose();
    _arrC.dispose();
    _personnelC.dispose();
    _start.dispose();
    _end.dispose();
    for (final stop in _stops) {
      stop.dispose();
    }
    super.dispose();
  }

  Future<List<AutocompletePrediction>> _searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final resp = await googlePlace.autocomplete.get(query, language: 'es', components: [Component('country', 'pe')], types: 'geocode', sessionToken: _sessionToken);
      return resp?.predictions ?? [];
    } catch (e) {
      _msg('Error buscando lugares: $e');
      return [];
    }
  }

  Future<void> _selectPrediction(StopPoint p, AutocompletePrediction choice) async {
    if (choice.placeId == null) return;
    try {
      final det = await googlePlace.details.get(choice.placeId!, sessionToken: _sessionToken);
      final loc = det?.result?.geometry?.location;
      if (loc == null) return;
      final duplicated = [_start, _end, ..._stops].where((s) => s != p && s.latLng != null).any((s) => (s.latLng!.latitude - loc.lat!).abs() < 1e-5 && (s.latLng!.longitude - loc.lng!).abs() < 1e-5);
      if (duplicated) {
        _msg('Ese punto ya fue agregado');
        return;
      }
      setState(() {
        p.controller.text = det?.result?.formattedAddress ?? choice.description ?? '';
        p.latLng = LatLng(loc.lat!, loc.lng!);
        _refreshRoute();
      });
    } catch (e) {
      _msg('Error obteniendo detalles del lugar: $e');
    }
  }

  void _addStop() => setState(() => _stops.add(StopPoint('Parada ${_stops.length + 1}')));

  void _removeStop(StopPoint p) {
    setState(() {
      p.dispose();
      _stops.remove(p);
      _refreshRoute();
    });
  }

  Future<void> _refreshRoute() async {
    final pts = [
      if (_start.latLng != null) _start.latLng!,
      ..._stops.where((s) => s.latLng != null).map((s) => s.latLng!),
      if (_end.latLng != null) _end.latLng!,
    ];
    setState(() {
      _markers.clear();
      _polylineCoordinates.clear();
      for (var i = 0; i < pts.length; i++) {
        final hue = i == 0 ? BitmapDescriptor.hueGreen : (i == pts.length - 1 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange);
        final title = i == 0 ? 'Inicio' : (i == pts.length - 1 ? 'Destino' : 'Parada');
        _markers.add(Marker(markerId: MarkerId('p$i'), position: pts[i], icon: BitmapDescriptor.defaultMarkerWithHue(hue), infoWindow: InfoWindow(title: title)));
      }
    });
    if (pts.length >= 2) {
      try {
        final res = await _polylinePoints.getRouteBetweenCoordinates(kMapsApiKey, PointLatLng(pts.first.latitude, pts.first.longitude), PointLatLng(pts.last.latitude, pts.last.longitude), travelMode: TravelMode.driving, wayPoints: pts.length > 2 ? pts.sublist(1, pts.length - 1).map((e) => PolylineWayPoint(location: '${e.latitude},${e.longitude}', stopOver: true)).toList() : []);
        if (res.points.isNotEmpty) {
          setState(() => _polylineCoordinates.addAll(res.points.map((e) => LatLng(e.latitude, e.longitude))));
        } else {
          _msg('No se pudo calcular la ruta. Error: ${res.errorMessage}');
        }
      } catch (e) {
        _msg('Error calculando la ruta: $e');
      }
      if (mounted) {
        final neLat = pts.map((e) => e.latitude).reduce((a, b) => a > b ? a : b);
        final neLng = pts.map((e) => e.longitude).reduce((a, b) => a > b ? a : b);
        final swLat = pts.map((e) => e.latitude).reduce((a, b) => a < b ? a : b);
        final swLng = pts.map((e) => e.longitude).reduce((a, b) => a < b ? a : b);
        await _mapCtrl?.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(northeast: LatLng(neLat, neLng), southwest: LatLng(swLat, swLng)), 60));
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      locale: const Locale('es', 'ES'),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateC.text = DateFormat('EEEE, d \'de\' MMMM \'de\' y', 'es_ES').format(pickedDate);
      });
    }
  }

  Future<void> _pickTime(TextEditingController c) async {
    final now = TimeOfDay.now();
    final pick = await showTimePicker(context: context, initialTime: now);
    if (pick != null) {
      final vm = context.read<_RouteVM>();
      c.text = vm.fmtTime.format(DateTime(2000, 1, 1, pick.hour, pick.minute));
    }
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _save() async {
    final vm = context.read<_RouteVM>();
    if (!_formKey.currentState!.validate()) return;
    if (_start.latLng == null || _end.latLng == null) { _msg('Seleccione un punto de partida y destino válidos'); return; }
    if (_driverId == null) { _msg('Seleccione conductor'); return; }
    if (_selectedDate == null) { _msg('Por favor, seleccione una fecha para la ruta'); return; }

    final routeDate = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
    final depTime = vm.fmtTime.parse(_depC.text);
    final arrTime = vm.fmtTime.parse(_arrC.text);

    DateTime departureDateTime = routeDate.add(Duration(hours: depTime.hour, minutes: depTime.minute));
    DateTime arrivalDateTime = routeDate.add(Duration(hours: arrTime.hour, minutes: arrTime.minute));

    if (arrivalDateTime.isBefore(departureDateTime)) {
      arrivalDateTime = arrivalDateTime.add(const Duration(days: 1));
      _msg('Nota: La hora de llegada es al día siguiente.');
    }

    setState(() => _sending = true);
    final List<Waypoint> wps = [];
    int order = 1;
    void addWaypoint(String defaultName, StopPoint p) {
      if (p.latLng != null) {
        wps.add(Waypoint(order: order++, name: p.controller.text.trim().isNotEmpty ? p.controller.text.trim() : defaultName, latitude: p.latLng!.latitude, longitude: p.latLng!.longitude));
      }
    }
    addWaypoint('Inicio', _start);
    for (final s in _stops) { addWaypoint('Parada', s); }
    addWaypoint('Destino', _end);

    final route = RouteModel(
      type: _routeType!,
      customer: _customerC.text.trim(),
      nameRoute: '${_start.controller.text.trim()} - ${_end.controller.text.trim()}',
      status: 'asignado',
      shift: _personnelC.text,
      driverId: _driverId,
      driverName: _driverName,
      vehicleId: _vehicle?.id,
      vehiclePlate: _vehicle?.licensePlate,
      departureTime: departureDateTime,
      arrivalTime: arrivalDateTime,
      waypoints: wps,
      lastLatitude: wps.first.latitude,
      lastLongitude: wps.first.longitude,
      createdAt: DateTime.now(),
      updatedAt: null,
      companyName: vm.companyName,
      companyRuc: vm.companyRuc,
    );
    try {
      final ok = await RouteService().createRoute(route);
      if (!mounted) return;
      if (ok) {
        _msg('Ruta creada con éxito');
        Navigator.pop(context, true);
      } else {
        _msg('Error: No se pudo crear la ruta. El servidor respondió negativamente.');
      }
    } catch (e) {
      _msg('Error al guardar la ruta: $e');
    } finally {
      if (mounted) { setState(() => _sending = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<_RouteVM>();
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBar,
        title: const Row(
          children: [
            Icon(Icons.add_road_outlined, color: _kAction, size: 22),
            SizedBox(width: 10),
            Text('Crear Nueva Ruta', style: TextStyle(color: _kTextMain, fontSize: 18)),
          ],
        ),
      ),
      drawer: AppDrawer(
        name: widget.userName,
        lastName: widget.userLastName,
        companyName: vm.companyName, // Usamos los datos del ViewModel
        companyRuc: vm.companyRuc,     // Usamos los datos del ViewModel
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator(color: _kAction))
          : (vm.error != null
          ? Center(child: Text('Error: ${vm.error}', style: const TextStyle(color: Colors.red)))
          : _buildForm(vm)),
      bottomNavigationBar: BottomAppBar(
        color: _kBg,
        elevation: 0,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: _kTextSub),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Cerrar', style: TextStyle(color: _kTextSub)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _sending ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _kAction,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.save_alt_outlined, color: Colors.black),
                label: const Text('Crear Ruta', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(_RouteVM vm) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          _buildSection(
            title: 'Información General',
            icon: Icons.info_outline,
            children: [
              _buildDropdownType(),
              const SizedBox(height: 16),
              _buildTextField(_customerC, 'Cliente (Empresa)', Icons.business_outlined),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Personal a Recoger", style: TextStyle(color: _kTextSub, fontSize: 13, fontWeight: FontWeight.w500)),
                        SizedBox(height: 4),
                        Text("Cantidad de personas que abordarán el vehículo.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildPersonnelCounter(),
                ],
              ),
            ],
          ),
          _buildSection(
            title: 'Asignación',
            icon: Icons.person_pin_circle_outlined,
            children: [
              _buildDriverDropdown(vm),
              if (_vehicle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: _buildVehicleInfoChip(),
                ),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _buildTimePicker(_depC, 'Hora de Salida')),
                const SizedBox(width: 12),
                Expanded(child: _buildTimePicker(_arrC, 'Hora de Llegada')),
              ]),
            ],
          ),
          _buildSection(
            title: 'Paradas de la Ruta',
            icon: Icons.alt_route,
            isInitiallyExpanded: true,
            children: [
              _autoField(_start, 'Punto de Partida'),
              const SizedBox(height: 12),
              ..._stops.map((s) => _buildStopRow(s)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addStop,
                  icon: const Icon(Icons.add_circle_outline, color: _kAction),
                  label: const Text('Agregar parada intermedia', style: TextStyle(color: _kAction)),
                ),
              ),
              _autoField(_end, 'Punto de Destino'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 270,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_kRadius),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(target: LatLng(-12.06, -77.04), zoom: 11),
                markers: _markers,
                polylines: _polylineCoordinates.isNotEmpty
                    ? { Polyline(polylineId: const PolylineId('route'), color: _kAction, width: 5, points: _polylineCoordinates) }
                    : {},
                onMapCreated: (c) => _mapCtrl = c,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isInitiallyExpanded = false,
  }) {
    return Card(
      color: _kCard,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: isInitiallyExpanded,
        iconColor: _kTextSub,
        collapsedIconColor: _kTextSub,
        title: Row(
          children: [
            Icon(icon, color: _kAction),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: _kTextMain, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: children),
          )
        ],
      ),
    );
  }

  Widget _buildPersonnelCounter() {
    return Container(
      width: 130,
      height: 48,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      child: FormField<int>(
        initialValue: _personnelCount,
        validator: (val) {
          if (val == null || val <= 0) return 'Inválido';
          if (val > 150) return 'Máx. 150';
          return null;
        },
        builder: (state) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$_personnelCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _kTextMain, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: _kCard.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(_kRadius), bottomRight: Radius.circular(_kRadius)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 30,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.keyboard_arrow_up, color: _kAction),
                        onPressed: () {
                          if (_personnelCount < 150) {
                            setState(() {
                              _personnelCount++;
                              _personnelC.text = _personnelCount.toString();
                              state.didChange(_personnelCount);
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      height: 24,
                      width: 30,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.keyboard_arrow_down, color: _kAction),
                        onPressed: () {
                          if (_personnelCount > 1) {
                            setState(() {
                              _personnelCount--;
                              _personnelC.text = _personnelCount.toString();
                              state.didChange(_personnelCount);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdownType() {
    return DropdownButtonFormField<String>(
      value: _routeType,
      decoration: _dec('Tipo de Servicio', Icons.category_outlined),
      items: const ['regular', 'reten', 'express', 'evento', 'mantenimiento']
          .map((e) => DropdownMenuItem(value: e, child: Text(e.capitalize3())))
          .toList(),
      validator: (v) => v == null ? 'Seleccione un tipo' : null,
      onChanged: (v) => setState(() => _routeType = v),
      dropdownColor: _kCard,
      style: const TextStyle(color: _kTextMain),
    );
  }

  Widget _buildDriverDropdown(_RouteVM vm) {
    return DropdownButtonFormField<int>(
      value: _driverId,
      decoration: _dec('Asignar a Conductor', Icons.person_search_outlined),
      items: vm.carriers.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['name'] as String))).toList(),
      onChanged: (id) {
        setState(() {
          _driverId = id;
          _driverName = vm.carriers.firstWhere((e) => e['id'] == id)['name'] as String;
          _vehicle = vm.vehicleForDriver(id!);
        });
      },
      validator: (v) => v == null ? 'Seleccione un conductor' : null,
      dropdownColor: _kCard,
      style: const TextStyle(color: _kTextMain),
    );
  }

  Widget _buildVehicleInfoChip() {
    return Chip(
      avatar: const Icon(Icons.directions_car, color: _kAction, size: 18),
      label: Text('Vehículo: ${_vehicle!.licensePlate}', style: const TextStyle(color: _kTextMain)),
      backgroundColor: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildTextField(TextEditingController c, String label, IconData icon) {
    return TextFormField(
      controller: c,
      decoration: _dec(label, icon),
      validator: (v) => v == null || v.trim().isEmpty ? 'Este campo es requerido' : null,
      style: const TextStyle(color: _kTextMain),
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      controller: _dateC,
      readOnly: true,
      decoration: _dec('Fecha de la Ruta', Icons.calendar_today_outlined),
      validator: (v) => v == null || v.isEmpty ? 'Seleccione una fecha' : null,
      style: const TextStyle(color: _kTextMain, fontWeight: FontWeight.w500),
      onTap: _pickDate,
    );
  }

  Widget _buildTimePicker(TextEditingController c, String label) {
    return TextFormField(
      controller: c,
      readOnly: true,
      decoration: _dec(label, Icons.schedule_outlined),
      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
      style: const TextStyle(color: _kTextMain, fontWeight: FontWeight.w500),
      onTap: () => _pickTime(c),
    );
  }

  Widget _buildStopRow(StopPoint s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(child: _autoField(s, 'Parada intermedia')),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
            onPressed: () => _removeStop(s),
            tooltip: 'Eliminar parada',
          )
        ],
      ),
    );
  }

  Widget _autoField(StopPoint p, String label) {
    return Autocomplete<AutocompletePrediction>(
      optionsBuilder: (txt) => _searchPlaces(txt.text),
      displayStringForOption: (o) => o.description ?? '',
      onSelected: (c) => _selectPrediction(p, c),
      initialValue: TextEditingValue(text: p.controller.text),
      fieldViewBuilder: (ctx, ctl, focus, onFieldSubmitted) {
        return TextFormField(
          controller: ctl,
          focusNode: focus,
          decoration: _dec(label, Icons.location_on_outlined),
          style: const TextStyle(color: _kTextMain),
          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
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
            child: opts.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Sin resultados', style: TextStyle(color: _kTextSub))))
                : ListView(
              padding: EdgeInsets.zero,
              children: opts.map((o) => ListTile(
                leading: const Icon(Icons.location_on_outlined, color: _kAction),
                title: Text(o.description ?? '', style: const TextStyle(color: _kTextMain)),
                onTap: () => onSelect(o),
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String l, [IconData? ic]) => InputDecoration(
    prefixIcon: ic != null ? Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Icon(ic, color: _kTextSub, size: 20),
    ) : null,
    labelText: l,
    labelStyle: const TextStyle(color: _kTextSub),
    filled: true,
    fillColor: _kBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(_kRadius), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_kRadius), borderSide: const BorderSide(color: _kAction)),
  );
}

extension StringExtension on String {
  String capitalize3() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}