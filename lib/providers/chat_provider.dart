// lib/features/chat/providers/chat_provider.dart

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

// --- IMPORTACIONES ABSOLUTAS ---
// Asegúrate de que el nombre del paquete 'movigestion_mobile' sea correcto.
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_model.dart';
import 'package:movigestion_mobile/features/vehicle_management/data/remote/vehicle_service.dart';

import '../features/vehicle_management/data/remote/route_service.dart';
import '../services/dialogflow_service.dart';


class ChatProvider with ChangeNotifier {
  // --- SERVICIOS ---
  final _dialogflowSvc = DialogflowRestService();
  final _routeSvc = RouteService();
  final _vehicleSvc = VehicleService();
  // final _reportSvc = ReportService(); // Descomenta cuando lo necesites

  // --- ESTADO ---
  final List<Map<String, String>> _messages = [];
  List<Map<String, String>> get messages => List.unmodifiable(_messages);

  bool _isBotTyping = false;
  bool get isBotTyping => _isBotTyping;

  // --- MÉTODO PRINCIPAL DE ENVÍO ---
  Future<void> send(String text) async {
    _addMessage(from: 'user', text: text);
    _setBotTyping(true);

    try {
      final response = await _dialogflowSvc.detectIntent(text);

      // --- DISPATCHER DE ACCIONES ---
      switch (response.action) {
      // --- Acciones de Rutas ---
        case 'consultar_rutas_hoy':
          await _handleConsultarRutasHoy(response.parameters);
          break;
        case 'consultar.rutas.estado':
          await _handleConsultarRutasPorEstado(response.parameters);
          break;
        case 'consultar.ruta.conductor':
          await _handleConsultarRutaPorConductor(response.parameters);
          break;

      // --- Acciones de Vehículos ---
        case 'consultar.vehiculo.placa':
          await _handleConsultarVehiculoPorPlaca(response.parameters);
          break;
        case 'consultar.vehiculos.disponibles':
          await _handleConsultarVehiculosDisponibles();
          break;

        default:
        // Si no hay una acción conocida, muestra la respuesta de texto de Dialogflow
          _addMessage(from: 'bot', text: response.text.isEmpty ? "No te he entendido, ¿puedes decirlo de otra forma?" : response.text);
      }
    } catch (e) {
      _addMessage(from: 'bot', text: 'Lo siento, hubo un error técnico. Por favor, inténtalo más tarde.');
      print('Error en ChatProvider: $e'); // Para depuración
    } finally {
      _setBotTyping(false);
    }
  }

  // --- MÉTODOS PRIVADOS DE MANEJO DE ESTADO ---
  void _addMessage({required String from, required String text}) {
    _messages.add({'from': from, 'text': text});
    notifyListeners();
  }

  void _setBotTyping(bool isTyping) {
    _isBotTyping = isTyping;
    notifyListeners();
  }

  // --- MANEJADORES DE ACCIONES (ACTION HANDLERS) ---

  // RUTAS
  Future<void> _handleConsultarRutasHoy(Map<String, dynamic> parameters) async {
    try {
      final allRoutes = await _routeSvc.getAllRoutes();
      final today = DateTime.now();
      final fmtDate = DateFormat('dd/MM/yyyy');

      final routesHoy = allRoutes.where((r) {
        if (r.createdAt == null) return false;
        return r.createdAt!.year == today.year &&
            r.createdAt!.month == today.month &&
            r.createdAt!.day == today.day;
      }).toList();

      if (routesHoy.isEmpty) {
        _addMessage(from: 'bot', text: 'No se encontraron rutas asignadas para hoy, ${fmtDate.format(today)}.');
      } else {
        String botResponse = "Para hoy, ${fmtDate.format(today)}, se han encontrado **${routesHoy.length}** ruta(s):\n\n";
        for (var route in routesHoy) {
          botResponse += "• **${route.customer}**: Asignada a _${route.driverName}_. Estado: **${route.status}**.\n";
        }
        _addMessage(from: 'bot', text: botResponse);
      }
    } catch(e) {
      _addMessage(from: 'bot', text: 'Tuve problemas para consultar las rutas en el sistema.');
    }
  }

