// lib/features/vehicle_management/data/remote/route_repository.dart
import '../remote/route_model.dart';
import '../remote/route_service.dart';

class RouteRepository {
  final RouteService routeService;
  RouteRepository({required this.routeService});

  Future<List<RouteModel>> getAllRoutes() => routeService.getAllRoutes();
  Future<RouteModel?>     getRouteById(int id) => routeService.getRouteById(id);
  Future<bool> createRoute(RouteModel r) => routeService.createRoute(r);
  Future<bool> updateRoute(int id, RouteModel r) => routeService.updateRoute(id, r);
  Future<bool> deleteRoute(int id) => routeService.deleteRoute(id);
}
