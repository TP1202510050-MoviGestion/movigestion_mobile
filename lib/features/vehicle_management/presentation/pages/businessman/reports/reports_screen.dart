import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ----- IMPORTACIONES ORIGINALES (MANTENIDAS) -----
import 'package:movigestion_mobile/core/app_constants.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/carrier_profiles/carrier_profiles.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/profile/profile_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/reports/report_detail_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/shipments/shipments_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/vehicle/vehicles_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';

import '../../../../../../core/widgets/app_drawer.dart';

class ReportsScreen extends StatefulWidget {
  final String name;
  final String lastName;

  const ReportsScreen({
    super.key,
    required this.name,
    required this.lastName,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  // --- Colores y Estilos ---
  static const _primaryColor = Color(0xFFEA8E00);
  static const _backgroundColor = Color(0xFF1E1F24);
  static const _cardColor = Color(0xFF2C2F38);
  static const _textColor = Colors.white;
  static const _textMutedColor = Colors.white70;

  // --- Estado de la UI ---
  final ReportService _reportService = ReportService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;

  // --- Estado de Datos ---
  List<ReportModel> _allReports = [];
  List<ReportModel> _filteredReports = [];
  String _companyName = '';
  String _companyRuc = '';

  // --- Estado de Filtros ---
  String? _filterType;
  String? _filterStatus;
  String _sortOrder = 'Recientes';

  // Opciones para los filtros
  List<String> get _reportTypes =>
      _allReports.map((r) => r.type).toSet().toList()..sort();
  final List<String> _statuses = ['Pendiente', 'En Proceso', 'Resuelto'];
  final List<String> _dateOptions = ['Recientes', 'Antiguos'];

  // --- Ciclo de Vida ---
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _bootstrap();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- Lógica de Datos ---
  Future<void> _bootstrap() async {
    setState(() => _isLoading = true);
    await _fetchManagerData();
    await _fetchReports();
    if (mounted) {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }

  Future<void> _fetchManagerData() async {
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}'));
      if (res.statusCode == 200) {
        // 1. Tomamos los bytes crudos de la respuesta (sin decodificar).
        var responseBytes = res.bodyBytes;

        // 2. Decodificamos los bytes forzando el formato UTF-8.
        var decodedBody = utf8.decode(responseBytes);

        // 3. Ahora usamos el texto ya corregido con json.decode.
        final list = json.decode(decodedBody) as List;
        final gerente = list.firstWhere(
              (e) =>
          e['name'].toString().toLowerCase() == widget.name.toLowerCase() &&
              e['lastName'].toString().toLowerCase() ==
                  widget.lastName.toLowerCase(),
          orElse: () => null,
        );
        if (gerente != null) {
          _companyName = gerente['companyName'] ?? '';
          _companyRuc = gerente['companyRuc'] ?? '';
        }
      }
    } catch (_) {
      // Manejo de error silencioso como en el original
    }
  }

  Future<void> _fetchReports() async {
    try {
      final all = await _reportService.getAllReports();
      _allReports = all
          .where((r) =>
      r.companyName == _companyName && r.companyRuc == _companyRuc)
          .toList();
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar reportes: $e')),
      );
      setState(() => _filteredReports = []);
    }
  }

