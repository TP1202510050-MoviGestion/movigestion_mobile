import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ----- IMPORTACIONES ORIGINALES (MANTENIDAS) -----
import 'package:movigestion_mobile/core/app_constants.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/reports/reports_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/vehicle/vehicles_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/shipments/shipments_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/profile/profile_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';

import '../../../../../../core/widgets/app_drawer.dart';

// Se asume que AppDrawer existe, pero se usará la implementación _buildDrawer provista en el código original.

class CarrierProfilesScreen extends StatefulWidget {
  final String name, lastName; // datos del gerente
  const CarrierProfilesScreen({
    super.key,
    required this.name,
    required this.lastName,
  });

  @override
  State<CarrierProfilesScreen> createState() => _CarrierProfilesScreenState();
}

class _CarrierProfilesScreenState extends State<CarrierProfilesScreen> {
  // --- Constantes y Colores ---
  static const _primaryColor = Color(0xFFEA8E00);
  static const _backgroundColor = Color(0xFF1E1F24);
  static const _cardColor = Color(0xFF2C2F38);
  static const _textColor = Colors.white;
  static const _textMutedColor = Colors.white70;

  final String _baseApiUrl =
      '${AppConstants.baseUrl}${AppConstants.profile}';

  // --- Estado ---
  bool _isLoading = true;
  List<Map<String, dynamic>> _carriers = [];
  String _companyName = '';
  String _companyRuc = '';

  // --- Ciclo de Vida ---
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // --- Lógica de Datos ---
  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(_baseApiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> allProfiles = jsonDecode(response.body);

        // 1. Obtiene la empresa del gerente.
        final managerProfile = allProfiles.firstWhere(
              (profile) =>
          profile['name'].toString().toLowerCase() ==
              widget.name.toLowerCase() &&
              profile['lastName'].toString().toLowerCase() ==
                  widget.lastName.toLowerCase(),
          orElse: () => null,
        );

        if (managerProfile != null) {
          _companyName = managerProfile['companyName'] ?? '';
          _companyRuc = managerProfile['companyRuc'] ?? '';
        }

        // 2. Filtra SOLO transportistas de la misma empresa y RUC.
        _carriers = allProfiles
            .where((profile) {
          final bool isTransportista =
              profile['type']?.toString() == 'Transportista';
          final bool sameCompanyName =
              (profile['companyName'] ?? '')
                  .toString()
                  .toLowerCase() ==
                  _companyName.toLowerCase();
          final bool sameCompanyRuc =
              (profile['companyRuc'] ?? '').toString() == _companyRuc;
          return isTransportista &&
              sameCompanyName &&
              sameCompanyRuc;
        })
            .map((profile) => {
          'id': profile['id'],
          'name': profile['name'],
          'lastName': profile['lastName'],
          'email': profile['email'],
          'phone': profile['phone'] ?? 'N/A',
          'profilePhoto': profile['profilePhoto'] ?? ''
        })
            .toList();
      } else {
        _showSnackBar('Error al cargar datos: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error de conexión al cargar perfiles.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Constructores de UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      drawer: AppDrawer(
        name: widget.name,
        lastName: widget.lastName,
        companyName: _companyName, // Usamos la variable de estado de la pantalla
        companyRuc: _companyRuc,     // Usamos la variable de estado de la pantalla
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _cardColor,
      title: const Row(
        children: [
          Icon(Icons.group, color: _primaryColor),
          SizedBox(width: 12),
          Text('Conductores', style: TextStyle(color: _textColor)),
        ],
      ),
      elevation: 0,
    );
  }

