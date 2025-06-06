import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/reports/reports_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/vehicle/vehicles_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/shipments/shipments_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/profile/profile_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';

class CarrierProfilesScreen extends StatefulWidget {
  final String name;
  final String lastName;

  const CarrierProfilesScreen({
    Key? key,
    required this.name,
    required this.lastName,
  }) : super(key: key);

  @override
  _CarrierProfilesScreenState createState() => _CarrierProfilesScreenState();
}

class _CarrierProfilesScreenState extends State<CarrierProfilesScreen> {
  List<Map<String, dynamic>> _carrierProfiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCarrierProfiles();
  }

  Future<void> _fetchCarrierProfiles() async {
    try {
      final response = await http.get(Uri.parse('https://app-241107014459.azurewebsites.net/api/profiles'));
      if (response.statusCode == 200) {
        List<dynamic> profiles = json.decode(response.body);
        setState(() {
          _carrierProfiles = profiles
              .where((profile) => profile['type'] == 'Transportista')
              .map((profile) => {
            'id': profile['id'],
            'name': profile['name'],
            'lastName': profile['lastName'],
            'email': profile['email'],
          })
              .toList();
          _isLoading = false;
        });
      } else {
        _showSnackbar('Error al cargar perfiles.');
      }
    } catch (e) {
      _showSnackbar('Error al obtener los perfiles.');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteProfile(int id) async {
    try {
      final response = await http.delete(Uri.parse('https://app-241107014459.azurewebsites.net/api/profiles/$id'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _carrierProfiles.removeWhere((profile) => profile['id'] == id);
        });
        _showSnackbar('Perfil eliminado correctamente');
      } else {
        _showSnackbar('Error al eliminar el perfil');
      }
    } catch (e) {
      _showSnackbar('Error al realizar la solicitud de eliminación');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F38),
        title: Row(
          children: [
            Icon(Icons.group, color: Colors.amber),
            const SizedBox(width: 10),
            Text(
              'Lista de Transportistas',
              style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF1E1F24),
      drawer: _buildDrawer(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA8E00)))
          : _carrierProfiles.isEmpty
          ? const Center(
        child: Text(
          'No se encontraron transportistas.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _carrierProfiles.length,
        itemBuilder: (context, index) {
          final profile = _carrierProfiles[index];
          return _buildProfileCard(profile['id'], profile['name'], profile['lastName'], profile['email']);
        },
      ),
    );
  }

  Widget _buildProfileCard(int id, String name, String lastName, String email) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading:             CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFEA8E00),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              'assets/images/driver.png',
              fit: BoxFit.cover,
              width: 40,
              height: 40,
            ),
          ),
        ),
        title: Text(
          '$name $lastName',
          style: const TextStyle( color: Colors.black, fontSize: 16),
        ),
        subtitle: Text(
          'Email: $email',
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => _showDeleteConfirmationDialog(id),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2F38),
          title: const Text(
            'Confirmar eliminación',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '¿Estás seguro de que deseas eliminar este perfil?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProfile(id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Drawer _buildDrawer(BuildContext context) {
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
                  '${widget.name} ${widget.lastName} - Gerente',
                  style: const TextStyle(color: Colors.grey,  fontSize: 16),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.person, 'PERFIL', ProfileScreen(name: widget.name, lastName: widget.lastName)),
          _buildDrawerItem(Icons.group, 'TRANSPORTISTAS', CarrierProfilesScreen(name: widget.name, lastName: widget.lastName)),
          _buildDrawerItem(Icons.report, 'REPORTES', ReportsScreen(name: widget.name, lastName: widget.lastName)),
          _buildDrawerItem(Icons.directions_car, 'VEHÍCULOS', VehiclesScreen(name: widget.name, lastName: widget.lastName)),
          _buildDrawerItem(Icons.local_shipping, 'ENVIOS', ShipmentsScreen(name: widget.name, lastName: widget.lastName)),
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
