import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';
import 'vehicle_model.dart';

class VehicleService {
  Future<List<VehicleModel>> getAllVehicles() async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.vehicle}');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => VehicleModel.fromJson(json)).toList();
      } else {
        print('Failed to load vehicles. Status code: ${response.statusCode}');
        throw Exception('Failed to load vehicles');
      }
    } catch (e) {
      print('Error fetching vehicles: $e');
      rethrow;
    }
  }

  Future<VehicleModel?> getVehicleById(int id) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.vehicle}/$id');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return VehicleModel.fromJson(json.decode(response.body));
      } else {
        print('Failed to load vehicle. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching vehicle by ID: $e');
      return null;
    }
  }

  Future<bool> createVehicle(VehicleModel vehicle) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.vehicle}');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(vehicle.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to create vehicle. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error creating vehicle: $e');
      return false;
    }
  }


  Future<bool> updateVehicle(int id, VehicleModel vehicle) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.vehicle}/$id');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(vehicle.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating vehicle: $e');
      return false;
    }
  }


  Future<bool> deleteVehicle(int id) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.vehicle}/$id');
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to delete vehicle. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting vehicle: $e');
      return false;
    }
  }
}
