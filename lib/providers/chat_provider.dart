import 'package:flutter/foundation.dart';
import '../services/dialogflow_service.dart';

class ChatProvider with ChangeNotifier {
  final _svc = DialogflowRestService();

  final List<Map<String,String>> _messages = [];
  List<Map<String,String>> get messages => List.unmodifiable(_messages);

  Future<void> send(String text) async {
    _messages.add({'from':'user','text':text});
    notifyListeners();

    final reply = await _svc.detectIntent(text);
    _messages.add({'from':'bot','text':reply});
    notifyListeners();
  }
}
