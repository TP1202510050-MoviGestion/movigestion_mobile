// lib/features/route_management/presentation/pages/businessman/route/route_detail_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:intl/intl.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../../../../../../core/google_maps_config.dart';
import '../../../../../../core/widgets/app_drawer.dart';
import '../../../../data/remote/route_model.dart';
import '../../../../data/remote/route_service.dart';
import '../../../../data/remote/profile_service.dart';

/* --- colores --- */
const _kBg = Color(0xFF1E1F24);
const _kCard = Color(0xFF2F353F);
const _kBar = Color(0xFF2C2F38);
const _kAction = Color(0xFFEA8E00);
const _kTextMain = Colors.white;
const _kTextSub = Colors.white70;
const _kRadius = 12.0;

// Clase interna para manejar los puntos editables
class _EditableStopPoint {
  final TextEditingController controller;
  LatLng latLng;

  _EditableStopPoint(Waypoint originalWaypoint)
      : controller = TextEditingController(text: originalWaypoint.name),
        latLng = LatLng(originalWaypoint.latitude, originalWaypoint.longitude);

  _EditableStopPoint.custom({
    required String name,
    required double lat,
    required double lng,
  })  : controller = TextEditingController(text: name),
        latLng = LatLng(lat, lng);

  void dispose() => controller.dispose();
}

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
  final _fmtDate = DateFormat('EEEE, d \'de\' MMMM \'de\' y', 'es_ES');
  final _formKey = GlobalKey<FormState>();

  // Campos principales
  late TextEditingController _customerC;
  late TextEditingController _shiftC;
  late TextEditingController _dateC;
  late TextEditingController _departureC;
  late TextEditingController _arrivalC;

  late DateTime _selectedDate;
  late String _type;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _initialized = false;

  // Conductor
  int? _driverId;
  String? _driverName;
  List<Map<String, dynamic>> _availableDrivers = [];
  bool _isLoadingDrivers = true;

  // Mapa y ruta
  GoogleMapController? _mapCtrl;
  final Set<Marker> _markers = {};
  final PolylinePoints _polylinePoints = PolylinePoints();
  List<LatLng> _polylineCoordinates = [];
  List<_EditableStopPoint> _editableWaypoints = [];
  String? _sessionToken; // Mantener nulo (no usamos sesión avanzada)

  @override
  void initState() {
    super.initState();
    _initializeStateFromRoute(widget.route);
    _loadAvailableDrivers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshRouteAndCamera();
    });
  }

  @override
  void dispose() {
    _customerC.dispose();
    _shiftC.dispose();
    _dateC.dispose();
    _departureC.dispose();
    _arrivalC.dispose();
    for (var p in _editableWaypoints) {
      p.dispose();
    }
    super.dispose();
  }

  // Inicializa o resetea el estado a partir de la ruta
  void _initializeStateFromRoute(RouteModel r) {
    if (!_initialized) {
      _customerC = TextEditingController();
      _shiftC = TextEditingController();
      _dateC = TextEditingController();
      _departureC = TextEditingController();
      _arrivalC = TextEditingController();
      _initialized = true;
    }

    _type = r.type;
    _customerC.text = r.customer;
    _shiftC.text = r.shift;
    _driverId = r.driverId;
    _driverName = r.driverName;

    final dep = r.departureTime!;
    final arr = r.arrivalTime!;
    _selectedDate = DateTime(dep.year, dep.month, dep.day);
    _dateC.text = _fmtDate.format(_selectedDate);
    _departureC.text = _fmtTime.format(dep);
    _arrivalC.text = _fmtTime.format(arr);

    // Reconstruimos los waypoints editables
    for (var p in _editableWaypoints) {
      p.dispose();
    }
    _editableWaypoints = r.waypoints
        .map((wp) => _EditableStopPoint(wp))
        .toList();
  }

  // Carga de conductores disponibles (similar a AssignRouteScreen)
  Future<void> _loadAvailableDrivers() async {
    setState(() {
      _isLoadingDrivers = true;
    });

    try {
      final profileSvc = ProfileService();

      // Obtenemos el perfil del usuario (igual que en AssignRouteScreen)
      final prof = await profileSvc.getProfileByNameAndLastName(
        widget.name,
        widget.lastName,
      );

      final allCarriers = await profileSvc.getAllCarriers();

      // Si el perfil tiene empresa, filtramos por esa empresa.
      // Si no, mostramos todos (mismo comportamiento práctico que AssignRouteScreen).
      final String? companyName = prof?.companyName;
      final String? companyRuc = prof?.companyRuc;

      final filtered = (companyName != null && companyRuc != null)
          ? allCarriers.where((c) {
        return (c.companyName ?? '') == companyName &&
            (c.companyRuc ?? '') == companyRuc;
      }).toList()
          : allCarriers;

      final mapped = filtered
          .map<Map<String, dynamic>>(
            (c) => {
          'id': c.id,
          'name': '${c.name} ${c.lastName}',
        },
      )
          .toList();

      // Aseguramos que el conductor actual siga apareciendo en el dropdown
      if (_driverId != null &&
          _driverName != null &&
          mapped.every((d) => d['id'] != _driverId)) {
        mapped.insert(0, {
          'id': _driverId,
          'name': _driverName!,
        });
      }

      if (!mounted) return;
      setState(() {
        _availableDrivers = mapped;
        _isLoadingDrivers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDrivers = false;
      });
      _msg('Error al cargar la lista de conductores: $e', isError: true);
    }
  }

  // Autocomplete: mantenemos sesión simple
  void _startNewAutocompleteSession() => _sessionToken = null;

  Future<List<AutocompletePrediction>> _searchPlaces(String query) async {
    if (query.trim().isEmpty || !_isEditing) return [];
    try {
      final resp = await googlePlace.autocomplete.get(
        query,
        language: 'es',
        components: [Component('country', 'pe')],
        sessionToken: _sessionToken,
      );
      return resp?.predictions ?? [];
    } catch (e) {
      _msg('Error buscando lugares: $e', isError: true);
      return [];
    }
  }

  Future<void> _selectPrediction(
      _EditableStopPoint p, AutocompletePrediction choice) async {
    if (choice.placeId == null) return;
    try {
      final det = await googlePlace.details.get(
        choice.placeId!,
        sessionToken: _sessionToken,
      );
      final loc = det?.result?.geometry?.location;
      if (loc == null) return;
      setState(() {
        p.controller.text =
            det?.result?.formattedAddress ?? choice.description ?? '';
        p.latLng = LatLng(loc.lat!, loc.lng!);
        _refreshRouteAndCamera();
      });
    } catch (e) {
      _msg('Error obteniendo detalles del lugar: $e', isError: true);
    }
  }

  // Tap en mapa para añadir waypoint nuevo en modo edición
  void _onMapTap(LatLng pos) async {
    if (!_isEditing) return;
    final name = await _askForText('Nombre del nuevo punto');
    if (name == null || name.trim().isEmpty) return;
    setState(() {
      _editableWaypoints.add(
        _EditableStopPoint.custom(
          name: name.trim(),
          lat: pos.latitude,
          lng: pos.longitude,
        ),
      );
      _refreshRouteAndCamera();
    });
  }

  void _removeWaypoint(_EditableStopPoint p) {
    if (_editableWaypoints.length <= 2) return;
    setState(() {
      p.dispose();
      _editableWaypoints.remove(p);
      _refreshRouteAndCamera();
    });
  }

  Future<void> _refreshRouteAndCamera() async {
    final pts = _editableWaypoints.map((p) => p.latLng).toList();
    _updateMarkers(pts);
    await _updatePolyline(pts);
    if (mounted) {
      setState(() {});
    }
  }

  void _updateMarkers(List<LatLng> pts) {
    _markers.clear();
    for (var i = 0; i < pts.length; i++) {
      final isFirst = i == 0;
      final isLast = i == pts.length - 1;
      _markers.add(
        Marker(
          markerId: MarkerId('p$i'),
          position: pts[i],
          infoWindow:
          InfoWindow(title: _editableWaypoints[i].controller.text),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isFirst
                ? BitmapDescriptor.hueGreen
                : (isLast
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueOrange),
          ),
        ),
      );
    }
  }

  Future<void> _updatePolyline(List<LatLng> pts) async {
    _polylineCoordinates.clear();
    if (pts.length < 2) return;
    try {
      final res = await _polylinePoints.getRouteBetweenCoordinates(
        kMapsApiKey,
        PointLatLng(pts.first.latitude, pts.first.longitude),
        PointLatLng(pts.last.latitude, pts.last.longitude),
        travelMode: TravelMode.driving,
        wayPoints: pts.length > 2
            ? pts
            .sublist(1, pts.length - 1)
            .map(
              (e) => PolylineWayPoint(
            location: '${e.latitude},${e.longitude}',
            stopOver: true,
          ),
        )
            .toList()
            : [],
      );
      if (res.points.isNotEmpty) {
        _polylineCoordinates.addAll(
          res.points
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList(),
        );
      }
    } catch (e) {
      _msg('Error al trazar la ruta: $e', isError: true);
    }
  }

  void _zoomToFitRoute(List<LatLng> pts) {
    if (pts.isEmpty || _mapCtrl == null) return;
    if (pts.length == 1) {
      _mapCtrl!.animateCamera(
        CameraUpdate.newLatLngZoom(pts.first, 15),
      );
      return;
    }
    final lats = pts.map((p) => p.latitude).toList();
    final lngs = pts.map((p) => p.longitude).toList();

    final bounds = LatLngBounds(
      southwest: LatLng(
        lats.reduce((a, b) => a < b ? a : b),
        lngs.reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        lats.reduce((a, b) => a > b ? a : b),
        lngs.reduce((a, b) => a > b ? a : b),
      ),
    );
    _mapCtrl!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }

  // Guardar cambios
  Future<void> _save() async {
    if (!_isEditing) return;
    if (!_formKey.currentState!.validate()) return;
    if (_editableWaypoints.length < 2) {
      _msg('Debe haber al menos un punto de inicio y destino.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Combinar fecha + horas
      final routeDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final depTime = _fmtTime.parse(_departureC.text);
      final arrTime = _fmtTime.parse(_arrivalC.text);

      DateTime departureDateTime = routeDate.add(
        Duration(hours: depTime.hour, minutes: depTime.minute),
      );
      DateTime arrivalDateTime = routeDate.add(
        Duration(hours: arrTime.hour, minutes: arrTime.minute),
      );

      if (arrivalDateTime.isBefore(departureDateTime)) {
        arrivalDateTime = arrivalDateTime.add(const Duration(days: 1));
      }

      // Mapear waypoints
      final waypointsToSave = _editableWaypoints.asMap().entries.map((entry) {
        final idx = entry.key;
        final point = entry.value;
        return Waypoint(
          order: idx + 1,
          name: point.controller.text.trim().isEmpty
              ? 'Punto ${idx + 1}'
              : point.controller.text.trim(),
          latitude: point.latLng.latitude,
          longitude: point.latLng.longitude,
        );
      }).toList();

      final updated = widget.route.copyWith(
        type: _type,
        customer: _customerC.text.trim(),
        shift: _shiftC.text.trim(),
        driverId: _driverId,
        driverName: _driverName,
        departureTime: departureDateTime,
        arrivalTime: arrivalDateTime,
        waypoints: waypointsToSave,
        lastLatitude: waypointsToSave.first.latitude,
        lastLongitude: waypointsToSave.first.longitude,
        nameRoute:
        '${waypointsToSave.first.name} → ${waypointsToSave.last.name}',
        updatedAt: DateTime.now(),
      );

      final ok = await _svc.updateRoute(updated.id!, updated);
      if (!mounted) return;

      if (ok) {
        _msg('Ruta actualizada con éxito');
        Navigator.pop(context, updated);
      } else {
        _msg('Error al guardar. El servidor respondió negativamente.',
            isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _msg('Error de red al guardar: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Selector de fecha
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('es', 'ES'),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateC.text = _fmtDate.format(pickedDate);
      });
    }
  }

  // Selector de hora
  Future<void> _pickTime(TextEditingController ctl) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
    );
    if (picked != null) {
      final dt = DateTime(2000, 1, 1, picked.hour, picked.minute);
      ctl.text = _fmtTime.format(dt);
    }
  }

  Future<String?> _askForText(String title) async {
    final ctl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title, style: const TextStyle(color: _kTextMain)),
        content: TextField(
          controller: ctl,
          autofocus: true,
          style: const TextStyle(color: _kTextMain),
          decoration: _dec('Ej: Almacén Principal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: _kTextSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kAction),
            onPressed: () => Navigator.pop(context, ctl.text),
            child: const Text('Aceptar',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBar,
        title: Text(
          _isEditing ? 'Editando Ruta' : 'Detalle de Ruta',
          style: const TextStyle(color: _kTextMain),
        ),
        iconTheme: const IconThemeData(color: _kTextMain),
        actions: [
          if (_isEditing)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: _kAction,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.save_outlined),
              onPressed: _isSaving ? null : _save,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _initializeStateFromRoute(widget.route);
                  _refreshRouteAndCamera();
                });
              },
            ),
        ],
      ),
      drawer: AppDrawer(
        name: widget.name,
        lastName: widget.lastName,
        companyName: widget.route.companyName,
        companyRuc: widget.route.companyRuc,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            _buildSectionTitle('Información del Servicio'),
            _buildInfoCard(
              children: [
                _buildDropdownType(),
                _txt('Cliente', _customerC),
                _buildDriverDropdownField(),
                _buildPersonnelCounterField(),
                _txt(
                  'Fecha de la Ruta',
                  _dateC,
                  readOnly: true,
                  icon: Icons.calendar_today_outlined,
                  onTap: _isEditing ? _pickDate : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _txt(
                        'Hora de Salida',
                        _departureC,
                        readOnly: true,
                        icon: Icons.schedule_outlined,
                        onTap: _isEditing
                            ? () => _pickTime(_departureC)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _txt(
                        'Hora de Llegada',
                        _arrivalC,
                        readOnly: true,
                        icon: Icons.schedule_outlined,
                        onTap: _isEditing
                            ? () => _pickTime(_arrivalC)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _buildSectionTitle(
              'Puntos de la Ruta',
              subtitle:
              _isEditing ? 'Toca el mapa para añadir un punto' : null,
            ),
            SizedBox(
              height: 250,
              child: AbsorbPointer(
                absorbing: !_isEditing,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_kRadius),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _editableWaypoints.isNotEmpty
                          ? _editableWaypoints.first.latLng
                          : const LatLng(-12.046374, -77.042793),
                      zoom: 12,
                    ),
                    markers: _markers,
                    polylines: {
                      if (_polylineCoordinates.isNotEmpty)
                        Polyline(
                          polylineId: const PolylineId('route'),
                          color: _kAction,
                          width: 5,
                          points: _polylineCoordinates,
                        ),
                    },
                    onTap: _onMapTap,
                    onMapCreated: (c) {
                      _mapCtrl = c;
                      if (_editableWaypoints.isNotEmpty) {
                        _zoomToFitRoute(
                          _editableWaypoints
                              .map((p) => p.latLng)
                              .toList(),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_isEditing)
              ..._editableWaypoints
                  .map(_buildEditableWaypointTile)
                  .toList()
            else
              ..._editableWaypoints
                  .map(_buildReadOnlyWaypointTile)
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _kTextMain,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: _kTextSub,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      color: _kCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: children
              .map(
                (e) => Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 6),
              child: e,
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDropdownType() {
    const options = ['regular', 'reten', 'express', 'evento', 'mantenimiento'];
    return AbsorbPointer(
      absorbing: !_isEditing,
      child: DropdownButtonFormField<String>(
        value: _type,
        decoration: _dec('Tipo de Servicio'),
        dropdownColor: _kCard,
        items: options
            .map(
              (e) => DropdownMenuItem(
            value: e,
            child: Text(e.capitalize2()),
          ),
        )
            .toList(),
        onChanged:
        _isEditing ? (v) => setState(() => _type = v!) : null,
        validator: (v) =>
        v == null || v.isEmpty ? 'Requerido' : null,
        style: const TextStyle(color: _kTextMain),
      ),
    );
  }

  Widget _buildDriverDropdownField() {
    if (_isLoadingDrivers) {
      return const SizedBox(
        height: 58,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _kAction,
          ),
        ),
      );
    }

    if (_availableDrivers.isEmpty) {
      return TextFormField(
        readOnly: true,
        decoration: _dec('Conductor asignado').copyWith(
          hintText: _driverName ?? 'No hay conductores disponibles',
          hintStyle: TextStyle(
            color: _driverName != null
                ? _kTextSub
                : Colors.redAccent,
          ),
        ),
        style: const TextStyle(color: _kTextSub),
      );
    }

    return AbsorbPointer(
      absorbing: !_isEditing,
      child: DropdownButtonFormField<int>(
        value: _driverId,
        decoration: _dec('Conductor asignado'),
        hint: const Text(
          'Selecciona un conductor',
          style: TextStyle(color: _kTextSub),
        ),
        items: _availableDrivers
            .map(
              (d) => DropdownMenuItem<int>(
            value: d['id'] as int,
            child: Text(d['name'] as String),
          ),
        )
            .toList(),
        onChanged: _isEditing
            ? (value) {
          if (value == null) return;
          setState(() {
            _driverId = value;
            _driverName = _availableDrivers
                .firstWhere(
                  (d) => d['id'] == value,
            )['name'] as String;
          });
        }
            : null,
        validator: (v) {
          if (_isEditing && (v == null || v == 0)) {
            return 'Debe asignar un conductor';
          }
          return null;
        },
        dropdownColor: _kCard,
        style: TextStyle(
          color: _isEditing ? _kTextMain : _kTextSub,
        ),
      ),
    );
  }

  Widget _buildPersonnelCounterField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Número de personal a recoger',
          style: TextStyle(color: _kTextSub, fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _shiftC,
          readOnly: !_isEditing,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _isEditing ? _kTextMain : _kTextSub,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          decoration: _dec('').copyWith(
            prefixIcon: _isEditing
                ? SizedBox(
              width: 48,
              child: IconButton(
                icon: const Icon(
                  Icons.remove,
                  color: _kAction,
                  size: 20,
                ),
                onPressed: () {
                  final current =
                      int.tryParse(_shiftC.text) ?? 1;
                  if (current > 1) {
                    setState(() {
                      _shiftC.text =
                          (current - 1).toString();
                    });
                  }
                },
              ),
            )
                : null,
            suffixIcon: _isEditing
                ? SizedBox(
              width: 48,
              child: IconButton(
                icon: const Icon(
                  Icons.add,
                  color: _kAction,
                  size: 20,
                ),
                onPressed: () {
                  final current =
                      int.tryParse(_shiftC.text) ?? 0;
                  if (current < 150) {
                    setState(() {
                      _shiftC.text =
                          (current + 1).toString();
                    });
                  }
                },
              ),
            )
                : null,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'Requerido';
            }
            final val = int.tryParse(v);
            if (val == null || val <= 0) {
              return 'Debe ser > 0';
            }
            if (val > 150) {
              return 'Máx. 150';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildReadOnlyWaypointTile(_EditableStopPoint p) {
    final index = _editableWaypoints.indexOf(p) + 1;
    return Card(
      color: _kCard.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _kAction,
          foregroundColor: Colors.black,
          child: Text(
            '$index',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          p.controller.text,
          style: const TextStyle(color: _kTextMain),
        ),
      ),
    );
  }

  Widget _buildEditableWaypointTile(_EditableStopPoint p) {
    final index = _editableWaypoints.indexOf(p);
    final total = _editableWaypoints.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(child: _autoField(p, index, total)),
          if (total > 2)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent),
              onPressed: () => _removeWaypoint(p),
            ),
        ],
      ),
    );
  }

  Widget _autoField(
      _EditableStopPoint p, int index, int total) {
    String label;
    if (index == 0) {
      label = 'Punto de Partida';
    } else if (index == total - 1) {
      label = 'Punto de Destino';
    } else {
      label = 'Parada #$index';
    }

    return Autocomplete<AutocompletePrediction>(
      optionsBuilder: (txt) => _searchPlaces(txt.text),
      displayStringForOption: (o) => o.description ?? '',
      onSelected: (c) => _selectPrediction(p, c),
      initialValue: TextEditingValue(text: p.controller.text),
      fieldViewBuilder:
          (ctx, ctl, focus, onFieldSubmitted) {
        focus.addListener(() {
          if (focus.hasFocus) {
            _startNewAutocompleteSession();
          }
        });
        return TextFormField(
          controller: ctl,
          focusNode: focus,
          style: const TextStyle(color: _kTextMain),
          decoration: _dec(label),
          validator: (v) =>
          v == null || v.trim().isEmpty
              ? 'Requerido'
              : null,
          onChanged: (val) {
            p.controller.text = val;
          },
        );
      },
      optionsViewBuilder:
          (ctx, onSelect, opts) =>
          Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: _kCard,
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints:
                const BoxConstraints(maxHeight: 220),
                child: opts.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Sin resultados',
                      style: TextStyle(color: _kTextSub),
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: opts.length,
                  itemBuilder: (c, i) {
                    final o = opts.elementAt(i);
                    return ListTile(
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: _kAction,
                      ),
                      title: Text(
                        o.description ?? '',
                        style: const TextStyle(
                            color: _kTextMain),
                      ),
                      onTap: () => onSelect(o),
                    );
                  },
                ),
              ),
            ),
          ),
    );
  }

  Widget _txt(
      String lbl,
      TextEditingController c, {
        TextInputType kb = TextInputType.text,
        bool readOnly = false,
        IconData? icon,
        VoidCallback? onTap,
      }) {
    return TextFormField(
      controller: c,
      readOnly: readOnly || !_isEditing,
      keyboardType: kb,
      style: TextStyle(
        color: _isEditing ? _kTextMain : _kTextSub,
      ),
      decoration: _dec(lbl).copyWith(
        suffixIcon: icon != null
            ? Icon(icon, color: _kAction)
            : null,
      ),
      validator: (v) =>
      v == null || v.trim().isEmpty
          ? 'Requerido'
          : null,
      onTap: onTap,
    );
  }

  InputDecoration _dec(String lbl) => InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(color: _kTextSub),
    filled: true,
    fillColor: _kBg,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kRadius),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kRadius),
      borderSide: const BorderSide(color: _kAction),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_kRadius),
      borderSide: BorderSide.none,
    ),
  );

  void _msg(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? Colors.redAccent : Colors.green,
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize2() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
