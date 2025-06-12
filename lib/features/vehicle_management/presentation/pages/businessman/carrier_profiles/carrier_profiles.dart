import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';

import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/reports/reports_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/vehicle/vehicles_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/shipments/shipments_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/profile/profile_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';

class CarrierProfilesScreen extends StatefulWidget {
  final String name, lastName;        // datos del gerente
  const CarrierProfilesScreen({super.key, required this.name, required this.lastName});

  @override
  State<CarrierProfilesScreen> createState() => _CarrierProfilesScreenState();
}

class _CarrierProfilesScreenState extends State<CarrierProfilesScreen> {
  final _base = '${AppConstants.baseUrl}${AppConstants.profile}';
  bool _loading = true;
  List<Map<String, dynamic>> _carriers = [];

  String _companyName = '';
  String _companyRuc  = '';

  // ---------- INIT ----------
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_fetchManagerData(), _fetchCarriers()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchManagerData() async {
    try {
      final res = await http.get(Uri.parse(_base));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        final gerente = list.firstWhere(
              (e) => e['name'].toString().toLowerCase()     == widget.name.toLowerCase() &&
              e['lastName'].toString().toLowerCase() == widget.lastName.toLowerCase(),
          orElse: () => null,
        );
        if (gerente != null) {
          _companyName = gerente['companyName'] ?? '';
          _companyRuc  = gerente['companyRuc']  ?? '';
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchCarriers() async {
    try {
      final res = await http.get(Uri.parse(_base));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        _carriers = list
            .where((e) => e['type'] == 'Transportista')
            .map((e) => {
          'id'      : e['id'],
          'name'    : e['name'],
          'lastName': e['lastName'],
          'email'   : e['email'],
          'phone'   : e['phone'] ?? '',
        'profilePhoto' : e['profilePhoto'] ?? ''
        })
            .toList();
      }
    } catch (_) {
      _show('Error al cargar perfiles');
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F24),
      appBar: _appBar(),
      drawer : _buildDrawer(context),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addCarrier',
        backgroundColor: const Color(0xFFEA8E00),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: _showAddCarrierDialog,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA8E00)))
          : _carriers.isEmpty
          ? const Center(child: Text('No se encontraron transportistas',
          style: TextStyle(color: Colors.white70)))
          : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _carriers.length,
          itemBuilder: (_, i) {
            final p = _carriers[i];
            return _card(p['id'], p['name'], p['lastName'], p['email'], p['phone'], p['profilePhoto'],);
          }),
    );
  }

  AppBar _appBar() => AppBar(
    backgroundColor: const Color(0xFF2C2F38),
    title: const Row(
      children: [Icon(Icons.group, color: Colors.amber), SizedBox(width: 10), Text('Lista de Transportistas')],
    ),
  );

  Widget _card(int id, String name, String lastName, String mail, String phone, String photoB64) {
    ImageProvider avatar;
    if (photoB64.isNotEmpty) {
      avatar = MemoryImage(base64Decode(photoB64));
    } else {
      avatar = const AssetImage('assets/images/driver.png');
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: avatar,
          radius: 24,
          backgroundColor: Colors.grey[200],
        ),
        title   : Text('$name $lastName'),
        subtitle: Text('📧 $mail\n📱 $phone'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => _confirmDelete(id),
        ),
      ),
    );
  }

  Future<void> _showAddCarrierDialog() async {
    final nameC = TextEditingController();
    final lastC = TextEditingController();
    final emailC= TextEditingController();
    final phoneC= TextEditingController();
    final passC = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2F38),
        title: const Text('Nuevo Transportista', style: TextStyle(color: Colors.amber)),
        content: SingleChildScrollView(
          child: Column(children: [
            _dlgField('Nombre',     nameC),
            _dlgField('Apellido',   lastC),
            _dlgField('Email',      emailC, kb: TextInputType.emailAddress),
            _dlgField('Teléfono',   phoneC, kb: TextInputType.phone),
            _dlgField('Contraseña', passC,  obs: true),
          ]),
        ),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA8E00)),
            child: const Text('Registrar', style: TextStyle(color: Colors.black)),
            onPressed: () async {
              if ([nameC,lastC,emailC,phoneC,passC].any((c)=>c.text.isEmpty)) {
                _show('Completa todos los campos'); return;
              }

              final body = {
                "name"        : nameC.text,
                "lastName"    : lastC.text,
                "email"       : emailC.text,
                "password"    : passC.text,
                "phone"       : phoneC.text,
                "companyName" : _companyName,
                "companyRuc"  : _companyRuc,
                "type"        : "Transportista",
                "profilePhoto": ""
              };

              final res = await http.post(Uri.parse(_base),
                  headers: {'Content-Type':'application/json'}, body: jsonEncode(body));

              if (res.statusCode == 201 || res.statusCode == 200) {
                Navigator.pop(context);
                _show('Transportista registrado');
                setState(() => _loading = true);
                await _fetchCarriers();
                setState(() => _loading = false);
              } else {
                _show('Error al registrar (${res.statusCode})');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _dlgField(String label, TextEditingController c,
      {TextInputType? kb, bool obs=false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c, obscureText: obs, keyboardType: kb,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label, labelStyle: const TextStyle(color: Colors.white70),
            filled: true, fillColor: const Color(0xFF3A414B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  // ---------- DELETE ----------
  void _confirmDelete(int id) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF2C2F38),
      title: const Text('Eliminar perfil', style: TextStyle(color: Colors.amber)),
      content: const Text('¿Seguro que deseas eliminar el transportista?',
          style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Eliminar'),
          onPressed: () async {
            final res =
            await http.delete(Uri.parse('$_base/$id'));
            Navigator.pop(context);
            if (res.statusCode == 200 || res.statusCode == 204) {
              _show('Eliminado');
              setState(() => _carriers.removeWhere((p) => p['id'] == id));
            } else {
              _show('Error al eliminar');
            }
          },
        ),
      ],
    ),
  );

  // ---------- helpers ----------
  void _show(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  /* Drawer sin cambios significativos */
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
