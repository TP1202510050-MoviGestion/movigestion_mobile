import 'dart:convert';
import 'package:file_picker/file_picker.dart';                       // 📦  NUEVO
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:movigestion_mobile/core/app_constants.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/reports/reports_carrier_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/shipments/shipments_screen2.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/vehicle/vehicle_detail_carrier_screen.dart';

class ProfileScreen2 extends StatefulWidget {
  final String name, lastName;
  const ProfileScreen2({super.key, required this.name, required this.lastName});

  @override
  State<ProfileScreen2> createState() => _ProfileScreen2State();
}

class _ProfileScreen2State extends State<ProfileScreen2> {
  /* ---------- controllers ---------- */
  late final TextEditingController nameC,
      lastC,
      mailC,
      phoneC,
      passC,
      confPassC,
      dlgMailC,
      dlgPassC;

  /* ---------- misc ---------- */
  final ProfileService _service = ProfileService();
  bool _loading = true, _edit = false;

  String _type          = '';
  String _companyName   = '';
  String _companyRuc    = '';
  String? _photoB64;                                 // 🖼️ base-64 de la foto

  @override
  void initState() {
    super.initState();
    nameC      = TextEditingController();
    lastC      = TextEditingController();
    mailC      = TextEditingController();
    phoneC     = TextEditingController();
    passC      = TextEditingController();
    confPassC  = TextEditingController();
    dlgMailC   = TextEditingController();
    dlgPassC   = TextEditingController();
    _fetch();
  }

  @override
  void dispose() {
    nameC.dispose();
    lastC.dispose();
    mailC.dispose();
    phoneC.dispose();
    passC.dispose();
    confPassC.dispose();
    dlgMailC.dispose();
    dlgPassC.dispose();
    super.dispose();
  }

  /* =================== DATA =================== */
  Future<void> _fetch() async {
    try {
      final res = await http.get(Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        final p = list.firstWhere(
              (e) =>
          e['name'].toString().toLowerCase() == widget.name.toLowerCase() &&
              e['lastName'].toString().toLowerCase() == widget.lastName.toLowerCase(),
          orElse: () => null,
        );

        if (p != null) {
          nameC.text   = p['name'];
          lastC.text   = p['lastName'];
          mailC.text   = p['email'];
          phoneC.text  = p['phone']        ?? '';
          _photoB64    = p['profilePhoto'];                 // 👈
          _type        = p['type'];
          _companyName = p['companyName'] ?? '';
          _companyRuc  = p['companyRuc']  ?? '';
        } else {
          _snack('No se encontró un perfil que coincida.');
        }
      } else {
        _snack('Error al cargar los perfiles');
      }
    } catch (_) {
      _snack('Error al obtener el perfil');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* =================== UPDATE =================== */
  Future<void> _update() async {
    if (passC.text != confPassC.text) {
      _snack('Las contraseñas no coinciden'); return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar credenciales'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: dlgMailC, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(controller: dlgPassC, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok != true) return;

    final updated = {
      'name'        : nameC.text,
      'lastName'    : lastC.text,
      'email'       : mailC.text,
      'password'    : passC.text,
      'phone'       : phoneC.text,
      'profilePhoto': _photoB64 ?? '',
      'type'        : _type,
    };

    final success = await _service.updateProfileByEmailAndPassword(
      dlgMailC.text, dlgPassC.text, updated,
    );

    if (success) {
      _snack('Datos actualizados');
      setState(() => _edit = false);
    } else {
      _snack('Error al actualizar');
    }
  }

  /* =================== PICK PHOTO =================== */
  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() => _photoB64 = base64Encode(result.files.single.bytes!));
    }
  }

  /* =================== UI =================== */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F24),
      appBar: _appBar(),
      drawer: _buildDrawer(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA8E00)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ---------------- Avatar ----------------
          GestureDetector(
            onTap: _edit ? _pickPhoto : null,
            child: CircleAvatar(
              radius: 60,
              backgroundImage: _photoB64 != null && _photoB64!.isNotEmpty
                  ? MemoryImage(base64Decode(_photoB64!)) as ImageProvider
                  : const AssetImage('assets/images/transportista.png'),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text('Bienvenido Conductor, ${widget.name} ${widget.lastName}',
                style: const TextStyle(color: Colors.white, fontSize: 22)),
          ),
          if (_companyName.isNotEmpty || _companyRuc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Nombre de Empresa: $_companyName  •  RUC: $_companyRuc',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 24),

          _input('Nombre',        nameC,  _edit),
          _gap(), _input('Apellido',      lastC,  _edit),
          _gap(), _input('Email',         mailC,  _edit, kb: TextInputType.emailAddress),
          _gap(), _input('Teléfono',      phoneC, _edit, kb: TextInputType.phone),

          if (_edit) ...[
            _gap(), _input('Contraseña',            passC,       true, obs: true),
            _gap(), _input('Confirmar Contraseña',  confPassC,   true, obs: true),
          ],

          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA8E00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(_edit ? 'CONFIRMAR ACTUALIZACIÓN' : 'EDITAR DATOS',
                  style: const TextStyle(color: Colors.black)),
              onPressed: _edit ? _update : () => setState(() => _edit = true),
            ),
          ),
        ]),
      ),
    );
  }

  /* ------------ helpers UI ------------ */
  AppBar _appBar() => AppBar(
    backgroundColor: const Color(0xFF2C2F38),
    title: const Row(children: [
      Icon(Icons.person, color: Colors.amber),
      SizedBox(width: 10),
      Text('Perfil', style: TextStyle(color: Colors.grey, fontSize: 22, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _input(String label, TextEditingController c, bool enabled,
      {TextInputType? kb, bool obs = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          enabled: enabled,
          obscureText: obs,
          keyboardType: kb,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
      ],
    );
  }

  Widget _readOnly(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(value, style: const TextStyle(color: Colors.black87)),
      ),
    ],
  );

  Widget _gap() => const SizedBox(height: 16);

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.black26));

  /* ------------ drawer ------------ */
  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2C2F38),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Column(
              children: [
                Image.asset('assets/images/login_logo.png', height: 100),
                const SizedBox(height: 10),
                Text('${widget.name} ${widget.lastName} - Transportista',
                    style: const TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          ),
          _drawerItem(Icons.person, 'PERFIL',
              ProfileScreen2(name: widget.name, lastName: widget.lastName)),
          _drawerItem(Icons.report, 'REPORTES',
              ReportsCarrierScreen(name: widget.name, lastName: widget.lastName)),
          _drawerItem(Icons.directions_car, 'VEHÍCULOS',
              VehicleDetailCarrierScreenScreen(name: widget.name, lastName: widget.lastName)),
          _drawerItem(Icons.local_shipping, 'ENVIOS',
              ShipmentsScreen2(name: widget.name, lastName: widget.lastName)),
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
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, Widget page) => ListTile(
    leading: Icon(icon, color: Colors.white),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
  );
}
