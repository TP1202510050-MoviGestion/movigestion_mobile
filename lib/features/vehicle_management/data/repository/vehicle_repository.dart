// lib/features/vehicle_management/data/remote/vehicle_repository.dart

import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_service.dart';

class VehicleRepository {
  final VehicleService vehicleService;

  VehicleRepository({required this.vehicleService});

  Future<List<VehicleModel>> getAllVehicles() =>
      vehicleService.getAllVehicles();

  Future<VehicleModel?> getVehicleById(int id) =>
      vehicleService.getVehicleById(id);

  Future<bool> createVehicle(VehicleModel vehicle) =>
      vehicleService.createVehicle(vehicle);

  Future<bool> updateVehicle(int id, VehicleModel vehicle) =>
      vehicleService.updateVehicle(id, vehicle);

  Future<bool> deleteVehicle(int id) => vehicleService.deleteVehicle(id);
}
