// lib/features/route_management/presentation/pages/driver/route_driver_detail_screen.dart
/* -------------------------------------------------------------- */
/*         PANTALLA ▸ DETALLE DE RUTA ACTIVA (Conductor)          */
/* -------------------------------------------------------------- */
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir Google Maps

import '../../../../../../core/google_maps_config.dart';
import '../../../../../../core/widgets/app_drawer.dart';
import '../../../../../../core/widgets/app_drawer2.dart';
import '../../../../data/remote/route_model.dart';
import '../../../../data/remote/route_service.dart';

/* --- Estilos --- */
const _kBg = Color(0xFF1E1F24);
const _kCard = Color(0xFF2F353F);
const _kBar = Color(0xFF2C2F38);
const _kAction = Color(0xFFEA8E00);
const _kTextMain = Colors.white;
const _kTextSub = Colors.white70;
const _kRadius = 16.0;

class RouteDriverDetailScreen extends StatefulWidget {
  final RouteModel route;
  final String name, lastName;
  const RouteDriverDetailScreen({
    super.key,
    required this.route,
    required this.name,
    required this.lastName,
  });

  @override
  State<RouteDriverDetailScreen> createState() => _RouteDriverDetailScreenState();
}

class _RouteDriverDetailScreenState extends State<RouteDriverDetailScreen> {
  final _svc = RouteService();
  late RouteModel _currentRoute;
  bool _isLoading = false;

