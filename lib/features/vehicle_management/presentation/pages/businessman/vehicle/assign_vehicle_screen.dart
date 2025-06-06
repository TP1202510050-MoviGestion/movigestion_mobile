import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/profile/profile_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/shipments/shipments_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/vehicle/vehicles_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/reports/reports_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/login_register/login_screen.dart';
import 'package:movigestion_mobile/features/vehicle_management/presentation/pages/businessman/carrier_profiles/carrier_profiles.dart';

class AssignVehicleScreen extends StatefulWidget {
  final Function(Map<String, String>) onVehicleAdded;
  final String name;
  final String lastName;

  const AssignVehicleScreen({
    Key? key,
    required this.onVehicleAdded,
    required this.name,
    required this.lastName,
  }) : super(key: key);

  @override
  _AssignVehicleScreenState createState() => _AssignVehicleScreenState();
}

class _AssignVehicleScreenState extends State<AssignVehicleScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController plateController = TextEditingController();
  final TextEditingController assignedDriverController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController lastInspectionDateController = TextEditingController();
  final VehicleService vehicleService = VehicleService();

  String? _selectedImageBase64;
  double engineValue = 50;
  double fuelValue = 50;
  double tiresValue = 50;
  double electricalSystemValue = 50;
  double transmissionTempValue = 50;

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedImageBase64 = base64Encode(result.files.single.bytes!);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imagen seleccionada y convertida a base64',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se seleccionó ninguna imagen',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _createVehicle() async {
    if (_formKey.currentState!.validate()) {
      final vehicle = VehicleModel(
        id: 0,
        userId: 1,
        licensePlate: plateController.text,
        model: modelController.text,
        engine: engineValue.toInt(),
        fuel: fuelValue.toInt(),
        tires: tiresValue.toInt(),
        electricalSystem: electricalSystemValue.toInt(),
        transmissionTemperature: transmissionTempValue.toInt(),
        driverName: assignedDriverController.text,
        vehicleImage: _selectedImageBase64 ?? '',
        color: colorController.text,
        lastTechnicalInspectionDate: DateFormat('yyyy-MM-dd').parse(lastInspectionDateController.text),
        createdAt: DateTime.now(),
      );

      try {
        final success = await vehicleService.createVehicle(vehicle);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehículo asignado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al asignar el vehículo'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al enviar la solicitud: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2F38),
        title: const Text(
          'Asignar Vehículo',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1E1F24),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionContainer(_buildTextField('Modelo del vehículo', modelController)),
              const SizedBox(height: 15),
              _buildSectionContainer(_buildTextField('Placa del vehículo', plateController)),
              const SizedBox(height: 15),
              _buildSectionContainer(_buildTextField('Conductor asignado', assignedDriverController)),
              const SizedBox(height: 15),
              _buildSectionContainer(_buildSliderField('Porcentaje de Motor', engineValue, (value) {
                setState(() {
                  engineValue = value;
                });
              })),
              const SizedBox(height: 15),
              _buildSectionContainer(_buildSliderField('Porcentaje de Combustible', fuelValue, (value) {
                setState(() {
                  fuelValue = value;
                });
              })),
              const SizedBox(height: 15),
              _buildSectionContainer(_buildSliderField('Porcentaje de Neumáticos', tiresValue, (value) {
                setState(() {
                  tiresValue = value;
                });
              })),
              const SizedBox(height: 15),
              _buildSectionContainer(_buildSliderField('Porcentaje del Sistema Eléctrico', electricalSystemValue, (value) {
                setState(() {
                  electricalSystemValue = value;
                });
              })),
              const SizedBox(height: 15),
              _buildSectionContainer(_buildSliderField('Temperatura de Transmisión', transmissionTempValue, (value) {
                setState(() {
                  transmissionTempValue = value;
                });
              })),
              const SizedBox(height: 15),
              _buildSectionContainer(_buildTextField('Color del vehículo', colorController)),
              const SizedBox(height: 15),
              _buildSectionContainer(_buildDateField('Fecha de última inspección', lastInspectionDateController)),
              const SizedBox(height: 20),
              _buildImagePicker(),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _createVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA8E00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Asignar Vehículo',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
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
          style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
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
          borderRadius: BorderRadius.circular(15),
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
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        filled: true,
        fillColor: const Color(0xFF3A414B),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, ingrese $label';
        }
        return null;
      },
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subir imagen del vehículo',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        _selectedImageBase64 == null
            ? ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.upload, color: Colors.white),
          label: const Text('Seleccionar Imagen', style: TextStyle(color: Colors.black)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEA8E00),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        )
            : Column(
          children: [
            Image.memory(
              base64Decode(_selectedImageBase64!),
              height: 150,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('Cambiar Imagen', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA8E00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ],
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
          _buildDrawerItem(Icons.directions_car, 'VEHÍCULOS', VehiclesScreen(name: widget.name, lastName: widget.lastName)),
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