  Future<void> _handleConsultarRutasPorEstado(Map<String, dynamic> parameters) async {
    final estado = parameters['estado'] as String?;
    if (estado == null || estado.isEmpty) {
      _addMessage(from: 'bot', text: 'Por favor, especifica un estado (ej. "en camino", "finalizadas").');
      return;
    }

    try {
      final allRoutes = await _routeSvc.getAllRoutes();
      final filteredRoutes = allRoutes.where((r) => r.status.toLowerCase().replaceAll('_', ' ') == estado.toLowerCase()).toList();

      if (filteredRoutes.isEmpty) {
        _addMessage(from: 'bot', text: 'No se encontraron rutas con el estado **"$estado"**.');
      } else {
        String response = "He encontrado **${filteredRoutes.length}** ruta(s) con estado **'$estado'**:\n\n";
        for (var route in filteredRoutes) {
          response += "• **${route.customer}**: De ${route.waypoints.first.name} a ${route.waypoints.last.name}.\n";
        }
        _addMessage(from: 'bot', text: response);
      }
    } catch(e) {
      _addMessage(from: 'bot', text: 'No pude consultar las rutas. Error: $e');
    }
  }

  Future<void> _handleConsultarRutaPorConductor(Map<String, dynamic> parameters) async {
    final conductorParam = parameters['person'] as Map<String, dynamic>?;
    final conductor = conductorParam?['name'] as String?;

    if (conductor == null || conductor.isEmpty) {
      _addMessage(from: 'bot', text: 'Por favor, dime el nombre del conductor que quieres consultar.');
      return;
    }

    try {
      final allRoutes = await _routeSvc.getAllRoutes();
      final activeRoute = allRoutes.firstWhere(
            (r) => r.driverName?.toLowerCase() == conductor.toLowerCase() && (r.status.toLowerCase() == 'asignado' || r.status.toLowerCase().contains('camino')),
        orElse: () => throw Exception('No se encontró ruta activa'),
      );

      String response = "La ruta activa de **$conductor** es para el cliente **${activeRoute.customer}**.\n\n"
          "• **Estado actual:** ${activeRoute.status}\n"
          "• **Origen:** ${activeRoute.waypoints.first.name}\n"
          "• **Destino:** ${activeRoute.waypoints.last.name}";
      _addMessage(from: 'bot', text: response);
    } catch (e) {
      _addMessage(from: 'bot', text: 'No encontré ninguna ruta activa para **$conductor**.');
    }
  }

  // VEHÍCULOS
  Future<void> _handleConsultarVehiculoPorPlaca(Map<String, dynamic> parameters) async {
    final placa = parameters['placa'] as String?;
    if (placa == null || placa.isEmpty) {
      _addMessage(from: 'bot', text: 'Por favor, indícame la placa que deseas consultar.');
      return;
    }

    final RegExp placaRegExp = RegExp(r'^[A-Z0-9]{3}-?[A-Z0-9]{3}$', caseSensitive: false);
    if (!placaRegExp.hasMatch(placa)) {
      _addMessage(from: 'bot', text: 'El formato de la placa "$placa" no parece correcto. Inténtalo de nuevo, por ejemplo: "ABC-123".');
      return;
    }

    try {
      final allVehicles = await _vehicleSvc.getAllVehicles();
      final vehicle = allVehicles.firstWhere(
            (v) => v.licensePlate.toLowerCase().replaceAll('-', '') == placa.toLowerCase().replaceAll('-', ''),
        orElse: () => throw Exception('No encontrado'),
      );

      String response = "Detalles del vehículo con placa **${vehicle.licensePlate}**:\n\n"
          "• **Marca/Modelo:** ${vehicle.brand} ${vehicle.model} (${vehicle.year})\n"
          "• **Estado:** ${vehicle.status}\n"
          "• **Asignado a:** ${vehicle.driverName ?? 'Ningún conductor'}\n";

      if (vehicle.lastTechnicalInspectionDate != null) {
        response += "• **Próxima Rev. Técnica:** ${DateFormat('dd/MM/yyyy').format(vehicle.lastTechnicalInspectionDate!)}";
      }

      _addMessage(from: 'bot', text: response);

    } catch (e) {
      _addMessage(from: 'bot', text: 'No pude encontrar ningún vehículo con la placa **$placa**.');
    }
  }

  Future<void> _handleConsultarVehiculosDisponibles() async {
    try {
      final allVehicles = await _vehicleSvc.getAllVehicles();
      final availableVehicles = allVehicles.where((v) => v.assignedDriverId == null).toList();

      if (availableVehicles.isEmpty) {
        _addMessage(from: 'bot', text: 'Actualmente no hay vehículos disponibles. Todos están asignados.');
      } else {
        String response = "He encontrado **${availableVehicles.length}** vehículo(s) disponible(s):\n\n";
        for (var vehicle in availableVehicles) {
          response += "• Placa **${vehicle.licensePlate}** (${vehicle.brand} ${vehicle.model})\n";
        }
        _addMessage(from: 'bot', text: response);
      }
    } catch (e) {
      _addMessage(from: 'bot', text: 'Tuve problemas para consultar la flota de vehículos.');
    }
  }
}