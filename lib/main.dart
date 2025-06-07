import 'package:flutter/material.dart';
import 'features/vehicle_management/presentation/pages/login_register/login_screen.dart';

void main() {
  runApp(MoviGestionApp());
}

class MoviGestionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoviGestion',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(
          onLoginClicked: (username, password) {
          },
          onRegisterClicked: () {
            Navigator.pushNamed(context, '/register');
          },
        ),

      },
    );
  }
}
