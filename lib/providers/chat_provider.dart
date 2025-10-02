// lib/features/chat/providers/chat_provider.dart

import 'package:flutter/material.dart';
import '../services/dialogflow_service.dart';

class ChatProvider with ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  final _dialogflowSvc = DialogflowRestService();
  final List<Map<String, dynamic>> _messages = []; // Cambiamos el tipo a dynamic


  bool _isBotTyping = false;
  Map<String, dynamic> _userParams = {};
  bool _isInitialized = false;

  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);  bool get isBotTyping => _isBotTyping;

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> initializeChat(Map<String, dynamic> parameters) async {
    if (_isInitialized) return;
    _isInitialized = true;
    _userParams = parameters;
    _messages.clear();
    _setBotTyping(true);
    notifyListeners();

    debugPrint("[FLUTTER DEBUG] ChatProvider.initializeChat: Iniciando con params: $_userParams");

    try {
      final response = await _dialogflowSvc.detectEvent('Evento-Bienvenida-App', parameters: _userParams);
      debugPrint("[FLUTTER DEBUG] ChatProvider.initializeChat: Respuesta recibida -> '${response.text}'");
      _addMessage(from: 'bot', text: response.text);
    } catch (e) {
      debugPrint("[FLUTTER DEBUG] ChatProvider.initializeChat: ERROR -> $e");
      _addMessage(from: 'bot', text: 'Lo siento, no pude conectarme con el asistente.');
    } finally {
      _setBotTyping(false);
    }
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    _addMessage(from: 'user', text: text);
    _setBotTyping(true);

    debugPrint("[FLUTTER DEBUG] ChatProvider.send: Enviando texto con params: $_userParams");

    try {
      final response = await _dialogflowSvc.detectIntent(text, queryParams: _userParams);
      debugPrint("[FLUTTER DEBUG] ChatProvider.send: Respuesta recibida -> '${response.text}'");
      final responseText = response.text.isEmpty ? "No te he entendido." : response.text;
      _addMessage(from: 'bot', text: responseText, payload: response.payload);
    } catch (e) {
      debugPrint("[FLUTTER DEBUG] ChatProvider.send: ERROR -> $e");
      _addMessage(from: 'bot', text: 'Lo siento, hubo un error técnico.');
    } finally {
      _setBotTyping(false);
    }
  }

  void disposeChat() {
    _messages.clear();
    _isInitialized = false;
    _userParams = {};
  }

  void clearChat() {
    _messages.clear();
    _isInitialized = false;
    _userParams = {};
    notifyListeners(); // Notificar para que la UI se limpie si sigue visible
  }




  // Modificamos _addMessage para aceptar el payload opcional
  void _addMessage({required String from, required String text, Map<String, dynamic>? payload}) {
    _messages.add({'from': from, 'text': text, 'payload': payload});
    _scrollToBottom();
    notifyListeners();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _setBotTyping(bool isTyping) {
    if (_isBotTyping == isTyping) return;
    _isBotTyping = isTyping;
    notifyListeners();
  }
}