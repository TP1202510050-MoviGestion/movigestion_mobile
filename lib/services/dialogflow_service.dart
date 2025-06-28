// lib/core/services/dialogflow_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';

// Modelo para una respuesta estructurada de Dialogflow
class DialogflowResponse {
  final String text;
  final String? action;
  final Map<String, dynamic> parameters;

  DialogflowResponse({
    required this.text,
    this.action,
    this.parameters = const {},
  });
}

/// Dialogflow ES vía REST (cuenta de servicio)
class DialogflowRestService {
  /* ── singleton ─────────────────────────────────────────────────── */
  DialogflowRestService._internal();
  static final DialogflowRestService _i = DialogflowRestService._internal();
  factory DialogflowRestService() => _i;

  /* ── configuración ─────────────────────────────────────────────── */
  // Asegúrate de que esta ruta sea correcta en tu proyecto
  static const _jsonKey = 'assets/keys/green-source-462801-q9-55866c61f206.json';
  static const _scopes = ['https://www.googleapis.com/auth/cloud-platform'];

  late final String _projectId;
  late final AutoRefreshingAuthClient _client;
  bool _ready = false;

  /* ── inicialización perezosa ───────────────────────────────────── */
  Future<void> _bootstrap() async {
    try {
      final jsonStr = await rootBundle.loadString(_jsonKey);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);

      _projectId = jsonMap['project_id'] as String;
      final credentials = ServiceAccountCredentials.fromJson(jsonStr);

      _client = await clientViaServiceAccount(credentials, _scopes);
      _ready = true;
    } catch (e) {
      print('Error al inicializar DialogflowService: $e');
      rethrow;
    }
  }

  Future<void> _ensureReady() => _ready ? Future.value() : _bootstrap();

  /* ── API pública MODIFICADA ───────────────────────────────────── */
  Future<DialogflowResponse> detectIntent(String text, {String sessionId = 'flutter_session'}) async {
    await _ensureReady();

    final uri = Uri.parse(
      'https://dialogflow.googleapis.com/v2/projects/'
          '$_projectId/agent/sessions/$sessionId:detectIntent',
    );

    final body = jsonEncode({
      'queryInput': {
        'text': {'text': text, 'languageCode': 'es'}
      }
    });

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Dialogflow error ${response.statusCode}: ${response.body}');
    }

    final decodedBody = utf8.decode(response.bodyBytes);
    final data = jsonDecode(decodedBody) as Map<String, dynamic>;
    final queryResult = data['queryResult'] as Map<String, dynamic>?;

    return DialogflowResponse(
      text: queryResult?['fulfillmentText'] as String? ?? '(sin respuesta)',
      action: queryResult?['action'] as String?,
      parameters: queryResult?['parameters'] as Map<String, dynamic>? ?? {},
    );
  }
}