  // Mapa
  GoogleMapController? _mapCtrl;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.route;
    _buildMapElements();
  }

  void _buildMapElements() {
    _markers.clear();
    for (final wp in _currentRoute.waypoints) {
      final isFirst = wp.order == 1;
      final isLast = wp.order == _currentRoute.waypoints.length;
      _markers.add(Marker(
        markerId: MarkerId('wp_${wp.order}'),
        position: LatLng(wp.latitude, wp.longitude),
        infoWindow: InfoWindow(title: wp.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isFirst ? BitmapDescriptor.hueGreen : (isLast ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange),
        ),
      ));
    }
    _drawRoute();
  }

  Future<void> _drawRoute() async {
    if (_currentRoute.waypoints.length < 2) return;
    final points = PolylinePoints();
    final result = await points.getRouteBetweenCoordinates(
      kMapsApiKey,
      PointLatLng(_currentRoute.waypoints.first.latitude, _currentRoute.waypoints.first.longitude),
      PointLatLng(_currentRoute.waypoints.last.latitude, _currentRoute.waypoints.last.longitude),
      travelMode: TravelMode.driving,
      wayPoints: _currentRoute.waypoints.length > 2
          ? _currentRoute.waypoints.sublist(1, _currentRoute.waypoints.length - 1)
          .map((wp) => PolylineWayPoint(location: '${wp.latitude},${wp.longitude}'))
          .toList()
          : [],
    );
    if (result.points.isNotEmpty) {
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        color: _kAction,
        width: 5,
        points: result.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
      ));
    }
    setState(() {});
  }

  // --- Lógica del Botón de Acción ---
  Future<void> _updateRouteStatus() async {
    setState(() => _isLoading = true);
    String newStatus;
    switch (_currentRoute.status.toLowerCase()) {
      case 'asignado':
        newStatus = 'en_camino';
        break;
      case 'en_camino':
      case 'en camino':
        newStatus = 'finalizado';
        break;
      default:
        setState(() => _isLoading = false);
        return;
    }

    final updatedRoute = _currentRoute.copyWith(status: newStatus);

    try {
      final success = await _svc.updateRoute(_currentRoute.id!, updatedRoute);
      if (success && mounted) {
        setState(() {
          _currentRoute = updatedRoute;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Estado de la ruta actualizado a: $newStatus'),
          backgroundColor: Colors.green,
        ));
        if (newStatus == 'finalizado') {
          Navigator.pop(context, true); // Regresa a la lista
        }
      } else {
        throw Exception('El servidor rechazó la actualización.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // --- Sugerencia: Abrir en Google Maps ---
  void _launchGoogleMaps() async {
    if (_currentRoute.waypoints.isEmpty) return;
    final destination = _currentRoute.waypoints.last;
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir Google Maps')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Mi Ruta Actual', style: TextStyle(color: _kTextMain)),
        backgroundColor: _kBar,
        iconTheme: const IconThemeData(color: _kTextMain),
        actions: [
          // Sugerencia: Botón para navegar con Google Maps
          IconButton(
            icon: const Icon(Icons.navigation_outlined, color: _kAction),
            onPressed: _launchGoogleMaps,
            tooltip: 'Navegar con Google Maps',
          )
        ],
      ),
      drawer: AppDrawer2(name: widget.name, lastName: widget.lastName),
      body: _buildBody(),
      bottomNavigationBar: _buildActionButton(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRouteHeader(),
          const SizedBox(height: 24),
          _buildSectionTitle('Puntos de la Ruta'),
          SizedBox(
            height: 250,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_kRadius),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(_currentRoute.waypoints.first.latitude, _currentRoute.waypoints.first.longitude),
                  zoom: 12,
                ),
                markers: _markers,
                polylines: _polylines,
                onMapCreated: (c) {
                  _mapCtrl = c;
                  // Centrar el mapa en la ruta
                  if (_currentRoute.waypoints.length > 1) {
                    Future.delayed(const Duration(milliseconds: 50), () {
                      _mapCtrl?.animateCamera(CameraUpdate.newLatLngBounds(
                        LatLngBounds(
                          southwest: LatLng(
                            _currentRoute.waypoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
                            _currentRoute.waypoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
                          ),
                          northeast: LatLng(
                            _currentRoute.waypoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
                            _currentRoute.waypoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
                          ),
                        ),
                        60,
                      ));
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._currentRoute.waypoints.map((wp) => _buildWaypointTile(wp)),
        ],
      ),
    );
  }

  Widget _buildRouteHeader() {
    return Card(
      color: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentRoute.customer, style: const TextStyle(color: _kTextMain, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_currentRoute.nameRoute.replaceAll('–', '→').replaceAll('-', '→'), style: const TextStyle(color: _kTextSub, fontSize: 16)),
            const Divider(color: _kTextSub, height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoColumn(title: 'Tipo de Servicio', value: _currentRoute.type.capitalize2()),
                _InfoColumn(title: 'Nº de Personal', value: _currentRoute.shift),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: _kTextMain, fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildWaypointTile(Waypoint wp) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _kBg,
        child: Text('${wp.order}', style: const TextStyle(color: _kAction, fontWeight: FontWeight.bold)),
      ),
      title: Text(wp.name, style: const TextStyle(color: _kTextMain)),
      subtitle: Text('Lat: ${wp.latitude.toStringAsFixed(4)}, Lng: ${wp.longitude.toStringAsFixed(4)}', style: const TextStyle(color: _kTextSub)),
      dense: true,
    );
  }

  Widget _buildActionButton() {
    String buttonText;
    IconData buttonIcon;
    VoidCallback? onPressed = _updateRouteStatus;

    switch (_currentRoute.status.toLowerCase()) {
      case 'asignado':
        buttonText = 'Empezar Ruta';
        buttonIcon = Icons.play_arrow_rounded;
        break;
      case 'en camino':
      case 'en_camino':
        buttonText = 'Confirmar Ruta Terminada';
        buttonIcon = Icons.check_rounded;
        break;
      default: // finalizado, cancelado, etc.
        buttonText = 'Ruta Finalizada';
        buttonIcon = Icons.lock_clock_rounded;
        onPressed = null; // Deshabilitar botón
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kAction,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : Icon(buttonIcon),
        label: Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String title;
  final String value;
  const _InfoColumn({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: _kTextSub, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: _kTextMain, fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize2() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}