import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Dialogflow ES vía REST (cuenta de servicio)
class DialogflowRestService {
  /* ── singleton ─────────────────────────────────────────────────── */
  DialogflowRestService._internal();
  static final DialogflowRestService _i = DialogflowRestService._internal();
  factory DialogflowRestService() => _i;

  /* ── configuración ─────────────────────────────────────────────── */
  static const _jsonKey =
      'assets/keys/green-source-462801-q9-55866c61f206.json';
  static const _scopes = ['https://www.googleapis.com/auth/cloud-platform'];

  late final String _projectId;
  late final AutoRefreshingAuthClient _client;
  bool _ready = false;

  /* ── inicialización perezosa ───────────────────────────────────── */
  Future<void> _bootstrap() async {
    // 1 · lee el JSON de la cuenta
    final jsonStr = await rootBundle.loadString(_jsonKey);
    final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);

    _projectId = jsonMap['project_id'] as String;
    final credentials = ServiceAccountCredentials.fromJson(jsonStr);

    // 2 · obtiene el cliente autenticado
    _client = await clientViaServiceAccount(credentials, _scopes);
    _ready = true;
  }

  Future<void> _ensureReady() => _ready ? Future.value() : _bootstrap();

  /* ── API pública ───────────────────────────────────────────────── */
  Future<String> detectIntent(String text, {String sessionId = 'flutter'}) async {
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
      throw Exception(
        'Dialogflow error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['queryResult']?['fulfillmentText'] as String? ??
        '(sin respuesta)';
  }
}
