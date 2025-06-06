import 'package:flutter/material.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/user_registration_screen.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onNextClicked;

  const RegisterScreen({Key? key, required this.onNextClicked}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  String _selectedRole = '';
  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _onRoleSelected(String role) {
    setState(() {
      _selectedRole = role;
    });
    _animationController.forward().then((_) => _animationController.reverse());
  }

  void _navigateToUserRegistration() {
    if (_selectedRole.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserRegistrationScreen(
            selectedRole: _selectedRole,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un rol'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
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
            Image.asset(
              'assets/images/login_logo.png',
              height: 120,
            ),
            const SizedBox(height: 40),
            _buildRoleButton('Gerente'),
            const SizedBox(height: 16),
            _buildRoleButton('Transportista'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _navigateToUserRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA000),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Siguiente',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(String role) {
    return ScaleTransition(
      scale: _selectedRole == role ? _buttonScaleAnimation : const AlwaysStoppedAnimation(1.0),
      child: ElevatedButton(
        onPressed: () => _onRoleSelected(role),
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedRole == role ? Colors.orangeAccent : const Color(0xFF2F353F),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          shadowColor: _selectedRole == role ? Colors.orange : Colors.transparent,
          elevation: _selectedRole == role ? 8 : 2,
        ),
        child: Text(
          role.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _selectedRole == role ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }
}
