import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/profile/profile_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/shipments/shipments_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/vehicle/vehicles_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/reports/reports_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/carrier_profiles/carrier_profiles.dart';
import 'dart:convert';

class VehicleDetailScreen extends StatefulWidget {
  final VehicleModel vehicle;
  final String name;
  final String lastName;

  const VehicleDetailScreen({
    Key? key,
    required this.vehicle,
    required this.name,
    required this.lastName,
  }) : super(key: key);

  @override
  _VehicleDetailScreenState createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> with SingleTickerProviderStateMixin {
  late TextEditingController licensePlateController;
  late TextEditingController modelController;
  late double engineValue;
  late double fuelValue;
  late double tiresValue;
  late double electricalSystemValue;
  late double transmissionTempValue;
  late TextEditingController driverNameController;
  late TextEditingController colorController;
  late TextEditingController lastTechnicalInspectionDateController;
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();
  final VehicleService vehicleService = VehicleService();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    licensePlateController = TextEditingController(text: widget.vehicle.licensePlate);
    modelController = TextEditingController(text: widget.vehicle.model);
    engineValue = widget.vehicle.engine.toDouble();
    fuelValue = widget.vehicle.fuel.toDouble();
    tiresValue = widget.vehicle.tires.toDouble();
    electricalSystemValue = widget.vehicle.electricalSystem.toDouble();
    transmissionTempValue = widget.vehicle.transmissionTemperature.toDouble();
    driverNameController = TextEditingController(text: widget.vehicle.driverName);
    colorController = TextEditingController(text: widget.vehicle.color);
    lastTechnicalInspectionDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(widget.vehicle.lastTechnicalInspectionDate),
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      _animationController.forward();
    }
  }

  Future<void> _updateVehicle() async {
    try {
      VehicleModel updatedVehicle = VehicleModel(
        id: widget.vehicle.id,
        userId: widget.vehicle.userId,
        licensePlate: licensePlateController.text,
        model: modelController.text,
        engine: engineValue.toInt(),
        fuel: fuelValue.toInt(),
        tires: tiresValue.toInt(),
        electricalSystem: electricalSystemValue.toInt(),
        transmissionTemperature: transmissionTempValue.toInt(),
        driverName: driverNameController.text,
        vehicleImage: _selectedImage != null ? _encodeImageToBase64(_selectedImage!) : widget.vehicle.vehicleImage,
        color: colorController.text,
        lastTechnicalInspectionDate: DateFormat('yyyy-MM-dd').parse(lastTechnicalInspectionDateController.text),
        createdAt: widget.vehicle.createdAt,
      );

      bool success = await vehicleService.updateVehicle(widget.vehicle.id, updatedVehicle);
      if (success) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => VehiclesScreen(
              name: widget.name,
              lastName: widget.lastName,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      } else {
        _showSnackbar('Error al actualizar el vehículo');
      }
    } catch (error) {
      _showSnackbar('Error al actualizar el vehículo: $error');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  String _encodeImageToBase64(File image) {
    List<int> imageBytes = image.readAsBytesSync();
    return base64Encode(imageBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F38),
        title: const Text(
          'Detalle del Vehículo',
          style: TextStyle(color: Colors.grey),
        ),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1E1F24),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _selectedImage != null
                  ? _buildVehicleImage(_selectedImage!)
                  : widget.vehicle.vehicleImage.isNotEmpty
                  ? _buildVehicleNetworkImage(widget.vehicle.vehicleImage)
                  : _buildNoImagePlaceholder(),
            ),
            const SizedBox(height: 20),
            _buildSectionContainer(_buildTextField('Placa', licensePlateController)),
            _buildSectionContainer(_buildTextField('Modelo', modelController)),
            _buildSectionContainer(_buildSliderField('Motor (%)', engineValue, (value) {
              setState(() {
                engineValue = value;
              });
            })),
            _buildSectionContainer(_buildSliderField('Combustible (%)', fuelValue, (value) {
              setState(() {
                fuelValue = value;
              });
            })),
            _buildSectionContainer(_buildSliderField('Neumáticos (%)', tiresValue, (value) {
              setState(() {
                tiresValue = value;
              });
            })),
            _buildSectionContainer(_buildSliderField('Sistema Eléctrico (%)', electricalSystemValue, (value) {
              setState(() {
                electricalSystemValue = value;
              });
            })),
            _buildSectionContainer(_buildSliderField('Temperatura de Transmisión (%)', transmissionTempValue, (value) {
              setState(() {
                transmissionTempValue = value;
              });
            })),
            _buildSectionContainer(_buildTextField('Conductor', driverNameController)),
            _buildSectionContainer(_buildTextField('Color', colorController)),
            _buildSectionContainer(_buildDateField('Fecha de Última Inspección Técnica', lastTechnicalInspectionDateController)),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _updateVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA8E00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  elevation: 5,
                ),
                child: const Text(
                  'Guardar cambios',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleImage(File image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.file(
        image,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildVehicleNetworkImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildNoImagePlaceholder(),
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2E35),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Center(
        child: Text(
          'Toca para seleccionar imagen',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSectionContainer(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2F353F),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSliderField(String label, double value, ValueChanged<double> onChanged) {
    String getConditionText(double value) {
      if (value > 75) {
        return "En excelente estado";
      } else if (value > 60) {
        return "En buen estado";
      } else if (value > 35) {
        return "Presenta algunas fallas";
      } else {
        return "En mal estado";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value.toInt()}%',
          style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 5),
        Text(
          getConditionText(value),
          style: TextStyle(
            fontSize: 14,
            color: value > 75
                ? Colors.green
                : value > 60
                ? Colors.amber
                : value > 35
                ? Colors.orange
                : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          label: '${value.toInt()}%',
          onChanged: onChanged,
          activeColor: const Color(0xFFEA8E00),
          inactiveColor: const Color(0xFF2F353F),
        ),
      ],
    );
  }


  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: const Color(0xFF3A414B),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, color: Color(0xFFEA8E00)),
          onPressed: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: const Color(0xFFEA8E00),
                      onPrimary: Colors.white,
                      surface: const Color(0xFF2C2F38),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null) {
              setState(() {
                controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
              });
            }
          },
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: const Color(0xFF3A414B),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF2C2F38),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(

            child: Column(
              children: [
                Image.asset(
                  'assets/images/login_logo.png',
                  height: 100,
                ),
                const SizedBox(height: 10),
                Text(
                  '${widget.name} ${widget.lastName} - Gerente',
                  style: const TextStyle(color: Colors.grey,  fontSize: 16),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.person, 'PERFIL', ProfileScreen(name: widget.name, lastName: widget.lastName)),
          _buildDrawerItem(Icons.people, 'TRANSPORTISTAS',
              CarrierProfilesScreen(name: widget.name, lastName: widget.lastName)),
          _buildDrawerItem(Icons.report, 'REPORTES', ReportsScreen(name: widget.name, lastName: widget.lastName)),
          _buildDrawerItem(Icons.directions_car, 'VEHICULOS', VehiclesScreen(name: widget.name, lastName: widget.lastName)),
          _buildDrawerItem(Icons.local_shipping, 'ENVIOS', ShipmentsScreen(name: widget.name, lastName: widget.lastName)),
          const SizedBox(height: 160),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('CERRAR SESIÓN', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pushAndRemoveUntil(
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
                    (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}
