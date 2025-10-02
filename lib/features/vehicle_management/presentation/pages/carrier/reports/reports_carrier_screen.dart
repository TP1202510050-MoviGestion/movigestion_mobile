// lib/features/vehicle_management/presentation/pages/carrier/reports/reports_carrier_screen.dart

import 'package:flutter/material.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/reports/new_report_screen.dart';
import '../../../../../../core/widgets/app_drawer2.dart';
import 'package:intl/intl.dart'; // Necesario para formatear la fecha

class ReportsCarrierScreen extends StatefulWidget {
  final String name;
  final String lastName;

  const ReportsCarrierScreen({
    Key? key,
    required this.name,
    required this.lastName,
  }) : super(key: key);

  @override
  _ReportsCarrierScreenState createState() => _ReportsCarrierScreenState();
}

class _ReportsCarrierScreenState extends State<ReportsCarrierScreen> with SingleTickerProviderStateMixin {
  // PASO 1: Usar las mismas constantes de estilo que en ReportsScreen
  static const _primaryColor = Color(0xFFEA8E00);
  static const _backgroundColor = Color(0xFF1E1F24);
  static const _cardColor = Color(0xFF2C2F38);
  static const _textColor = Colors.white;
  static const _textMutedColor = Colors.white70;

  final ReportService _reportService = ReportService();
  List<ReportModel> _allReports = [];
  List<ReportModel> _filteredReports = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String? _filterType;
  String? _filterStatus;
  String  _sortOrder = 'Recientes';

  List<String> get _reportTypes => _allReports.map((r) => r.type).toSet().toList()..sort();
  final List<String> _statuses = ['Pendiente', 'En Proceso', 'Resuelto'];
  final List<String> _dateOptions = ['Recientes', 'Antiguos'];

  String get _fullNameLower => '${widget.name} ${widget.lastName}'.toLowerCase();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _fetchReports();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final all = await _reportService.getAllReports();
      _allReports = all.where((r) => r.driverName.toLowerCase() == _fullNameLower).toList();
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar reportes: $e')));
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
        _animationController.forward();
      }
    }
  }

  void _applyFilters() {
    var list = List<ReportModel>.from(_allReports);
    if (_filterType != null)   list = list.where((r) => r.type == _filterType).toList();
    if (_filterStatus != null) list = list.where((r) => r.status == _filterStatus).toList();
    list.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      return _sortOrder == 'Recientes' ? -cmp : cmp;
    });
    setState(() => _filteredReports = list);
  }

  Future<void> _navigateToNewReport() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewReportScreen(name: widget.name, lastName: widget.lastName)),
    );
    // Si se creó un nuevo reporte, refrescamos la lista
    if (result == true) {
      _fetchReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      drawer: AppDrawer2(name: widget.name, lastName: widget.lastName),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToNewReport,
        backgroundColor: _primaryColor,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Nuevo Reporte', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // PASO 2: Rediseñar la AppBar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _cardColor,
      title: const Row(
        children: [
          Icon(Icons.assessment_outlined, color: _primaryColor),
          SizedBox(width: 12),
          Text('Mis Reportes', style: TextStyle(color: _textColor)),
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
              'No has realizado ningún reporte',
              style: TextStyle(color: _textMutedColor, fontSize: 18),
            ),
            Text(
              'Usa el botón "+" para crear uno nuevo.',
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

  // PASO 3: Rediseñar la tarjeta de reporte
  Widget _buildReportCard(ReportModel report) {
    return Card(
      color: _cardColor,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Aquí puedes añadir navegación al detalle si lo creas en el futuro
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _primaryColor.withOpacity(0.15),
                child: Icon(_getIconForReportType(report.type), color: _primaryColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.type,
                      style: const TextStyle(color: _textColor, fontSize: 17, fontWeight: FontWeight.bold),
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
                        const Icon(Icons.calendar_today, size: 12, color: _textMutedColor),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('yyyy-MM-dd').format(report.createdAt.toLocal()),
                          style: const TextStyle(fontSize: 12, color: _textMutedColor),
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

  IconData _getIconForReportType(String type) {
    switch (type.toLowerCase()) {
      case 'accidente': return Icons.car_crash_outlined;
      case 'mantenimiento preventivo': return Icons.build_outlined;
      case 'falla mecánica': return Icons.settings_outlined;
      case 'problema de llantas': return Icons.tire_repair_outlined;
      default: return Icons.report_problem_outlined;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status) {
      case 'Pendiente': badgeColor = Colors.orange.shade700; break;
      case 'En Proceso': badgeColor = Colors.blue.shade700; break;
      case 'Resuelto': badgeColor = Colors.green.shade700; break;
      default: badgeColor = Colors.grey.shade700;
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
        style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // PASO 4: Refactorizar el modal y el constructor de filtros
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
                    width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  const Text('Filtrar y Ordenar', style: TextStyle(color: _textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildFilterSection('Tipo de Reporte', [null, ..._reportTypes], tempType, (value) => modalSetState(() => tempType = value)),
                        _buildFilterSection('Estado', [null, ..._statuses], tempStatus, (value) => modalSetState(() => tempStatus = value)),
                        _buildFilterSection('Ordenar por Fecha', _dateOptions, tempOrder, (value) => modalSetState(() => tempOrder = value!), isExclusive: true),
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
        Text(title, style: const TextStyle(color: _textMutedColor, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return ChoiceChip(
              label: Text(option ?? 'Todos'),
              selected: isSelected,
              onSelected: (_) => onSelected(isExclusive ? option : (isSelected ? null : option)),
              backgroundColor: _backgroundColor,
              selectedColor: _primaryColor,
              labelStyle: TextStyle(color: isSelected ? Colors.black : _textMutedColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: isSelected ? _primaryColor : Colors.white24),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}