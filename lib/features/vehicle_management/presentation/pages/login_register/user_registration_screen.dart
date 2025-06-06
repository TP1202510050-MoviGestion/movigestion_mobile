import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/profile/profile_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/carrier/profile/profile_screen2.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';

class UserRegistrationScreen extends StatefulWidget {
  final String selectedRole;

  const UserRegistrationScreen({
    Key? key,
    required this.selectedRole,
  }) : super(key: key);

  @override
  _UserRegistrationScreenState createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _dniController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _termsAccepted = false;
  bool _formValid = false;
  String _errorMessage = '';

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
    _nameController.addListener(_validateForm);
    _usernameController.addListener(_validateForm);
    _dniController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      if (_nameController.text.isEmpty ||
          _usernameController.text.isEmpty ||
          _dniController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty) {
        _errorMessage = 'Todos los campos son obligatorios';
        _formValid = false;
      } else if (_passwordController.text != _confirmPasswordController.text) {
        _errorMessage = 'Las contraseñas no coinciden';
        _formValid = false;
      } else if (!_termsAccepted) {
        _errorMessage = 'Debes aceptar los Términos y Condiciones';
        _formValid = false;
      } else {
        _errorMessage = '';
        _formValid = true;
      }
    });
  }

  Future<void> _submitRegistrationForm() async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.profile}');

    final body = {
      "name": _nameController.text,
      "lastName": _usernameController.text,
      "email": _dniController.text,
      "password": _passwordController.text,
      "type": widget.selectedRole,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso')),
        );
        _animationController.forward();
        await Future.delayed(const Duration(seconds: 1));
        _navigateBasedOnRole();
      } else {
        setState(() {
          _errorMessage = 'Error al registrar usuario: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al realizar la solicitud';
      });
    }
  }

  void _navigateBasedOnRole() {
    if (widget.selectedRole == 'Gerente') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            name: _nameController.text,
            lastName: _usernameController.text,
          ),
        ),
      );
    } else if (widget.selectedRole == 'Transportista') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen2(
            name: _nameController.text,
            lastName: _usernameController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F24), // Fondo oscuro moderno
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                'assets/images/login_logo.png',
                height: 120,
              ),
            ),
            // Logo en la parte superior
            Image.asset(
              'assets/images/login_logo.png',
              height: 100,
            ),
            const SizedBox(height: 40),
            const SizedBox(height: 30),
            Text(
              'Registro de ${widget.selectedRole}',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField('Nombre', _nameController),
            const SizedBox(height: 20),
            _buildTextField('Apellido', _usernameController),
            const SizedBox(height: 20),
            _buildTextField('Email', _dniController),
            const SizedBox(height: 20),
            _buildTextField('Contraseña', _passwordController, obscureText: true),
            const SizedBox(height: 20),
            _buildTextField('Confirmar Contraseña', _confirmPasswordController, obscureText: true),
            const SizedBox(height: 20),
            _buildTermsCheckbox(),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            _buildSubmitButton(),
            const SizedBox(height: 20),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF2F353F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _termsAccepted,
          onChanged: (bool? newValue) {
            setState(() {
              _termsAccepted = newValue ?? false;
              _validateForm();
            });
          },
          activeColor: Colors.amber,
        ),
        const Text(
          'Confirmar Términos y Condiciones',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _formValid ? _submitRegistrationForm : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _formValid ? Colors.amber : Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text(
        'EMPEZAR',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return TextButton(
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
      child: const Text(
        '¿Ya eres usuario? - Inicia Sesión',
        style: TextStyle(
          color: Colors.white,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
