import 'package:flutter/material.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/report_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/reports/reports_carrier_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/shipments/shipments_screen2.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/vehicle/vehicle_detail_carrier_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/profile/profile_screen2.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';

class NewReportScreen extends StatefulWidget {
  final String name;
  final String lastName;

  const NewReportScreen({
    Key? key,
    required this.name,
    required this.lastName,
  }) : super(key: key);

  @override
  _NewReportScreenState createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen> with SingleTickerProviderStateMixin {
  String? _selectedReportType;
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _reportTypes = ['Problemas con el vehiculo', 'Cliente no disponible', 'Direccion incorrecta', 'Accidente en autopista', 'Otro'];
  final ReportService reportService = ReportService();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Reporte',style: TextStyle(color: Colors.grey),
        ),
        backgroundColor: const Color(0xFF2C2F38),

        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1A1F24),
      body: FadeTransition(
        opacity: _animationController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              _buildReportForm(),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
      drawer: _buildDrawer(context),
    );
  }

  Widget _buildReportForm() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2F38),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalles del Reporte',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Tipo de Reporte',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1A1F24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                dropdownColor: const Color(0xFF1A1F24),
                value: _selectedReportType,
                items: _reportTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedReportType = newValue;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1A1F24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEA8E00),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 5,
      ),
      onPressed: _createReport,
      child: const Text(
        'Crear Nuevo Reporte',
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2C2F38),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/login_logo.png',
                  height: 80,
                ),
                const SizedBox(height: 10),
                Text(
                  '${widget.name} ${widget.lastName}',
                  style: const TextStyle(color: Colors.grey,  fontSize: 16),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.person, 'PERFIL', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen2(name: widget.name, lastName: widget.lastName),
              ),
            );
          }),
          _buildDrawerItem(Icons.report, 'REPORTES', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportsCarrierScreen(name: widget.name, lastName: widget.lastName),
              ),
            );
          }),
          _buildDrawerItem(Icons.directions_car, 'VEHÍCULOS', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VehicleDetailCarrierScreenScreen(name: widget.name, lastName: widget.lastName),
              ),
            );
          }),
          _buildDrawerItem(Icons.local_shipping, 'ENVIOS', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShipmentsScreen2(name: widget.name, lastName: widget.lastName),
              ),
            );
          }),
          const Divider(color: Colors.white54),
          _buildDrawerItem(Icons.logout, 'CERRAR SESIÓN', () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => LoginScreen(
                  onLoginClicked: (username, password) {
                    print('Usuario: $username, Contraseña: $password');
                  },
                  onRegisterClicked: () {
                    print('Registrarse');
                  },
                ),
              ),
                  (Route<dynamic> route) => false,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Future<void> _createReport() async {
    if (_selectedReportType != null && _descriptionController.text.isNotEmpty) {
      final newReport = ReportModel(
        userId: 1, // Ajusta según el usuario actual
        type: _selectedReportType!,
        description: _descriptionController.text,
        driverName: widget.name,
        createdAt: DateTime.now(),
      );

      final success = await reportService.createReport(newReport);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte creado exitosamente')),
        );
        Navigator.pop(context, newReport);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear el reporte')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
    }
  }
}
