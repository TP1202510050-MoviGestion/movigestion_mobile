import 'package:movigestion_mobile/features/vehicle_management/data/remote/shipment_service.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/shipment_model.dart';

class ShipmentRepository {
  final ShipmentService shipmentService;

  ShipmentRepository({required this.shipmentService});

  Future<List<ShipmentModel>> getAllShipments() async {
    return await shipmentService.getAllShipments();
  }

  Future<ShipmentModel?> getShipmentById(int id) async {
    return await shipmentService.getShipmentById(id);
  }

  Future<bool> createShipment(ShipmentModel shipment) async {
    return await shipmentService.createShipment(shipment);
  }

  Future<bool> deleteShipment(int id) async {
    return await shipmentService.deleteShipment(id);
  }
  Future<bool> updateShipmentStatus(int id, String status) async {
    return await shipmentService.updateShipmentStatus(id, status);
  }

}
