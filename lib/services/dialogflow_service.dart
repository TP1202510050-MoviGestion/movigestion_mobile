// lib/features/chat/services/dialogflow_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Representa la respuesta simplificada de nuestro webhook.
/// Ahora incluye un campo opcional para datos estructurados (payload).
class DialogflowResponse {
  /// El texto de respuesta principal para mostrar como texto simple.
  final String text;
  /// Un mapa opcional con datos estructurados para renderizar widgets personalizados.
  final Map<String, dynamic>? payload;

  DialogflowResponse({ required this.text, this.payload });
}

/// Servicio para interactuar DIRECTAMENTE con nuestro Webhook en Azure.
class DialogflowRestService {
  /* ── Singleton Pattern ─────────────────────────────────────────────────── */
  DialogflowRestService._internal();
  static final DialogflowRestService _i = DialogflowRestService._internal();
  factory DialogflowRestService() => _i;

  // --- CONFIGURACIÓN ---
  final String _webhookUrl = 'https://app-250626000818.azurewebsites.net/api/dialogflow-webhook';
  final String _projectId = 'green-source-462801-q9';

  /// Envía una consulta de texto a nuestro webhook.
  Future<DialogflowResponse> detectIntent(String text, {required Map<String, dynamic> queryParams, String sessionId = 'flutter_session'}) async {
    // Lógica simple para adivinar el intent basado en palabras clave
    String intentName = "AnalisisGeneral";
    if (text.contains("ruta")) intentName = "ConsultarRutas";
    if (text.contains("reporte") || text.contains("incidente")) intentName = "ConsultarReportes";
    if (text.contains("vehículo") || text.contains("flota")) intentName = "ConsultarVehiculos";

    final requestBody = {
      "queryResult": {
        "queryText": text,
        "intent": { "displayName": intentName },
        "queryParams": { "payload": queryParams }
      },
      "session": "projects/$_projectId/agent/sessions/$sessionId"
    };

    return _sendRequest(requestBody);
  }

  /// Envía un evento a nuestro webhook para iniciar la conversación.
  Future<DialogflowResponse> detectEvent(String eventName, {required Map<String, dynamic> parameters, String sessionId = 'flutter_session'}) async {
    final requestBody = {
      "queryResult": {
        "intent": { "displayName": eventName },
        "outputContexts": [{
          "name": "projects/$_projectId/agent/sessions/$sessionId/contexts/evento-bienvenida-app",
          "parameters": parameters
        }]
      },
      "session": "projects/$_projectId/agent/sessions/$sessionId"
    };

    return _sendRequest(requestBody);
  }

  /// Método base para enviar la petición POST a nuestro webhook y parsear la respuesta.
  Future<DialogflowResponse> _sendRequest(Map<String, dynamic> requestBody) async {
    try {
      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        debugPrint('Webhook API Error (${response.statusCode}): ${response.body}');
        throw Exception('Error en la comunicación con el webhook.');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final fulfillmentMessages = data['fulfillmentMessages'] as List<dynamic>?;

      String fulfillmentText = '(sin respuesta del asistente)';
      Map<String, dynamic>? payload;

      if (fulfillmentMessages != null && fulfillmentMessages.isNotEmpty) {
        final firstMessage = fulfillmentMessages.first as Map<String, dynamic>;

        // --- LÓGICA DE EXTRACCIÓN MEJORADA ---
        if (firstMessage.containsKey('payload')) {
          // Si hay un payload, lo extraemos.
          payload = firstMessage['payload'] as Map<String, dynamic>;
          // Usamos un texto genérico, ya que la UI se construirá a partir del payload.
          fulfillmentText = "Aquí tienes la información que solicitaste:";
        } else if (firstMessage.containsKey('text')) {
          // Si no hay payload, extraemos el texto simple.
          final textData = firstMessage['text'] as Map<String, dynamic>?;
          final textList = textData?['text'] as List<dynamic>?;
          if (textList != null && textList.isNotEmpty) {
            fulfillmentText = textList.first as String;
          }
        }
      }

      return DialogflowResponse(
        text: fulfillmentText,
        payload: payload,
      );

    } catch (e) {
      debugPrint('Error en _sendRequest: $e');
      return DialogflowResponse(text: '(Error de conexión con el asistente)');
    }
  }
}