import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_model.dart'; // ← nuevo
import 'package:movigestion_mobile/core/app_constants.dart';

import '../reports/reports_screen.dart';
import '../vehicle/vehicles_screen.dart';
import '../shipments/shipments_screen.dart';
import '../carrier_profiles/carrier_profiles.dart';
import '../../login_register/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String name, lastName;
  const ProfileScreen({super.key, required this.name, required this.lastName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // controllers
  final nameC        = TextEditingController();
  final lastNameC    = TextEditingController();
  final emailC       = TextEditingController();
  final phoneC       = TextEditingController();
  final companyC     = TextEditingController();
  final rucC         = TextEditingController();
  final passC        = TextEditingController();
  final confirmPassC = TextEditingController();

  final _service     = ProfileService();
  bool _loading = true, _edit = false;
  String userType = '';
  int?    _id;
  String? _photoB64;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await http.get(Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        final p = list.firstWhere(
              (e) =>
          e['name'].toString().toLowerCase()   == widget.name.toLowerCase() &&
              e['lastName'].toString().toLowerCase() == widget.lastName.toLowerCase(),
          orElse: () => null,
        );
        if (p != null) {
          _id           = p['id'] as int;
          nameC.text    = p['name'];
          lastNameC.text= p['lastName'];
          emailC.text   = p['email'];
          phoneC.text   = p['phone']       ?? '';
          companyC.text = p['companyName'] ?? '';
          rucC.text     = p['companyRuc']  ?? '';
          _photoB64     = p['profilePhoto'];
          userType      = p['type'];
        }
      }
    } catch (_) {
      _show('Error al obtener datos');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F24),
      appBar: _appBar(),
      drawer: _buildDrawer(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA8E00)))
          : _body(),
    );
  }

  AppBar _appBar() => AppBar(
    backgroundColor: const Color(0xFF2C2F38),
    title: const Row(
      children: [
        Icon(Icons.person, color: Colors.amber), SizedBox(width: 10),
        Text('Perfil')
      ],
    ),
  );

  Widget _body() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        GestureDetector(
          onTap: _edit ? _pickPhoto : null,
          child: CircleAvatar(
            radius: 60,
            backgroundImage: _photoB64 != null && _photoB64!.isNotEmpty
                ? MemoryImage(base64Decode(_photoB64!))
                : const AssetImage('assets/images/Gerente.png')
            as ImageProvider,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Bienvenido, ${widget.name} ${widget.lastName}',
          style: const TextStyle(color: Colors.white, fontSize: 22),
        ),
        if (companyC.text.isNotEmpty || rucC.text.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Empresa: ${companyC.text}  •  RUC: ${rucC.text}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        _field('Nombre',     nameC,     _edit),
        _field('Apellido',   lastNameC, _edit),
        _field('Email',      emailC,    _edit, kb: TextInputType.emailAddress),
        _field('Teléfono',   phoneC,    _edit, kb: TextInputType.phone),
        _field('Empresa',    companyC,  _edit),
        _field('RUC Empresa',rucC,      _edit, kb: TextInputType.number),
        if (_edit) ...[
          _field('Nueva contraseña',           passC,        true, obs: true),
          _field('Confirmar contraseña',       confirmPassC, true, obs: true),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _edit ? _save : () => setState(() => _edit = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEA8E00),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(
            _edit ? 'CONFIRMAR ACTUALIZACIÓN' : 'EDITAR DATOS',
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    ),
  );

  Widget _field(String label, TextEditingController c, bool enabled,
      {TextInputType? kb, bool obs = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            enabled: enabled,
            obscureText: obs,
            keyboardType: kb,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (res != null && res.files.single.bytes != null) {
      setState(() => _photoB64 = base64Encode(res.files.single.bytes!));
    }
  }

  Future<void> _save() async {
    if (passC.text.isNotEmpty && passC.text != confirmPassC.text) {
      return _show('Las contraseñas no coinciden');
    }

    if (_id == null) {
      return _show('Perfil no cargado correctamente.');
    }

    // 1) Actualizo datos generales (PUT /api/profiles/{id})
    final profile = ProfileModel(
      id:           _id!,
      name:         nameC.text,
      lastName:     lastNameC.text,
      email:        emailC.text,
      type:         userType,
      phone:        phoneC.text.isEmpty ? null : phoneC.text,
      companyName:  companyC.text.isEmpty ? null : companyC.text,
      companyRuc:   rucC.text.isEmpty ? null : rucC.text,
      profilePhoto: _photoB64,
    );

    final ok1 = await _service.updateProfile(profile);
    if (!ok1) {
      return _show('Error al actualizar datos generales');
    }

    // 2) Si cambió contraseña, pido credenciales y hago PATCH /api/profiles/password
    if (passC.text.isNotEmpty) {
      final creds = await showDialog<Map<String,String>>(
        context: context,
        builder: (_) {
          final emailAuth = TextEditingController(text: emailC.text);
          final oldPass   = TextEditingController();
          return AlertDialog(
            title: const Text('Confirma tu contraseña'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailAuth,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: oldPass,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña actual'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'email': emailAuth.text,
                    'password': oldPass.text,
                  });
                },
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      );

      if (creds == null || creds['password']!.isEmpty) {
        return _show('Contraseña actual requerida');
      }

      final ok2 = await _service.changePassword(
        creds['email']!,
        creds['password']!,
        passC.text,
      );
      if (!ok2) {
        return _show('Error al cambiar contraseña');
      }
    }

    _show('Perfil actualizado correctamente');
    setState(() => _edit = false);
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Drawer _buildDrawer(BuildContext ctx) {
    return Drawer(
      backgroundColor: const Color(0xFF2C2F38),
      child: ListView(padding: EdgeInsets.zero, children: [
        DrawerHeader(
          child: Column(
            children: [
              Image.asset('assets/images/login_logo.png', height: 100),
              const SizedBox(height: 10),
              Text(
                '${widget.name} ${widget.lastName} - Gerente',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
        _buildDrawerItem(Icons.person, 'PERFIL', widget),
        _buildDrawerItem(Icons.people, 'TRANSPORTISTAS', CarrierProfilesScreen(name: widget.name, lastName: widget.lastName)),
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
                builder: (_) => LoginScreen(
                  onLoginClicked: (_, __) {},
                  onRegisterClicked: () {},
                ),
              ),
                  (Route<dynamic> route) => false,
            );
          },
        ),
      ]),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
