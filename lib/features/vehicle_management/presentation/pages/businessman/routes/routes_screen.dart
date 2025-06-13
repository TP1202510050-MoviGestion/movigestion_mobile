// lib/features/route_management/presentation/pages/businessman/route/routes_screen.dart
/* -------------------------------------------------------------- */
/*                  LISTADO DE RUTAS (Company)                    */
/* -------------------------------------------------------------- */
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/widgets/app_drawer.dart';
import '../../../../data/remote/route_model.dart';
import '../../../../data/remote/route_service.dart';
import '../../../../data/remote/profile_service.dart';
import 'assign_route_screen.dart';
import 'route_detail_screen.dart';

/* --- colores compartidos --- */
const _kBg = Color(0xFF1C1E24);
const _kCard = Color(0xFF2F353F);
const _kBar = Color(0xFF2C2F38);
const _kAction = Color(0xFFFFA000);
const _kTextMain = Colors.white;
const _kTextSub = Colors.white70;

class RoutesScreen extends StatefulWidget {
  final String name;
  final String lastName;
  const RoutesScreen({super.key, required this.name, required this.lastName});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final _svc = RouteService();
  final _profileSvc = ProfileService();

  final List<RouteModel> _routes = [];
  bool _loading = true;

  late String _companyName;
  late String _companyRuc;

  @override
  void initState() {
    super.initState();
    _loadCompanyAndRoutes();
  }

  Future<void> _loadCompanyAndRoutes() async {
    final prof = await _profileSvc.getProfileByNameAndLastName(
        widget.name, widget.lastName);
    _companyName = prof?.companyName ?? '';
    _companyRuc  = prof?.companyRuc  ?? '';

    await _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    setState(() => _loading = true);
    try {
      final all = await _svc.getAllRoutes();
      _routes
        ..clear()
        ..addAll(all.where((r) =>
        r.companyName == _companyName &&
            r.companyRuc  == _companyRuc));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al cargar rutas'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addRoute(RouteModel r) =>
      setState(() => _routes.insert(0, r));

  /* ============================ build ============================ */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBar,
        title: const Text('Rutas', style: TextStyle(color: _kTextMain)),
        iconTheme: const IconThemeData(color: _kTextMain),
      ),
      drawer: AppDrawer(name: widget.name, lastName: widget.lastName),
      body: RefreshIndicator(
        onRefresh: _fetchRoutes,
        color: Colors.amber,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kAction))
            : _routes.isEmpty
            ? ListView(children: const [
          SizedBox(height: 120),
          Center(child: Text('No hay rutas', style: TextStyle(color: _kTextSub))),
        ])
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _routes.length,
          itemBuilder: (_, i) => _RouteCard(
            route: _routes[i],
            onTap: () async {
              final updated = await Navigator.push<RouteModel?>(
                context,
                MaterialPageRoute(
                  builder: (_) => RouteDetailScreen(
                    route: _routes[i],
                    name: widget.name,
                    lastName: widget.lastName,
                  ),
                ),
              );
              if (updated != null) {
                _routes[i] = updated;
                setState(() {});
              }
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addRoute',
        backgroundColor: _kAction,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Nueva ruta', style: TextStyle(color: Colors.black)),
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AssignRouteScreen(name: widget.name, lastName: widget.lastName),
            ),
          );
          if (ok == true) _fetchRoutes();
        },
      ),
    );
  }
}

/* ---------- Card de ruta ---------- */
class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, required this.onTap});
  final RouteModel route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.Hm();
    return Card(
      color: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Chip(label: Text(route.type), backgroundColor: Colors.amber),
              const SizedBox(width: 8),
              Text(route.customer, style: const TextStyle(color: _kTextMain, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(fmt.format(route.departureTime!), style: const TextStyle(color: _kTextSub)),
            ]),
            const SizedBox(height: 4),
            Text(route.nameRoute, style: const TextStyle(color: _kTextMain, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Conductor: ${route.driverName ?? '-'}',
                style: const TextStyle(color: _kTextSub, fontSize: 13)),
            Text('Placa: ${route.vehiclePlate ?? '-'}',
                style: const TextStyle(color: _kTextSub, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}
