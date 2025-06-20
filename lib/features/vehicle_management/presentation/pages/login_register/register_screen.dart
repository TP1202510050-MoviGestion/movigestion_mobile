import 'package:flutter/material.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/user_registration_screen.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onNextClicked;

  const RegisterScreen({Key? key, required this.onNextClicked}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}



class _RegisterScreenState extends State<RegisterScreen> {
  String _selectedRole = '';

  void _onRoleSelected(String role) {
    setState(() => _selectedRole = role);

    if (role == 'Gerente') {
      // Navega inmediatamente
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserRegistrationScreen(selectedRole: 'Gerente'),
        ),
      );
    } else if (role == 'Transportista') {
      // Muestra diálogo informativo
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF2C2F38),
          title: const Text(
            '¡Hola Transportista!',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Tu cuenta debe ser creada por el administrador de tu empresa. '
                'Por favor, ponte en contacto con tu gerente para que te proporcione acceso.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text('Entendido', style: TextStyle(color: Colors.amber)),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F24),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/images/login_logo.png', height: 100),
              const SizedBox(height: 32),
              const Text(
                'Regístrate como',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 16),
              _roleCard(
                icon: Icons.admin_panel_settings,
                label: 'Administrador de Flota',
                selected: _selectedRole == 'Gerente',
                onTap: () => _onRoleSelected('Gerente'),
              ),
              const SizedBox(height: 16),
              _roleCard(
                icon: Icons.local_shipping,
                label: 'Conductor',
                selected: _selectedRole == 'Transportista',
                onTap: () => _onRoleSelected('Transportista'),
              ),
              const Spacer(),
              const Text(
                'Selecciona tu rol para continuar',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFA000) : const Color(0xFF2F353F),
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: selected ? Colors.black : Colors.white70),
            const SizedBox(width: 20),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.black : Colors.white70,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.black, size: 28),
          ],
        ),
      ),
    );
  }
}
