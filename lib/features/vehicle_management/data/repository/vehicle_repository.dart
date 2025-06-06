import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_model.dart';

class VehicleRepository {
  final VehicleService vehicleService;

  VehicleRepository({required this.vehicleService});

  Future<List<VehicleModel>> getAllVehicles() async {
    return await vehicleService.getAllVehicles();
  }

  Future<VehicleModel?> getVehicleById(int id) async {
    return await vehicleService.getVehicleById(id);
  }

  Future<bool> createVehicle(VehicleModel vehicle) async {
    return await vehicleService.createVehicle(vehicle);
  }

  Future<bool> updateVehicle(int id, VehicleModel vehicle) async {
    return await vehicleService.updateVehicle(id, vehicle);
  }

  Future<bool> deleteVehicle(int id) async {
    return await vehicleService.deleteVehicle(id);
  }
}
