// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:movigestion_mobile/providers/chat_provider.dart';
// PASO 1: Importar Provider y tu ChatProvider
import 'package:provider/provider.dart';
import 'features/vehicle_management/presentation/pages/login_register/login_screen.dart';

void main() {
  // PASO 2: Envolver la aplicación con el provider
  runApp(
    ChangeNotifierProvider(
      create: (context) => ChatProvider(),
      child: MoviGestionApp(),
    ),
  );
}

class MoviGestionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Opcional: para quitar la cinta de "DEBUG"
      title: 'MoviGestion',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      locale: const Locale('es', 'ES'),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(
          onLoginClicked: (username, password) {},
          onRegisterClicked: () {
            Navigator.pushNamed(context, '/register');
          },
        ),
      },
    );
  }
}