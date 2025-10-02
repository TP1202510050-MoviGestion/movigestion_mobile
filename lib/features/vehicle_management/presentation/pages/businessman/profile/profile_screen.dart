// lib/features/vehicle_management/presentation/pages/businessman/profile/profile_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/app_constants.dart';
import '../../../../../../core/widgets/app_drawer.dart';
import '../../../../data/remote/profile_model.dart';
import '../../../../data/remote/profile_service.dart';

/* ---------- Constantes visuales ---------- */
const _kBg = Color(0xFF1E1F24);
const _kCard = Color(0xFF2F353F);
const _kBar = Color(0xFF2C2F38);
const _kAction = Color(0xFFEA8E00);
const _kTextMain = Colors.white;
const _kTextSub = Colors.white70;
const _kRadius = 16.0;

class ProfileScreen extends StatefulWidget {
  final String name, lastName;
  const ProfileScreen({super.key, required this.name, required this.lastName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameC = TextEditingController();
  final lastNameC = TextEditingController();
  final emailC = TextEditingController();
  final phoneC = TextEditingController();
  final companyC = TextEditingController();
  final rucC = TextEditingController();
  final passC = TextEditingController();
  final confirmPassC = TextEditingController();

  final _service = ProfileService();
  bool _loading = true, _editMode = false, _isSaving = false;
  String userType = '';
  int? _id;
  String? _photoB64;
  File? _pickedImgFile;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    nameC.dispose();
    lastNameC.dispose();
    emailC.dispose();
    phoneC.dispose();
    companyC.dispose();
    rucC.dispose();
    passC.dispose();
    confirmPassC.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}'));
      if (res.statusCode == 200) {
        final decodedBody = utf8.decode(res.bodyBytes);
        final list = jsonDecode(decodedBody) as List;
        final p = list.firstWhere(
              (e) =>
          e['name'].toString().toLowerCase() == widget.name.toLowerCase() &&
              e['lastName'].toString().toLowerCase() == widget.lastName.toLowerCase(),
          orElse: () => null,
        );
        if (p != null) {
          final profile = ProfileModel.fromJson(p as Map<String, dynamic>);
          _initializeStateFromProfile(profile);
        }
      }
    } catch (e) {
      _show('Error al obtener datos: $e', isError: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  // --- MÉTODO AÑADIDO ---
  void _initializeStateFromProfile(ProfileModel p) {
    _id = p.id;
    nameC.text = p.name;
    lastNameC.text = p.lastName;
    emailC.text = p.email;
    phoneC.text = p.phone ?? '';
    companyC.text = p.companyName ?? '';
    rucC.text = p.companyRuc ?? '';
    _photoB64 = p.profilePhoto;
    userType = p.type;
    passC.clear();
    confirmPassC.clear();
  }

  Future<void> _pickPhoto() async {
    if (!_editMode) return;
    try {
      final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (xFile != null) {
        setState(() => _pickedImgFile = File(xFile.path));
      }
    } catch (e) {
      _show('Error al seleccionar imagen: $e', isError: true);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (passC.text.isNotEmpty && passC.text != confirmPassC.text) {
      _show('Las contraseñas no coinciden', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    if (passC.text.isNotEmpty) {
      final creds = await _showPasswordConfirmationDialog();
      if (creds == null || creds['password']!.isEmpty) {
        _show('Contraseña actual requerida para cambiarla.', isError: true);
        setState(() => _isSaving = false);
        return;
      }
      final okPass = await _service.changePassword(creds['email']!, creds['password']!, passC.text);
      if (!okPass) {
        _show('Error al cambiar contraseña. Verifica tu contraseña actual.', isError: true);
        setState(() => _isSaving = false);
        return;
      }
    }

    final profile = ProfileModel(
      id: _id!,
      name: nameC.text.trim(),
      lastName: lastNameC.text.trim(),
      email: emailC.text.trim(),
      type: userType,
      phone: phoneC.text.trim().isEmpty ? null : phoneC.text.trim(),
      companyName: companyC.text.trim().isEmpty ? null : companyC.text.trim(),
      companyRuc: rucC.text.trim().isEmpty ? null : rucC.text.trim(),
      profilePhoto: _pickedImgFile != null ? base64Encode(_pickedImgFile!.readAsBytesSync()) : _photoB64,
    );

    final okProfile = await _service.updateProfile(profile);
    setState(() => _isSaving = false);
    if (okProfile) {
      _show('Perfil actualizado correctamente');
      setState(() {
        _editMode = false;
        _photoB64 = profile.profilePhoto;
        _pickedImgFile = null;
      });
    } else {
      _show('Error al actualizar datos generales.', isError: true);
    }
  }

  Future<Map<String, String>?> _showPasswordConfirmationDialog() async {
    final oldPass = TextEditingController();
    return showDialog<Map<String,String>>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
        title: const Text('Confirma tu contraseña', style: TextStyle(color: _kTextMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Para cambiar tu contraseña, por favor ingresa tu contraseña actual.', style: TextStyle(color: _kTextSub)),
            const SizedBox(height: 16),
            TextField(
              controller: oldPass,
              obscureText: true,
              style: const TextStyle(color: _kTextMain),
              decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  labelStyle: const TextStyle(color: _kTextSub),
                  filled: true, fillColor: _kBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: _kTextSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kAction),
            onPressed: () => Navigator.pop(context, {'email': emailC.text, 'password': oldPass.text}),
            child: const Text('Continuar', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _show(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBar,
        title: Text(_editMode ? 'Editar Perfil' : 'Mi Perfil', style: const TextStyle(color: _kTextMain)),
        iconTheme: const IconThemeData(color: _kTextMain),
        elevation: 0,
      ),
      drawer: AppDrawer(
        name: widget.name,
        lastName: widget.lastName,
        companyName: companyC.text, // Le pasamos el nombre de la empresa desde el controlador
        companyRuc: rucC.text,     // Le pasamos el RUC desde el controlador
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kAction))
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 32.0),
        child: Column(
          children: [
            _buildProfileAvatar(),
            const SizedBox(height: 16),
            Text(
              '${nameC.text} ${lastNameC.text}',
              style: const TextStyle(color: _kTextMain, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              emailC.text,
              style: const TextStyle(color: _kTextSub, fontSize: 16),
            ),
            const SizedBox(height: 32),
            _buildSectionCard(
              title: 'Datos Personales',
              icon: Icons.person_outline,
              children: [
                _field('Nombre', nameC),
                _field('Apellido', lastNameC),
                _field('Teléfono', phoneC, kb: TextInputType.phone),
              ],
            ),
            _buildSectionCard(
              title: 'Datos de la Empresa',
              icon: Icons.business_outlined,
              children: [
                _field('Nombre de la Empresa', companyC),
                _field('RUC', rucC, kb: TextInputType.number),
              ],
            ),
            if (_editMode)
              _buildSectionCard(
                title: 'Seguridad',
                icon: Icons.lock_outline,
                children: [
                  _field('Nueva Contraseña', passC, obs: true, isOptional: true),
                  _field('Confirmar Contraseña', confirmPassC, obs: true, isOptional: true),
                ],
              ),
            if (_editMode)
              Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: _buildSaveCancelButtons(),
              ),

            if (!_editMode)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => setState(() => _editMode = true),
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text('Editar Perfil'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kCard,
                      foregroundColor: _kAction,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final imageProvider = _pickedImgFile != null
        ? FileImage(_pickedImgFile!)
        : (_photoB64 != null && _photoB64!.isNotEmpty
        ? MemoryImage(base64Decode(_photoB64!))
        : const AssetImage('assets/images/Gerente.png')) as ImageProvider;

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 65,
            backgroundColor: _kAction.withOpacity(0.8),
            child: CircleAvatar(
              radius: 62,
              backgroundImage: imageProvider,
              backgroundColor: _kCard,
            ),
          ),
          if (_editMode)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: _kCard, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_outlined, color: _kAction, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      color: _kCard,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kRadius)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _kAction, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: _kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24, color: _kBg),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {TextInputType? kb, bool obs = false, bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        enabled: _editMode,
        obscureText: obs,
        keyboardType: kb,
        style: TextStyle(color: _editMode ? _kTextMain : _kTextSub),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _kTextSub),
          filled: true,
          fillColor: _kBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(_kRadius), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_kRadius), borderSide: const BorderSide(color: _kAction)),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_kRadius), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (v) {
          if (isOptional) return null;
          return (v == null || v.trim().isEmpty) ? 'Este campo es requerido' : null;
        },
      ),
    );
  }
  Widget _buildSaveCancelButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _editMode = false;
                _fetch();
                _pickedImgFile = null;
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kTextSub),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text('Cancelar', style: TextStyle(color: _kTextSub)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.save, color: Colors.black),
            label: const Text('Guardar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAction,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
          ),
        ),
      ],
    );
  }

}