  void _applyFilters() {
    var list = List<ReportModel>.from(_allReports);
    if (_filterType != null) {
      list = list.where((r) => r.type == _filterType).toList();
    }
    if (_filterStatus != null) {
      list = list.where((r) => r.status == _filterStatus).toList();
    }
    list.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      return _sortOrder == 'Recientes' ? -cmp : cmp;
    });
    setState(() => _filteredReports = list);
  }

  // --- Constructores de UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      drawer: AppDrawer(
        name: widget.name,
        lastName: widget.lastName,
        companyName: _companyName, // Usamos la variable de estado de la pantalla
        companyRuc: _companyRuc,     // Usamos la variable de estado de la pantalla
      ),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _cardColor,
      title: const Row(
        children: [
          Icon(Icons.assessment_outlined, color: _primaryColor),
          SizedBox(width: 12),
          Text('Reportes', style: TextStyle(color: _textColor)),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Filtrar reportes',
          icon: const Icon(Icons.filter_list, color: _textColor),
          onPressed: _isLoading ? null : _showFilterModal,
        ),
      ],
      elevation: 0,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primaryColor));
    }
    if (_filteredReports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, color: _textMutedColor, size: 80),
            SizedBox(height: 16),
            Text(
              'No se encontraron reportes',
              style: TextStyle(color: _textMutedColor, fontSize: 18),
            ),
            Text(
              'Prueba a cambiar los filtros o vuelve más tarde.',
              style: TextStyle(color: _textMutedColor),
            ),
          ],
        ),
      );
    }
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredReports.length,
        itemBuilder: (ctx, i) => _buildReportCard(_filteredReports[i]),
      ),
    );
  }

  /// Construye la tarjeta visual para un reporte individual.
  Widget _buildReportCard(ReportModel report) {
    return Card(
      color: _cardColor,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final changed = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportDetailScreen(
                  name: widget.name, lastName: widget.lastName, report: report),
            ),
          );
          if (changed == true) {
            _fetchReports();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _primaryColor.withOpacity(0.15),
                child: Icon(_getIconForReportType(report.type),
                    color: _primaryColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.type,
                      style: const TextStyle(
                          color: _textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reportado por: ${report.driverName}',
                      style: const TextStyle(color: _textMutedColor, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 12, color: _textMutedColor),
                        const SizedBox(width: 6),
                        Text(
                          '${report.createdAt.toLocal()}'.split(' ')[0], // Solo la fecha
                          style:
                          const TextStyle(fontSize: 12, color: _textMutedColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(report.status),
            ],
          ),
        ),
      ),
    );
  }

  /// Devuelve un ícono basado en el tipo de reporte.
  IconData _getIconForReportType(String type) {
    switch (type.toLowerCase()) {
      case 'accidente':
        return Icons.car_crash_outlined;
      case 'mantenimiento preventivo':
        return Icons.build_outlined;
      case 'falla mecánica':
        return Icons.settings_outlined;
      case 'problema de llantas':
        return Icons.tire_repair_outlined;
      default:
        return Icons.report_problem_outlined;
    }
  }

  /// Construye una "insignia" de color para el estado del reporte.
  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status) {
      case 'Pendiente':
        badgeColor = Colors.orange.shade700;
        break;
      case 'En Proceso':
        badgeColor = Colors.blue.shade700;
        break;
      case 'Resuelto':
        badgeColor = Colors.green.shade700;
        break;
      default:
        badgeColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Muestra el modal de filtros.
  /// Usa StatefulBuilder para evitar reconstruir toda la pantalla al cambiar filtros.
  void _showFilterModal() {
    String? tempType = _filterType;
    String? tempStatus = _filterStatus;
    String tempOrder = _sortOrder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (BuildContext context, StateSetter modalSetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.8,
            builder: (_, scrollController) => Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const Text('Filtrar y Ordenar',
                      style: TextStyle(
                          color: _textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildFilterSection(
                          'Tipo de Reporte',
                          [null, ..._reportTypes],
                          tempType,
                              (value) => modalSetState(() => tempType = value),
                        ),
                        _buildFilterSection(
                          'Estado',
                          [null, ..._statuses],
                          tempStatus,
                              (value) => modalSetState(() => tempStatus = value),
                        ),
                        _buildFilterSection(
                          'Ordenar por Fecha',
                          _dateOptions,
                          tempOrder,
                              (value) => modalSetState(() => tempOrder = value!),
                          isExclusive: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _filterType = tempType;
                      _filterStatus = tempStatus;
                      _sortOrder = tempOrder;
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Aplicar Filtros',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String?> options,
      String? selectedValue, ValueChanged<String?> onSelected,
      {bool isExclusive = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: _textMutedColor, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return ChoiceChip(
              label: Text(option ?? 'Todos'),
              selected: isSelected,
              onSelected: (_) => onSelected(isExclusive ? option : (isSelected ? null : option)),
              backgroundColor: _backgroundColor,
              selectedColor: _primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : _textMutedColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                    color: isSelected ? _primaryColor : Colors.white24),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }


}