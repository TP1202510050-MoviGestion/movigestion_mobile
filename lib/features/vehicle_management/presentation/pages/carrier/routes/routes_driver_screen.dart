// lib/features/route_management/presentation/pages/driver/routes_driver_screen.dart
/* -------------------------------------------------------------- */
/*                  PANTALLA ▸ MIS RUTAS (Conductor)              */
/* -------------------------------------------------------------- */
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Importaciones necesarias
import '../../../../../../core/widgets/app_drawer.dart';
import '../../../../../../core/widgets/app_drawer2.dart';
import '../../../../data/remote/route_model.dart';
import '../../../../data/remote/route_service.dart';
import 'route_driver_detail_screen.dart'; // La nueva pantalla de detalle

/* --- Estilos y Colores (los mismos de siempre) --- */
const _kBg = Color(0xFF1C1E24);
const _kCard = Color(0xFF2F353F);
const _kBar = Color(0xFF2C2F38);
const _kAction = Color(0xFFFFA000);
const _kTextMain = Colors.white;
const _kTextSub = Colors.white70;

class RoutesDriverScreen extends StatefulWidget {
  final String name;
  final String lastName;
  const RoutesDriverScreen({super.key, required this.name, required this.lastName});

  @override
  State<RoutesDriverScreen> createState() => _RoutesDriverScreenState();
}

class _RoutesDriverScreenState extends State<RoutesDriverScreen> {

  static const _primaryColor = Color(0xFFEA8E00);
  static const _backgroundColor = Color(0xFF1E1F24);
  static const _cardColor = Color(0xFF2C2F38);
  static const _textColor = Colors.white;
  static const _textMutedColor = Colors.white70;

  final _svc = RouteService();
  final List<RouteModel> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyRoutes();
  }

  Future<void> _fetchMyRoutes() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final driverFullName = '${widget.name} ${widget.lastName}';

    try {
      final all = await _svc.getAllRoutes();
      if (!mounted) return;

      setState(() {
        _routes
          ..clear()
          ..addAll(all.where((r) => r.driverName == driverFullName));
        // Ordenar: primero las asignadas, luego en camino, y al final las demás
        _routes.sort((a, b) {
          int statusValue(String status) {
            switch (status.toLowerCase()) {
              case 'asignado': return 1;
              case 'en camino':
              case 'en_camino': return 2;
              default: return 3;
            }
          }
          return statusValue(a.status).compareTo(statusValue(b.status));
        });
      });

    } catch (_) {
      _showError('Error al cargar tus rutas asignadas');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _cardColor,
        title: const Row(
          children: [
            Icon(Icons.route, color:_primaryColor ,),
            SizedBox(width: 12),
            Text('Mis Rutas', style: TextStyle(color: _textColor)),
          ],
        ),
      ),
      drawer: AppDrawer2(name: widget.name, lastName: widget.lastName),
      body: RefreshIndicator(
        onRefresh: _fetchMyRoutes,
        color: _kAction,
        backgroundColor: _kBar,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kAction))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_routes.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _routes.length,
      itemBuilder: (_, i) => _RouteCard( // Reutilizamos el mismo widget _RouteCard
        route: _routes[i],
        onTap: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => RouteDriverDetailScreen(
                route: _routes[i],
                name: widget.name,
                lastName: widget.lastName,
              ),
            ),
          );
          // Al regresar, siempre refrescamos la lista para ver cambios de estado
          _fetchMyRoutes();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 80, color: _kTextSub.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No tienes rutas asignadas',
                      style: TextStyle(color: _kTextSub, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Espera a que un administrador te asigne una.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _kTextSub.withOpacity(0.6))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, required this.onTap});
  final RouteModel route;
  final VoidCallback onTap;

  ({Color color, IconData icon}) _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'asignado':
        return (color: const Color(0xFF64B5F6), icon: Icons.assignment_turned_in_outlined);
      case 'en camino':
      case 'en_camino':
        return (color: const Color(0xFF4FC3F7), icon: Icons.local_shipping_outlined);
      case 'finalizado':
        return (color: const Color(0xFF81C784), icon: Icons.check_circle_outline);
      case 'cancelado':
        return (color: const Color(0xFFE57373), icon: Icons.cancel_outlined);
      default:
        return (color: _kTextSub, icon: Icons.help_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusStyle = _getStatusStyle(route.status);
    final dateFmt = DateFormat('dd/MM/yy');
    final timeFmt = DateFormat.Hm();
    final titleStyle = const TextStyle(color: _kTextMain, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5);
    final subtitleStyle = TextStyle(color: _kTextSub.withOpacity(0.8), fontSize: 14);
    final chipTextStyle = TextStyle(color: _kTextSub, fontSize: 13);
    final routeDescription = route.nameRoute.replaceAll('–', ' → ').replaceAll('-', ' → ');

    return Card(
      color: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: _kAction.withOpacity(0.1),
        highlightColor: _kAction.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _kAction.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.alt_route, color: _kAction, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    route.departureTime != null ? dateFmt.format(route.departureTime!) : 'Sin fecha',
                    style: TextStyle(color: _kTextSub.withOpacity(0.7), fontSize: 12),
                  ),
                  const SizedBox(height: 4),

                  // 3. Mantenemos el widget de la hora
                  Text(
                    route.departureTime != null ? timeFmt.format(route.departureTime!) : '--:--',
                    style: const TextStyle(color: _kTextSub, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(route.customer, style: titleStyle),
                    const SizedBox(height: 6),
                    Text(routeDescription, style: subtitleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 8.0,
                      children: [
                        _InfoChip(
                          icon: Icons.person_outline,
                          text: route.driverName ?? 'No asignado',
                          style: chipTextStyle,
                        ),
                        _InfoChip(
                          icon: statusStyle.icon,
                          text: route.status.capitalize(),
                          color: statusStyle.color,
                          style: chipTextStyle.copyWith(color: statusStyle.color),
                        ),
                        _InfoChip(
                          icon: Icons.miscellaneous_services_outlined,
                          text: route.type.capitalize(),
                          style: chipTextStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: _kTextSub, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({ required this.icon, required this.text, this.color, this.style });
  final IconData icon;
  final String text;
  final Color? color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _kTextSub;
    final effectiveStyle = style ?? TextStyle(color: effectiveColor, fontSize: 13);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: effectiveColor, size: 16),
        const SizedBox(width: 6),
        Text(text, style: effectiveStyle),
      ],
    );
  }
}

// ==============================================================================
//           EXTENSIÓN DE STRING PARA CAPITALIZAR (SOLO PARA ESTE ARCHIVO)
// ==============================================================================
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}