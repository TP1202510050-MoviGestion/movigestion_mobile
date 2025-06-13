import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/reports/reports_carrier_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/vehicle/vehicle_detail_carrier_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/profile/profile_screen2.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';

import '../../../../../../core/widgets/app_drawer2.dart';

class ShipmentsScreen2 extends StatefulWidget {
  final String name;
  final String lastName;

  const ShipmentsScreen2({
    Key? key,
    required this.name,
    required this.lastName,
  }) : super(key: key);

  @override
  _ShipmentsScreen2State createState() => _ShipmentsScreen2State();
}

class _ShipmentsScreen2State extends State<ShipmentsScreen2> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _shipments = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchShipments();
  }

  Future<void> _fetchShipments() async {
    try {
      final profilesResponse = await http.get(Uri.parse('https://app-241107014459.azurewebsites.net/api/profiles'));

      if (profilesResponse.statusCode == 200) {
        List<dynamic> profiles = json.decode(profilesResponse.body);
        bool isDriverExists = profiles.any((profile) => profile['name'] == widget.name);

        if (isDriverExists) {
          final shipmentsResponse = await http.get(Uri.parse('https://app-241107014459.azurewebsites.net/api/shipments'));

          if (shipmentsResponse.statusCode == 200) {
            List<dynamic> data = json.decode(shipmentsResponse.body);
            setState(() {
              _shipments = data
                  .where((shipment) => shipment['driverName'] == widget.name)
                  .map((shipment) => {
                'id': shipment['id'],
                'destiny': shipment['destiny'],
                'description': shipment['description'],
                'createdAt': DateTime.parse(shipment['createdAt']),
              })
                  .toList();
              _isLoading = false;
            });


            _animationController.forward();
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsDelivered(int index) async {
    final shipment = _shipments[index];
    final id = shipment['id'];

    try {
      final response = await http.put(
        Uri.parse('https://app-241107014459.azurewebsites.net/api/shipments/$id/status'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': 'Envio Entregado'}),
      );

      if (response.statusCode == 204) {
        setState(() {
          _shipments[index]['status'] = 'Envio Entregado';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Confirmación entregada al gerente.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al marcar como entregado. Código: ${response.statusCode}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
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
            Icon(Icons.local_shipping, color: Colors.amber),
            const SizedBox(width: 10),
            Text(
              'Envios',
              style: TextStyle(color: Colors.grey, fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF1A1F24),
      drawer: AppDrawer2(name: widget.name, lastName: widget.lastName),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.amber,
          strokeWidth: 4,
        ),
      )
          : _shipments.isEmpty
          ? FadeTransition(
        opacity: _fadeAnimation,
        child: const Center(
          child: Text(
            'No hay envíos disponibles',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: _shipments.length,
            itemBuilder: (context, index) {
              return _buildShipmentCard(
                _shipments[index]['destiny'],
                _shipments[index]['description'],
                _shipments[index]['createdAt'],
                index,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildShipmentCard(String destiny, String description, DateTime createdAt, int index) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.only(bottom: 16.0),
      color: const Color(0xFFFFFFFF),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.amber.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child:
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFEA8E00),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        'assets/images/box.png',
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Destino: $destiny',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Descripción: $description',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Fecha: ${DateFormat.yMMMd().format(createdAt)}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _markAsDelivered(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Confirmar Entrega ',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
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
          _buildDrawerItem(Icons.directions_car, 'VEHICULOS', VehicleDetailCarrierScreen(name: widget.name, lastName: widget.lastName)),
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
