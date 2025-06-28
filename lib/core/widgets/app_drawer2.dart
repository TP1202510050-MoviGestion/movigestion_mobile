import 'dart:convert';
import 'package:flutter/material.dart';

// Importa los servicios y pantallas necesarios
import 'package:movigestion_mobile/features/vehicle_management/data/remote/profile_service.dart';


import '../../features/vehicle_management/presentation/pages/businessman/carrier_profiles/carrier_profiles.dart';
import '../../features/vehicle_management/presentation/pages/businessman/profile/profile_screen.dart';
import '../../features/vehicle_management/presentation/pages/businessman/reports/reports_screen.dart';
import '../../features/vehicle_management/presentation/pages/businessman/shipments/shipments_screen.dart';
import '../../features/vehicle_management/presentation/pages/businessman/vehicle/vehicles_screen.dart';
import '../../features/vehicle_management/presentation/pages/carrier/profile/profile_screen2.dart';
import '../../features/vehicle_management/presentation/pages/carrier/reports/reports_carrier_screen.dart';
import '../../features/vehicle_management/presentation/pages/carrier/routes/routes_driver_screen.dart';
import '../../features/vehicle_management/presentation/pages/carrier/shipments/shipments_screen2.dart';
import '../../features/vehicle_management/presentation/pages/carrier/vehicle/vehicle_detail_carrier_screen.dart';
import '../../features/vehicle_management/presentation/pages/login_register/login_screen.dart';

// Constantes de estilo
class AppColors {
  static const Color surface = Color(0xFF2C2F38);
  static const Color text = Colors.white;
}

// 1. Convertimos AppDrawer a un StatefulWidget
class AppDrawer2 extends StatefulWidget {
  final String name;
  final String lastName;

  const AppDrawer2({
    Key? key,
    required this.name,
    required this.lastName,
  }) : super(key: key);

  @override
  _AppDrawer2State createState() => _AppDrawer2State();
}

class _AppDrawer2State extends State<AppDrawer2> {
  // 2. Añadimos el servicio y variables de estado
  final ProfileService _profileService = ProfileService();
  String? _profilePhotoBase64;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 3. Llamamos al método para obtener los datos del perfil al iniciar
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profile = await _profileService.getProfileByNameAndLastName(
        widget.name,
        widget.lastName,
      );

      // Verificamos que el widget siga "montado" antes de actualizar el estado
      if (mounted) {
        setState(() {
          // Guardamos la foto (puede ser null si no existe)
          _profilePhotoBase64 = profile?.profilePhoto;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching profile for drawer: $e");
      if (mounted) {
        setState(() {
          _isLoading = false; // Dejamos de cargar incluso si hay un error
        });
      }
    }
  }

  // 4. Widget dinámico para mostrar la foto de perfil
  Widget _buildProfileImage() {
    // Estado de carga
    if (_isLoading) {
      return const CircleAvatar(
        radius: 45,
        backgroundColor: Colors.white24,
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      );
    }

    // Si tenemos la foto y no está vacía, la mostramos
    if (_profilePhotoBase64 != null && _profilePhotoBase64!.isNotEmpty) {
      try {
        final imageBytes = base64Decode(_profilePhotoBase64!);
        return CircleAvatar(
          radius: 45,
          backgroundImage: MemoryImage(imageBytes),
          backgroundColor: Colors.white24, // Color de fondo por si la imagen tiene transparencias
        );
      } catch (e) {
        // Si hay un error decodificando, mostramos el icono de fallback
        print("Error decoding base64 profile image: $e");
        return _buildFallbackProfileIcon();
      }
    }

    // Fallback: Si no hay foto o hubo un error, mostramos un icono genérico
    return _buildFallbackProfileIcon();
  }

  Widget _buildFallbackProfileIcon() {
    return const CircleAvatar(
      radius: 45,
      backgroundColor: Colors.white24,
      child: Icon(
        Icons.person,
        size: 50,
        color: Colors.white70,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.surface,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 5. Usamos nuestro nuevo widget dinámico aquí
                _buildProfileImage(),
                const SizedBox(height: 12),
                Text(
                  '${widget.name} ${widget.lastName} – Conductor',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _drawerItem(
            context,
            icon: Icons.person,
            title: 'PERFIL',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen2(name: widget.name, lastName: widget.lastName)));
            },
          ),
          _drawerItem(
            context,
            icon: Icons.report,
            title: 'REPORTES',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsCarrierScreen(name: widget.name, lastName: widget.lastName)));
            },
          ),
          _drawerItem(
            context,
            icon: Icons.directions_car,
            title: 'VEHÍCULO',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailCarrierScreen(name: widget.name, lastName: widget.lastName)));
            },
          ),
          _drawerItem(
            context,
            icon: Icons.route,
            title: 'RUTAS',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => RoutesDriverScreen(name: widget.name, lastName: widget.lastName)));
            },
          ),
          const SizedBox(height: 160),

          _drawerItem(
            context,
            icon: Icons.logout,
            title: 'CERRAR SESIÓN',
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen(onLoginClicked: (_, __) {}, onRegisterClicked: () {})),
                  (route) => false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.text),
      title: Text(title, style: const TextStyle(color: AppColors.text)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}