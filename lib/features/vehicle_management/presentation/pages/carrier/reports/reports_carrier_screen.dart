import 'package:flutter/material.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/reports/new_report_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/shipments/shipments_screen2.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/vehicle/vehicle_detail_carrier_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/profile/profile_screen2.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';

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
  List<ReportModel> _allReports = [];
  List<ReportModel> _filtered = [];
  bool _isLoading = true;
  late AnimationController _anim;
  late Animation<double> _fade;

  // Filtros reales
  String? _filterType;
  String? _filterStatus;
  String  _sortOrder = 'Recientes';

  // Opciones para el modal
  List<String> get _types   => _allReports.map((r) => r.type).toSet().toList()..sort();
  final List<String> _statuses = ['Pendiente', 'En Proceso', 'Resuelto'];
  final List<String> _dateOptions = ['Recientes', 'Antiguos'];

  String get _fullNameLower => '${widget.name} ${widget.lastName}'.toLowerCase();

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final svc = ReportService();
      final all = await svc.getAllReports();
      _allReports = all.where((r) => r.driverName.toLowerCase() == _fullNameLower).toList();
      _applyFilters();
    } catch (_) {
      // manejar error
    } finally {
      setState(() {
        _isLoading = false;
      });
      _anim.forward();
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
    setState(() => _filtered = list);
  }

  Future<void> _newReport() async {
    final rpt = await Navigator.push<ReportModel?>(
      context,
      MaterialPageRoute(builder: (_) => NewReportScreen(name: widget.name, lastName: widget.lastName)),
    );
    if (rpt != null && rpt.driverName.toLowerCase() == _fullNameLower) {
      _allReports.add(rpt);
      _applyFilters();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F38),
        title: Row(
          children: [
            const Icon(Icons.report, color: Colors.amber),
            const SizedBox(width: 10),
            Text(
              'Tus Reportes',
              style: TextStyle(color: Colors.grey, fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterModal,
          )
        ],
      ),
      backgroundColor: const Color(0xFF1A1F24),
      drawer: _buildDrawer(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 3))
          : FadeTransition(
        opacity: _fade,
        child: _filtered.isEmpty
            ? const Center(
          child: Text(
            'No realizaste ningún reporte.',
            style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filtered.length,
          itemBuilder: (ctx, i) => _buildCard(_filtered[i]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newReport,
        backgroundColor: const Color(0xFFFFA000),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _showFilterModal() {
    // variables temp dentro del modal
    String? tmpType    = _filterType;
    String? tmpStatus  = _filterStatus;
    String  tmpOrder   = _sortOrder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        builder: (c, scroll) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2C2F38),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ListView(
            controller: scroll,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Filtrar por...', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              // Tipo
              const Text('Tipo', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [null, ..._types].map((t) {
                  return ChoiceChip(
                    label: Text(t ?? 'Todos'),
                    selected: tmpType == t,
                    onSelected: (_) => setState(() => tmpType = t),
                    selectedColor: Colors.amber,
                    backgroundColor: Colors.white10,
                    labelStyle: TextStyle(color: tmpType == t ? Colors.black : Colors.grey),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Estado
              const Text('Estado', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [null, ..._statuses].map((s) {
                  return ChoiceChip(
                    label: Text(s ?? 'Todos'),
                    selected: tmpStatus == s,
                    onSelected: (_) => setState(() => tmpStatus = s),
                    selectedColor: Colors.amber,
                    backgroundColor: Colors.white10,
                    labelStyle: TextStyle(color: tmpStatus == s ? Colors.black : Colors.grey),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Fecha
              const Text('Ordenar por fecha', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _dateOptions.map((o) {
                  return ChoiceChip(
                    label: Text(o),
                    selected: tmpOrder == o,
                    onSelected: (_) => setState(() => tmpOrder = o),
                    selectedColor: Colors.amber,
                    backgroundColor: Colors.white10,
                    labelStyle: TextStyle(color: tmpOrder == o ? Colors.black : Colors.grey),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // aplicar seleccion
                  _filterType   = tmpType;
                  _filterStatus = tmpStatus;
                  _sortOrder    = tmpOrder;
                  _applyFilters();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Aplicar filtros', style: TextStyle(color: Colors.black, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(ReportModel r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.amber.shade700]),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.report, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(r.type, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(r.status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(r.description, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
            const SizedBox(width: 4),
            Text(
              '${r.createdAt.toLocal()}'.split('.')[0],
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ]),
        ]),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext ctx) => Drawer(
    backgroundColor: const Color(0xFF2C2F38),
    child: ListView(padding: EdgeInsets.zero, children: [
      DrawerHeader(
        child: Column(
          children: [
            Image.asset('assets/images/login_logo.png', height: 100),
            const SizedBox(height: 10),
            Text(
              '${widget.name} ${widget.lastName} - Transportista',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
      _drawerItem(Icons.person, 'PERFIL', () {
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => ProfileScreen2(name: widget.name, lastName: widget.lastName)));
      }),
      _drawerItem(Icons.report, 'REPORTES', () {
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => ReportsCarrierScreen(name: widget.name, lastName: widget.lastName)));
      }),
      _drawerItem(Icons.directions_car, 'VEHÍCULOS', () {
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => VehicleDetailCarrierScreenScreen(name: widget.name, lastName: widget.lastName)));
      }),
      _drawerItem(Icons.local_shipping, 'ENVIOS', () {
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => ShipmentsScreen2(name: widget.name, lastName: widget.lastName)));
      }),
      const SizedBox(height: 160),
      ListTile(
        leading: const Icon(Icons.logout, color: Colors.white),
        title: const Text('CERRAR SESIÓN', style: TextStyle(color: Colors.white)),
        onTap: () {
          Navigator.pushAndRemoveUntil(
            ctx,
            MaterialPageRoute(builder: (_) => LoginScreen(onLoginClicked: (_, __) {}, onRegisterClicked: () {})),
                (route) => false,
          );
        },
      ),
    ]),
  );

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: Colors.white),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    onTap: onTap,
  );
}
