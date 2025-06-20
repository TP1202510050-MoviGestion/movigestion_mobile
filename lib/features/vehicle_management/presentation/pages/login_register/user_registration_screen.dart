import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';                // 📥  foto
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/profile/profile_screen.dart';

import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';

class UserRegistrationScreen extends StatefulWidget {
  final String selectedRole; // siempre "Gerente"

  const UserRegistrationScreen({Key? key, required this.selectedRole})
      : super(key: key);

  @override
  State<UserRegistrationScreen> createState() =>
      _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen>
    with SingleTickerProviderStateMixin {
  // ---------- controllers ----------
  final _nameCtrl        = TextEditingController();
  final _lastNameCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _companyCtrl     = TextEditingController();
  final _rucCtrl         = TextEditingController();
  final _passCtrl        = TextEditingController();
  final _confirmCtrl     = TextEditingController();

  bool _terms = false;
  String? _photoBase64;                 // foto de perfil
  bool get _formOk =>
      _nameCtrl.text.isNotEmpty &&
          _lastNameCtrl.text.isNotEmpty &&
          _emailCtrl.text.isNotEmpty &&
          _phoneCtrl.text.isNotEmpty &&
          _companyCtrl.text.isNotEmpty &&
          _rucCtrl.text.isNotEmpty &&
          _passCtrl.text.isNotEmpty &&
          _passCtrl.text == _confirmCtrl.text &&
          _terms;

  late final AnimationController _anim =
  AnimationController(vsync: this, duration: const Duration(seconds: 1))
    ..forward();

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F24),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 60),
            FadeTransition(
              opacity: _anim,
              child: Image.asset('assets/images/login_logo.png', height: 120),
            ),
            const SizedBox(height: 30),
            Text('Registro de Administrador de Flotas',
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // ------- datos personales -------
            _field('Nombre', _nameCtrl),
            _field('Apellido', _lastNameCtrl),
            _field('Email', _emailCtrl, keyboard: TextInputType.emailAddress),
            _field('Teléfono móvil', _phoneCtrl,
                keyboard: TextInputType.phone),

            // ------- empresa -------
            const SizedBox(height: 10),
            _field('Nombre de la empresa', _companyCtrl),
            _field('RUC de la empresa', _rucCtrl),

            // ------- credenciales -------
            _field('Contraseña', _passCtrl, obscure: true),
            _field('Confirmar contraseña', _confirmCtrl, obscure: true),

            // ------- foto -------
            const SizedBox(height: 10),
            _buildPhotoPicker(),

            // ------- términos -------
            Row(
              children: [
                Checkbox(
                  value: _terms,
                  activeColor: Colors.amber,
                  onChanged: (v) => setState(() => _terms = v ?? false),
                ),
                const Expanded(
                  child: Text('Aceptar Términos y Condiciones',
                      style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ------- botón enviar -------
            ElevatedButton(
              onPressed: _formOk ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _formOk ? Colors.amber : Colors.grey,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('EMPEZAR',
                  style: TextStyle(color: Colors.black)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
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
                );
              },
              child: const Text('¿Ya eres usuario? – Inicia Sesión',
                  style: TextStyle(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- widgets auxiliares ----------
  Widget _field(String label, TextEditingController c,
      {bool obscure = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF2F353F),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Foto de perfil',
            style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        _photoBase64 == null
            ? ElevatedButton.icon(
          onPressed: _pickPhoto,
          icon: const Icon(Icons.photo_camera),
          label: const Text('Seleccionar imagen'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA8E00)),
        )
            : Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.memory(base64Decode(_photoBase64!),
                  height: 100, width: 100, fit: BoxFit.cover),
            ),
            TextButton(
                onPressed: _pickPhoto, child: const Text('Cambiar foto'))
          ],
        ),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    final res = await FilePicker.platform.pickFiles(
        type: FileType.image, withData: true);
    if (res != null && res.files.single.bytes != null) {
      setState(() => _photoBase64 = base64Encode(res.files.single.bytes!));
    }
  }

  // ---------- envío ----------
  Future<void> _submit() async {
    final body = {
      "name": _nameCtrl.text,
      "lastName": _lastNameCtrl.text,
      "email": _emailCtrl.text,
      "password": _passCtrl.text,
      "type": widget.selectedRole,
      "phone": _phoneCtrl.text,
      "companyName": _companyCtrl.text,
      "companyRuc": _rucCtrl.text,
      "profilePhoto": _photoBase64 ?? '',
    };

    try {
      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Registro exitoso')));
        _goToProfile();
      } else {
        _showError('Error al registrar: ${res.statusCode}');
      }
    } catch (_) {
      _showError('Error de conexión');
    }
  }

  void _goToProfile() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => ProfileScreen(
              name: _nameCtrl.text,
              lastName: _lastNameCtrl.text,
            )));
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
