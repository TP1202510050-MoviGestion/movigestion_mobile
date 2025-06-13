// lib/features/vehicle_management/data/remote/route_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movigestion_mobile/core/app_constants.dart';
import 'route_model.dart';

class RouteService {
  /* -------------------- READ -------------------- */
  Future<List<RouteModel>> getAllRoutes() async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.route}');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List<dynamic>;
      return data.map((e) => RouteModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load routes (status ${res.statusCode})');
  }

  Future<RouteModel?> getRouteById(int id) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.route}/$id');
    final res = await http.get(url);
    return res.statusCode == 200 ? RouteModel.fromJson(json.decode(res.body)) : null;
  }

  /* -------------------- CREATE -------------------- */
  Future<bool> createRoute(RouteModel route) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.route}');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(route.toJson()),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  /* -------------------- UPDATE -------------------- */
  Future<bool> updateRoute(int id, RouteModel route) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.route}/$id');
    final res = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(route.toJson()),
    );
    return res.statusCode == 200;
  }

  /* -------------------- DELETE -------------------- */
  Future<bool> deleteRoute(int id) async {
    final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.route}/$id');
    final res = await http.delete(url);
    return res.statusCode == 200 || res.statusCode == 204;
  }
}
