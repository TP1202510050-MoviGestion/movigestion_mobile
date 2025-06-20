// lib/features/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';

/// ─── Colores corporativos ──────────────────────────────────────────────────
const _kBg       = Color(0xFF1E1F24);
const _kSurface  = Color(0xFF2C2F38);
const _kBubbleMe = Color(0xFF3C4250);      // burbuja usuario
const _kBubbleBot = Color(0xFF2A2D35);     // burbuja bot
const _kAccent   = Color(0xFFEA8E00);      // acento naranja
const _kTextMain = Colors.white;
const _kTextSub  = Colors.white70;
const _kRadius   = 14.0;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  void _send() {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;

    context.read<ChatProvider>().send(txt);
    _controller.clear();

    // Desplazar al final cuando termine de construir la respuesta
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final msgs = context.watch<ChatProvider>().messages;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: const Text('Asistente', style: TextStyle(color: _kTextMain)),
        iconTheme: const IconThemeData(color: _kTextMain),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final m      = msgs[i];
                final isUser = m['from'] == 'user';
                final align  = isUser ? Alignment.centerRight : Alignment.centerLeft;
                final color  = isUser ? _kBubbleMe : _kBubbleBot;
                final textAl = isUser ? TextAlign.right : TextAlign.left;

                return Align(
                  alignment: align,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 260),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.only(
                        topLeft : const Radius.circular(_kRadius),
                        topRight: const Radius.circular(_kRadius),
                        bottomLeft : Radius.circular(isUser ? _kRadius : 4),
                        bottomRight: Radius.circular(isUser ? 4 : _kRadius),
                      ),
                    ),
                    child: Text(
                      m['text']!,
                      textAlign: textAl,
                      style: const TextStyle(color: _kTextMain, height: 1.3),
                    ),
                  ),
                );
              },
            ),
          ),

          // ─── Barra de entrada ──────────────────────────────────────────────
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              color: _kSurface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: const TextStyle(color: _kTextMain),
                      decoration: InputDecoration(
                        hintText: 'Escribe tu mensaje…',
                        hintStyle: const TextStyle(color: _kTextSub),
                        filled: true,
                        fillColor: _kBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kAccent,
                      ),
                      child: const Icon(Icons.send, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