  Widget _buildFloatingActionButton() {
    return Tooltip(
      message: 'Añadir Conductor',
      child: FloatingActionButton(
        heroTag: 'addCarrier',
        backgroundColor: _primaryColor,
        onPressed: _showAddCarrierDialog,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }
    if (_carriers.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron conductores.',
          style: TextStyle(color: _textMutedColor, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _carriers.length,
      itemBuilder: (context, index) {
        final carrier = _carriers[index];
        return _buildCarrierCard(
          id: carrier['id'],
          name: carrier['name'],
          lastName: carrier['lastName'],
          mail: carrier['email'],
          phone: carrier['phone'],
          photoB64: carrier['profilePhoto'],
        );
      },
    );
  }

  /// Tarjeta de transportista
  Widget _buildCarrierCard({
    required int id,
    required String name,
    required String lastName,
    required String mail,
    required String phone,
    required String photoB64,
  }) {
    ImageProvider avatar;
    try {
      if (photoB64.isNotEmpty) {
        avatar = MemoryImage(base64Decode(photoB64));
      } else {
        avatar = const AssetImage('assets/images/driver.png');
      }
    } catch (_) {
      avatar = const AssetImage('assets/images/driver.png');
    }

    return Card(
      elevation: 2.0,
      color: _cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: avatar,
            radius: 28,
            backgroundColor: Colors.grey[800],
          ),
          title: Text(
            '$name $lastName',
            style: const TextStyle(
              color: _textColor,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.email_outlined, mail),
                const SizedBox(height: 4),
                _buildInfoRow(Icons.phone_outlined, phone),
              ],
            ),
          ),
          trailing: IconButton(
            icon:
            const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDeleteDialog(id),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _textMutedColor, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style:
            const TextStyle(color: _textMutedColor, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Diálogo para añadir un nuevo transportista.
  Future<void> _showAddCarrierDialog() async {
    final nameC = TextEditingController();
    final lastC = TextEditingController();
    final emailC = TextEditingController();
    final phoneC = TextEditingController();
    final passC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Nuevo Conductor', style: TextStyle(color: _primaryColor)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _buildDialogTextField('Nombre', nameC, icon: Icons.person_outline),
              _buildDialogTextField('Apellido', lastC, icon: Icons.person_outline),
              _buildDialogTextField('Email', emailC, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              _buildDialogTextField('Teléfono', phoneC, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              _buildDialogTextField('Contraseña', passC, icon: Icons.lock_outline, obscureText: true),
            ]),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: _textMutedColor)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text('Registrar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () async {
              if ([nameC, lastC, emailC, phoneC, passC].any((c) => c.text.trim().isEmpty)) {
                _showSnackBar('Por favor, completa todos los campos.');
                return;
              }
              Navigator.pop(context); // Cierra el diálogo antes de la llamada
              await _registerCarrier({
                "name": nameC.text.trim(),
                "lastName": lastC.text.trim(),
                "email": emailC.text.trim(),
                "password": passC.text,
                "phone": phoneC.text.trim(),
                "companyName": _companyName,
                "companyRuc": _companyRuc,
                "type": "Transportista",
                "profilePhoto": ""
              });
            },
          ),
        ],
      ),
    );
  }

  /// Campo de texto estilizado para los diálogos.
  Widget _buildDialogTextField(
      String label,
      TextEditingController controller, {
        IconData? icon,
        TextInputType? keyboardType,
        bool obscureText = false,
      }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: _textColor),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: _textMutedColor),
            prefixIcon: icon != null ? Icon(icon, color: _textMutedColor, size: 20) : null,
            filled: true,
            fillColor: _backgroundColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primaryColor),
            ),
          ),
        ),
      );

  // --- Lógica de Acciones ---

  Future<void> _registerCarrier(Map<String, dynamic> body) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(_baseApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar('Conductor registrado con éxito.');
        await _fetchData(); // Refresca toda la lista
      } else {
        _showSnackBar('Error al registrar (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Error de conexión al registrar.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCarrier(int id) async {
    final originalCarriers = List<Map<String, dynamic>>.from(_carriers);

    // Optimistic UI: remueve el item de la UI inmediatamente
    setState(() {
      _carriers.removeWhere((p) => p['id'] == id);
    });

    try {
      final response = await http.delete(Uri.parse('$_baseApiUrl/$id'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSnackBar('Conductor eliminado.');
      } else {
        // Si falla, revierte el cambio en la UI
        _showSnackBar('Error al eliminar. Inténtalo de nuevo.');
        setState(() {
          _carriers = originalCarriers;
        });
      }
    } catch (e) {
      _showSnackBar('Error de conexión al eliminar.');
      setState(() {
        _carriers = originalCarriers;
      });
    }
  }

  /// Diálogo para confirmar la eliminación de un perfil.
  void _confirmDeleteDialog(int id) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text('Eliminar Conductor', style: TextStyle(color: _textColor)),
      content: const Text('¿Estás seguro de que deseas eliminar a este transportista? Esta acción no se puede deshacer.', style: TextStyle(color: _textMutedColor)),
      actions: [
        TextButton(
          child: const Text('Cancelar', style: TextStyle(color: _textMutedColor)),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
          child: const Text('Eliminar', style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
          onPressed: () async {
            Navigator.pop(context); // Cierra el diálogo
            await _deleteCarrier(id);
          },
        ),
      ],
    ),
  );

  // --- Helpers ---
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _cardColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


}