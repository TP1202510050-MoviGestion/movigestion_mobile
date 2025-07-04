// lib/features/route_management/presentation/pages/businessman/route/routes_screen.dart
// -----------------------------------------------------------------------------
//                PANTALLA  ▸  LISTADO DE RUTAS  (versión rediseñada v2)
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/widgets/app_drawer.dart';
import '../../../../data/remote/route_model.dart';
import '../../../../data/remote/route_service.dart';
import '../../../../data/remote/profile_service.dart';
import 'assign_route_screen.dart';
import 'route_detail_screen.dart';

/* --- Estilos y Colores --- */
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
  // --- Lógica de negocio (sin cambios) ---


  static const _primaryColor = Color(0xFFEA8E00);
  static const _backgroundColor = Color(0xFF1E1F24);
  static const _cardColor = Color(0xFF2C2F38);
  static const _textColor = Colors.white;
  static const _textMutedColor = Colors.white70;


  final _svc = RouteService();
  final _profileSvc = ProfileService();
  final List<RouteModel> _routes = [];
  bool _loading = true;
  String _companyName = '';
  String _companyRuc = '';

  @override
  void initState() {
    super.initState();
    _loadCompanyAndRoutes();
  }

  Future<void> _loadCompanyAndRoutes() async {
    try {
      final prof = await _profileSvc.getProfileByNameAndLastName(
          widget.name, widget.lastName);
      _companyName = prof?.companyName ?? '';
      _companyRuc = prof?.companyRuc ?? '';
      await _fetchRoutes();
    } catch (_) {
      _showError('Error al cargar datos de la empresa');
    }
  }

  Future<void> _fetchRoutes() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final all = await _svc.getAllRoutes();
      _routes
        ..clear()
        ..addAll(all.where((r) =>
        r.companyName == _companyName && r.companyRuc == _companyRuc));
    } catch (_) {
      _showError('Error al cargar rutas');
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

  // ============================ BUILD ============================
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
            Text('Rutas', style: TextStyle(color: _textColor)),
          ],
        ),
      ),
      drawer: AppDrawer(name: widget.name, lastName: widget.lastName),
      body: RefreshIndicator(
        onRefresh: _fetchRoutes,
        color: _kAction,
        backgroundColor: _kBar,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kAction))
            : _buildContent(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addRoute',
        backgroundColor: _kAction,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Nueva Ruta', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AssignRouteScreen(name: widget.name, lastName: widget.lastName),
            ),
          );
          if (ok == true && mounted) {
            _fetchRoutes();
          }
        },
      ),
    );
  }

  /// MEJORA: Widget para el estado cuando no hay rutas
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
                  const Text('No hay rutas disponibles',
                      style: TextStyle(color: _kTextSub, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Crea una nueva ruta usando el botón "+"',
                      style: TextStyle(color: _kTextSub.withOpacity(0.6))),
                  const SizedBox(height: 100), // Espacio para que no lo tape el FAB
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// MEJORA: Widget para el contenido principal
  Widget _buildContent() {
    if (_routes.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _routes.length,
      itemBuilder: (_, i) => _RouteCard( // Se usa el nuevo _RouteCard rediseñado
        route: _routes[i],
        onTap: () async {
          // Lógica de navegación sin cambios
          await Navigator.push<RouteModel?>(
            context,
            MaterialPageRoute(
              builder: (_) => RouteDetailScreen(
                route: _routes[i],
                name: widget.name,
                lastName: widget.lastName,
              ),
            ),
          );
          // Al regresar, refrescamos los datos para ver cualquier cambio.
          _fetchRoutes();
        },
      ),
    );
  }
}

// ==============================================================================
//                    CARD DE RUTA (COMPONENTE REDISEÑADO v2)
// ==============================================================================
class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, required this.onTap});
  final RouteModel route;
  final VoidCallback onTap;

  /// MEJORA: Helper para obtener color e icono según el estado de la ruta.
  /// Esto hace que la UI sea mucho más informativa a simple vista.
  ({Color color, IconData icon}) _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'asignado':
        return (color: const Color(0xFF64B5F6), icon: Icons.assignment_turned_in_outlined); // Azul claro
      case 'en camino':
      case 'en_camino': // Por si acaso viene con guion bajo
        return (color: const Color(0xFF4FC3F7), icon: Icons.local_shipping_outlined); // Cyan
      case 'finalizado':
        return (color: const Color(0xFF81C784), icon: Icons.check_circle_outline); // Verde
      case 'cancelado':
        return (color: const Color(0xFFE57373), icon: Icons.cancel_outlined); // Rojo claro
      default:
        return (color: _kTextSub, icon: Icons.help_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusStyle = _getStatusStyle(route.status);
    final fmt = DateFormat.Hm();

    // MEJORA TIPOGRÁFICA: Definir estilos para consistencia
    final titleStyle = const TextStyle(
      color: _kTextMain,
      fontSize: 17, // Un poco más grande para mayor impacto
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );
    final subtitleStyle = TextStyle(
      color: _kTextSub.withOpacity(0.8), // Ligeramente más visible
      fontSize: 14,
    );
    final chipTextStyle = TextStyle(color: _kTextSub, fontSize: 13);

    // MEJORA: Reemplazar el guion largo por un icono para mejor estética
    final routeDescription = route.nameRoute
        .replaceAll('–', ' → ')  // Reemplaza el guion largo
        .replaceAll('-', ' → '); // Reemplaza el guion simple

    return Card(
      color: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      clipBehavior: Clip.antiAlias, // Para que el InkWell respete los bordes
      child: InkWell(
        onTap: onTap,
        splashColor: _kAction.withOpacity(0.1),
        highlightColor: _kAction.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- COLUMNA IZQUIERDA: Icono y Hora ---
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kAction.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.alt_route, color: _kAction, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    route.departureTime != null ? fmt.format(route.departureTime!) : '--:--',
                    style: const TextStyle(
                      color: _kTextSub,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // --- COLUMNA CENTRAL: Información de la Ruta ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(route.customer, style: titleStyle),
                    const SizedBox(height: 6),
                    Text(
                      routeDescription,
                      style: subtitleStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // MEJORA: Envolver los chips en un Wrap para que se ajusten si no hay espacio
                    Wrap(
                      spacing: 12.0, // Espacio horizontal entre chips
                      runSpacing: 8.0, // Espacio vertical si se van a una nueva línea
                      children: [
                        _InfoChip(
                          icon: Icons.person_outline,
                          text: route.driverName ?? 'No asignado',
                          style: chipTextStyle,
                        ),
                        _InfoChip(
                          icon: statusStyle.icon,
                          text: route.status.capitalize(), // Capitalizar la primera letra
                          color: statusStyle.color,
                          style: chipTextStyle.copyWith(color: statusStyle.color),
                        ),
                        // ---- CAMBIO SOLICITADO: Añadir el tipo de servicio ----
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

              // --- COLUMNA DERECHA: Flecha de acción ---
              const Icon(Icons.arrow_forward_ios, color: _kTextSub, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// MEJORA: Pequeño widget reutilizable para mostrar un ícono con texto
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
    this.color,
    this.style,
  });

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

// Helper para capitalizar strings (puedes moverlo a un archivo de utilidades)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}