import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/profile/profile_screen2.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/reports/reports_carrier_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/shipments/shipments_screen2.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';


class VehicleDetailCarrierScreenScreen extends StatefulWidget {
  final String name;
  final String lastName;

  const VehicleDetailCarrierScreenScreen({
    Key? key,
    required this.name,
    required this.lastName,
  }) : super(key: key);

  @override
  _VehicleDetailCarrierScreenScreenState createState() => _VehicleDetailCarrierScreenScreenState();
}

class _VehicleDetailCarrierScreenScreenState extends State<VehicleDetailCarrierScreenScreen> with SingleTickerProviderStateMixin {
  VehicleModel? vehicle;
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchVehicleByDriverName(widget.name);
  }

  Future<void> _fetchVehicleByDriverName(String driverName) async {
    final url = Uri.parse('https://app-241107014459.azurewebsites.net/api/vehicles');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        VehicleModel? foundVehicle = data
            .map((json) => VehicleModel.fromJson(json))
            .cast<VehicleModel?>()
            .firstWhere(
              (vehicle) => vehicle?.driverName == driverName,
          orElse: () => null,
        );

        if (foundVehicle != null) {
          setState(() {
            vehicle = foundVehicle;
            isLoading = false;
          });
          _animationController.forward();
        } else {
          setState(() {
            vehicle = null;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
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
        backgroundColor: const Color(0xFF2C2F38),
        title: Row(
          children: [
            Icon(Icons.directions_car, color: Colors.amber),
            const SizedBox(width: 10),
            Text(
              'Vehiculo Asignado',
              style: TextStyle(color: Colors.grey, fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),

      backgroundColor: const Color(0xFF1A1F24),
      drawer: _buildDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : vehicle != null
          ? FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionContainer(_buildVehicleImage(vehicle!.vehicleImage)),
              const SizedBox(height: 20),
              _buildSectionContainer(_buildInfoRow('Placa', vehicle!.licensePlate)),
              _buildSectionContainer(_buildInfoRow('Modelo', vehicle!.model)),
              _buildSectionContainer(_buildInfoRow('Motor (%)', '${vehicle!.engine}%', isPercentage: true)),
              _buildSectionContainer(_buildInfoRow('Combustible (%)', '${vehicle!.fuel}%', isPercentage: true)),
              _buildSectionContainer(_buildInfoRow('Neumáticos (%)', '${vehicle!.tires}%', isPercentage: true)),
              _buildSectionContainer(_buildInfoRow('Sistema Eléctrico (%)', '${vehicle!.electricalSystem}%', isPercentage: true)),
              _buildSectionContainer(_buildInfoRow('Temperatura de Transmisión (%)', '${vehicle!.transmissionTemperature}%', isPercentage: true)),

              _buildSectionContainer(_buildInfoRow('Conductor', vehicle!.driverName)),
              _buildSectionContainer(_buildInfoRow('Color', vehicle!.color)),
              _buildSectionContainer(
                _buildInfoRow('Fecha de Última Inspección', DateFormat('yyyy-MM-dd').format(vehicle!.lastTechnicalInspectionDate)),
              ),
            ],
          ),
        ),
      )
          :  const Center(
        child: Text(
          'No te asignaron un vehiculo',
          style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      )
    );
  }

  Widget _buildSectionContainer(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2F353F),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPercentage = false}) {
    String getConditionText(double percentage) {
      if (percentage > 75) {
        return "En excelente estado";
      } else if (percentage > 60) {
        return "En buen estado";
      } else if (percentage > 35) {
        return "Presenta algunas fallas";
      } else {
        return "En mal estado";
      }
    }

    Color getConditionColor(double percentage) {
      if (percentage > 75) {
        return Colors.green;
      } else if (percentage > 60) {
        return Colors.amber;
      } else if (percentage > 35) {
        return Colors.orange;
      } else {
        return Colors.red;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.amber, fontSize: 16),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
              if (isPercentage)
                Text(
                  getConditionText(double.tryParse(value.replaceAll('%', '')) ?? 0),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: getConditionColor(double.tryParse(value.replaceAll('%', '')) ?? 0),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildVehicleImage(String imageUrl) {
    return imageUrl.isNotEmpty
        ? ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildNoImagePlaceholder();
        },
      ),
    )
        : _buildNoImagePlaceholder();
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF3A414B),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Center(
        child: Text(
          'No hay imagen disponible',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF2C2F38),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(

            child: Column(
              children: [
                Image.asset(
                  'assets/images/login_logo.png',
                  height: 100,
                ),
                const SizedBox(height: 10),
                Text(
                  '${widget.name} ${widget.lastName} - Transportista',
                  style: const TextStyle(color: Colors.grey,  fontSize: 16),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.person, 'PERFIL', ProfileScreen2(name: widget.name, lastName: widget.lastName)),
          _buildDrawerItem(Icons.report, 'REPORTES', ReportsCarrierScreen(name: widget.name, lastName: widget.lastName)),
          _buildDrawerItem(Icons.directions_car, 'VEHICULOS', VehicleDetailCarrierScreenScreen(name: widget.name, lastName: widget.lastName)),
          _buildDrawerItem(Icons.local_shipping, 'ENVIOS', ShipmentsScreen2(name: widget.name, lastName: widget.lastName)),
          const SizedBox(height: 160),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('CERRAR SESIÓN', style: TextStyle(color: Colors.white)),
            onTap: () {
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
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}
