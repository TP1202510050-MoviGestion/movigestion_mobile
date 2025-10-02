// lib/features/route_management/presentation/pages/businessman/route/routes_screen.dart

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
  final _svc = RouteService();
  final _profileSvc = ProfileService();
  bool _loading = true;
  String _companyName = '';
  String _companyRuc = '';

  List<RouteModel> _allRoutes = [];
  List<RouteModel> _filteredRoutes = [];

  String? _filterStatus;
  String? _filterType;
  String _sortOrder = 'Recientes';

  final List<String> _statuses = ['Asignado', 'En_camino', 'Finalizado', 'Cancelado'];
  final List<String> _types = ['Regular', 'Reten', 'Express', 'Evento', 'Mantenimiento'];
  final List<String> _dateOptions = ['Recientes', 'Antiguos'];

  @override
  void initState() {
    super.initState();
    _loadCompanyAndRoutes();
  }

  Future<void> _loadCompanyAndRoutes() async {
    try {
      final prof = await _profileSvc.getProfileByNameAndLastName(widget.name, widget.lastName);
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
      _allRoutes = all.where((r) => r.companyName == _companyName && r.companyRuc == _companyRuc).toList();
      _applyFilters();
    } catch (_) {
      _showError('Error al cargar rutas');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // PASO 1: Crear la función para eliminar la ruta
  Future<void> _deleteRoute(RouteModel route) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar Eliminación', style: TextStyle(color: _kTextMain)),
        content: const Text('¿Estás seguro de que quieres eliminar esta ruta?', style: TextStyle(color: _kTextSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: _kTextSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar', style: TextStyle(color: _kTextMain)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (route.id == null) {
          _showError('Error: La ruta no tiene un ID válido para eliminar.');
          return;
        }
        final success = await _svc.deleteRoute(route.id!);
        if (success) {
          // Si tiene éxito, eliminamos la ruta de nuestras listas locales y actualizamos la UI
          setState(() {
            _allRoutes.removeWhere((r) => r.id == route.id);
            _filteredRoutes.removeWhere((r) => r.id == route.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ruta eliminada correctamente'), backgroundColor: Colors.green),
          );
        } else {
          _showError('No se pudo eliminar la ruta. El servidor respondió negativamente.');
        }
      } catch (e) {
        _showError('Ocurrió un error al eliminar la ruta: $e');
      }
    }
  }

  void _applyFilters() {
    var list = List<RouteModel>.from(_allRoutes);
    if (_filterStatus != null) {
      list = list.where((r) => r.status.toLowerCase() == _filterStatus!.toLowerCase()).toList();
    }
    if (_filterType != null) {
      list = list.where((r) => r.type.toLowerCase() == _filterType!.toLowerCase()).toList();
    }
    list.sort((a, b) {
      final dateA = a.createdAt ?? DateTime(1970);
      final dateB = b.createdAt ?? DateTime(1970);
      final cmp = dateA.compareTo(dateB);
      return _sortOrder == 'Recientes' ? -cmp : cmp;
    });
    setState(() => _filteredRoutes = list);
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
        backgroundColor: _kBar,
        title: const Row(
          children: [
            Icon(Icons.route, color: _kAction),
            SizedBox(width: 12),
            Text('Rutas', style: TextStyle(color: _kTextMain)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Filtrar rutas',
            icon: const Icon(Icons.filter_list, color: _kTextMain),
            onPressed: _loading ? null : _showFilterModal,
          ),
        ],
      ),
      drawer: AppDrawer(
        name: widget.name,
        lastName: widget.lastName,
        companyName: _companyName, // Usamos la variable de estado de la pantalla
        companyRuc: _companyRuc,     // Usamos la variable de estado de la pantalla
      ),
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
          final ok = await Navigator.push<bool>(context, MaterialPageRoute(
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

  Widget _buildEmptyState() {
    final hasRoutes = _allRoutes.isNotEmpty;
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(hasRoutes ? Icons.filter_alt_off_outlined : Icons.map_outlined, size: 80, color: _kTextSub.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(hasRoutes ? 'No hay rutas con estos filtros' : 'No hay rutas disponibles', style: const TextStyle(color: _kTextSub, fontSize: 18)),
                const SizedBox(height: 8),
                Text(hasRoutes ? 'Prueba a cambiar los filtros' : 'Crea una nueva ruta usando el botón "+"', style: TextStyle(color: _kTextSub.withOpacity(0.6))),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      );
    },
    );
  }

  Widget _buildContent() {
    if (_filteredRoutes.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _filteredRoutes.length,
      itemBuilder: (_, i) => _RouteCard(
        route: _filteredRoutes[i],
        onTap: () async {
          final updatedRoute = await Navigator.push<RouteModel?>(context, MaterialPageRoute(
            builder: (_) => RouteDetailScreen(
              route: _filteredRoutes[i],
              name: widget.name,
              lastName: widget.lastName,
            ),
          ),
          );
          // Si regresamos con una ruta actualizada, refrescamos la lista
          if (updatedRoute != null) {
            _fetchRoutes();
          }
        },
        // PASO 2: Pasar la función de eliminar a la tarjeta
        onDelete: () => _deleteRoute(_filteredRoutes[i]),
      ),
    );
  }

  void _showFilterModal() {
    String? tempStatus = _filterStatus;
    String? tempType = _filterType;
    String tempOrder = _sortOrder;

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => StatefulBuilder(
      builder: (BuildContext context, StateSetter modalSetState) {
        return DraggableScrollableSheet(initialChildSize: 0.6, maxChildSize: 0.8, builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: _kCard, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const Text('Filtrar y Ordenar', style: TextStyle(color: _kTextMain, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildFilterSection('Estado', [null, ..._statuses], tempStatus, (value) => modalSetState(() => tempStatus = value)),
                    _buildFilterSection('Tipo de Servicio', [null, ..._types], tempType, (value) => modalSetState(() => tempType = value)),
                    _buildFilterSection('Ordenar por Fecha', _dateOptions, tempOrder, (value) => modalSetState(() => tempOrder = value!), isExclusive: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _filterStatus = tempStatus;
                  _filterType = tempType;
                  _sortOrder = tempOrder;
                  _applyFilters();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAction,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Aplicar Filtros', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        );
      },
    ),
    );
  }

  Widget _buildFilterSection(String title, List<String?> options, String? selectedValue, ValueChanged<String?> onSelected, {bool isExclusive = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: _kTextSub, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue?.toLowerCase() == option?.toLowerCase();
            return ChoiceChip(
              label: Text((option ?? 'Todos').capitalize()),
              selected: isSelected,
              onSelected: (_) => onSelected(isExclusive ? option : (isSelected ? null : option)),
              backgroundColor: _kBg,
              selectedColor: _kAction,
              labelStyle: TextStyle(color: isSelected ? Colors.black : _kTextSub, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: isSelected ? _kAction : Colors.white24),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ==============================================================================
//                    CARD DE RUTA (MODIFICADA CON BOTÓN DE ELIMINAR)
// ==============================================================================
class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.onTap,
    required this.onDelete, // PASO 3: Añadir el nuevo parámetro
  });
  final RouteModel route;
  final VoidCallback onTap;
  final VoidCallback onDelete; // PASO 3 (cont.)

  ({Color color, IconData icon}) _getStatusStyle(String status) {
    switch (status.toLowerCase().replaceAll('_', '')) {
      case 'asignado': return (color: const Color(0xFF64B5F6), icon: Icons.assignment_turned_in_outlined);
      case 'encamino': return (color: const Color(0xFF4FC3F7), icon: Icons.local_shipping_outlined);
      case 'finalizado': return (color: const Color(0xFF81C784), icon: Icons.check_circle_outline);
      case 'cancelado': return (color: const Color(0xFFE57373), icon: Icons.cancel_outlined);
      default: return (color: _kTextSub, icon: Icons.help_outline);
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
          padding: const EdgeInsets.fromLTRB(16, 18, 8, 18), // Ajustamos el padding derecho
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
                  Text(route.departureTime != null ? dateFmt.format(route.departureTime!) : 'Sin fecha', style: TextStyle(color: _kTextSub.withOpacity(0.7), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(route.departureTime != null ? timeFmt.format(route.departureTime!) : '--:--', style: const TextStyle(color: _kTextSub, fontSize: 15, fontWeight: FontWeight.w500)),
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
                        _InfoChip(icon: Icons.person_outline, text: route.driverName ?? 'No asignado', style: chipTextStyle),
                        _InfoChip(icon: statusStyle.icon, text: route.status.replaceAll('_', ' ').capitalize(), color: statusStyle.color, style: chipTextStyle.copyWith(color: statusStyle.color)),
                        _InfoChip(icon: Icons.miscellaneous_services_outlined, text: route.type.capitalize(), style: chipTextStyle),
                      ],
                    ),
                  ],
                ),
              ),
              // PASO 4: Añadir la columna con la flecha y el botón de eliminar
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.arrow_forward_ios, color: _kTextSub, size: 18),
                  const SizedBox(height: 20), // Espacio para separar
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: onDelete,
                    tooltip: 'Eliminar ruta',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(), // Para quitar padding extra
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget reutilizable para mostrar un ícono con texto
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

// Helper para capitalizar strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    final parts = split('_');
    final capitalizedParts = parts.map((part) {
      if (part.isEmpty) return '';
      return "${part[0].toUpperCase()}${part.substring(1).toLowerCase()}";
    });
    return capitalizedParts.join(' ');
  }
}