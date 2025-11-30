import 'dart:convert';
import 'dart:io';
import 'dart:async'; // <--- AÑADE ESTA LÍNEA

import 'package:file_picker/file_picker.dart';                // 📥  foto
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/profile/profile_screen.dart';
import 'package:flutter/services.dart';
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

  final _formKey = GlobalKey<FormState>();

  // ---------- controllers ----------
  final _nameCtrl        = TextEditingController();
  final _lastNameCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _companyCtrl     = TextEditingController();
  final _rucCtrl         = TextEditingController();
  final _passCtrl        = TextEditingController();
  final _confirmCtrl     = TextEditingController();


  // --- ESTADO PARA VALIDACIÓN ASÍNCRONA DE EMAIL ---
  Timer? _debounce;
  bool _isCheckingEmail = false;
  bool _isEmailDuplicate = false;
  final FocusNode _emailFocusNode = FocusNode();
  // ---------------------------------------------------

  bool _terms = false;
  String? _photoBase64;

  late final AnimationController _anim =
  AnimationController(vsync: this, duration: const Duration(seconds: 1))
    ..forward();

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_onEmailChanged);
    _emailFocusNode.addListener(_onEmailFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _emailCtrl.removeListener(_onEmailChanged);
    _emailFocusNode.removeListener(_onEmailFocusChanged);
    _emailFocusNode.dispose();

    // ... (resto de los dispose) ...
    _nameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _rucCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  // ---------- LÓGICA DE VALIDACIÓN ASÍNCRONA (NUEVA VERSIÓN) ----------

  void _onEmailChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (_emailCtrl.text.isNotEmpty && mounted && !_emailFocusNode.hasFocus) {
        _checkEmail(_emailCtrl.text);
      }
    });
  }

  void _onEmailFocusChanged() {
    if (!_emailFocusNode.hasFocus) {
      final email = _emailCtrl.text;
      final isFormatValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
      if (email.isNotEmpty && isFormatValid) {
        _checkEmail(email);
      }
    }
  }

  // --- FUNCIÓN _checkEmail MODIFICADA ---
  Future<void> _checkEmail(String email) async {
    setState(() {
      _isCheckingEmail = true;
      _isEmailDuplicate = false;
    });

    try {
      // 1. Hacemos el GET a la lista completa de perfiles
      final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}');
      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> profiles = json.decode(response.body);

        // 2. Buscamos una coincidencia en el cliente
        // Normalizamos ambos emails para una comparación insensible a mayúsculas/minúsculas
        final normalizedEmail = email.trim().toLowerCase();
        final bool exists = profiles.any((profile) =>
        (profile['email'] as String?)?.trim().toLowerCase() == normalizedEmail
        );

        setState(() {
          _isEmailDuplicate = exists;
        });

        // 3. Si hay duplicado, forzamos una re-validación del formulario
        if (_isEmailDuplicate) {
          _formKey.currentState?.validate();
        }

      }
    } catch (e) {
      debugPrint("Error al verificar email: $e");
    } finally {
      if (mounted) {
        setState(() => _isCheckingEmail = false);
      }
    }
  }




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



  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F24),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Form(
    key: _formKey, // Asigna la clave
    autovalidateMode: AutovalidateMode.onUserInteraction, // Muestra errores mientras el usuario escribe
        child: Column(
          children: [
            const SizedBox(height: 60),
            FadeTransition(
              opacity: _anim,
              child: Image.asset('assets/images/login_logo.png', height: 120),
            ),
            const SizedBox(height: 30),
            Text('Registro de Administrador',
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // ------- datos personales -------
            _field(
              'Nombre',
              _nameCtrl,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))], // Solo letras y espacios
              validator: (val) {
                if (val == null || val.isEmpty) return 'El nombre es requerido';
                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(val)) return 'Solo se permiten letras';
                return null;
              },
            ),
            _field(
              'Apellido',
              _lastNameCtrl,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))], // Solo letras y espacios
              validator: (val) {
                if (val == null || val.isEmpty) return 'El apellido es requerido';
                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(val)) return 'Solo se permiten letras';
                return null;
              },
            ),
            _field(
              'Email',
              _emailCtrl,
              focusNode: _emailFocusNode,
              keyboard: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.isEmpty) return 'El email es requerido';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                  return 'Formato de email no válido';
                }
                if (_isEmailDuplicate) {
                  return 'Este correo electrónico ya está registrado';
                }
                return null;
              },
            ),

            _field(
              'Teléfono móvil',
              _phoneCtrl,
              keyboard: TextInputType.phone,
              formatters: [
                FilteringTextInputFormatter.digitsOnly, // Solo números
                LengthLimitingTextInputFormatter(9), // Máximo 9 dígitos
              ],
              validator: (val) {
                if (val == null || val.isEmpty) return 'El teléfono es requerido';
                if (val.length != 9) return 'Debe tener 9 dígitos';
                if (!val.startsWith('9')) return 'Debe empezar con 9';
                return null;
              },
            ),

            // ------- empresa -------
            const SizedBox(height: 10),
            _field(
              'Nombre de la empresa',
              _companyCtrl,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]'))], // Letras, números, espacios
              validator: (val) {
                if (val == null || val.isEmpty) return 'El nombre es requerido';
                if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(val)) return 'No se permiten caracteres especiales';
                return null;
              },
            ),
            _field(
              'RUC de la empresa',
              _rucCtrl,
              keyboard: TextInputType.number,
              formatters: [
                FilteringTextInputFormatter.digitsOnly, // Solo números
                LengthLimitingTextInputFormatter(11), // Máximo 11 dígitos
              ],
              validator: (val) {
                if (val == null || val.isEmpty) return 'El RUC es requerido';
                if (val.length != 11) return 'El RUC debe tener 11 dígitos';
                return null;
              },
            ),

            // ------- credenciales -------
            _field(
              'Contraseña',
              _passCtrl,
              obscure: true,
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'La contraseña es requerida';
                }
                if (val.length < 8) {
                  return 'Mínimo 8 caracteres';
                }
                // Expresión regular que verifica al menos una letra y al menos un número
                if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$').hasMatch(val)) {
                  return 'Debe contener letras y números';
                }
                return null;
              },
            ),
            _field(
              'Confirmar contraseña',
              _confirmCtrl,
              obscure: true,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Confirme su contraseña';
                if (val != _passCtrl.text) return 'Las contraseñas no coinciden';
                return null;
              },
            ),

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
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
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
      ),
    );
  }

  // ---------- widgets auxiliares ----------
  Widget _field(
      String label,
      TextEditingController c, {
        bool obscure = false,
        TextInputType? keyboard,
        String? Function(String?)? validator, // Para las reglas de validación
        List<TextInputFormatter>? formatters, // Para restringir el teclado
        FocusNode? focusNode, // <-- PARÁMETRO AÑADIDO

      }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: c,
        focusNode: focusNode, // <-- USO DEL PARÁMETRO
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
        validator: validator,
        inputFormatters: formatters,
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

    if (!_formKey.currentState!.validate()) {
      // Si la validación falla, no hagas nada.
      // Los mensajes de error ya son visibles en la UI.
      _showError("Por favor, corrige los errores en el formulario");
      return;
    }

    // --- SEGUNDO, VALIDA LOS TÉRMINOS Y CONDICIONES MANUALMENTE ---
    if (!_terms) {
      _showError("Debes aceptar los términos y condiciones");
      return;
    }


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
