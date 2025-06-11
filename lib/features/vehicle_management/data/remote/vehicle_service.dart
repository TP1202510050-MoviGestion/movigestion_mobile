// lib/features/vehicle_management/data/remote/vehicle_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';
import 'vehicle_model.dart';

class VehicleService {
  Future<List<VehicleModel>> getAllVehicles() async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.vehicle}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) => VehicleModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to load vehicles (status ${response.statusCode})');
    }
  }

  Future<VehicleModel?> getVehicleById(int id) async {
    final url =
    Uri.parse('${AppConstants.baseUrl}${AppConstants.vehicle}/$id');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return VehicleModel.fromJson(json.decode(response.body));
    } else {
      return null;
    }
  }

  Future<bool> createVehicle(VehicleModel vehicle) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.vehicle}');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(vehicle.toJson()),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> updateVehicle(int id, VehicleModel vehicle) async {
    final url =
    Uri.parse('${AppConstants.baseUrl}${AppConstants.vehicle}/$id');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(vehicle.toJson()),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteVehicle(int id) async {
    final url =
    Uri.parse('${AppConstants.baseUrl}${AppConstants.vehicle}/$id');
    final response = await http.delete(url);
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
