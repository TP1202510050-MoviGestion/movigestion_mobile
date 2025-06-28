// lib/features/chat/presentation/pages/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';

/* --- Colores --- */
const _kBg = Color(0xFF1E1F24);
const _kSurface = Color(0xFF2C2F38);
const _kBubbleMe = Color(0xFF3C4250);
const _kBubbleBot = Color(0xFF2A2D35);
const _kAccent = Color(0xFFEA8E00);
const _kTextMain = Colors.white;
const _kTextSub = Colors.white70;
const _kRadius = 14.0;

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

    // Llama al provider para que maneje la lógica de envío
    context.read<ChatProvider>().send(txt);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final msgs = chatProvider.messages;

    // Lógica para hacer scroll al final cada vez que la lista de mensajes cambia.
    // Se ejecuta después de que el frame se ha construido.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: const Text('Asistente Virtual', style: TextStyle(color: _kTextMain)),
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
                final m = msgs[i];
                final isUser = m['from'] == 'user';

                return _ChatMessageBubble(
                  isUser: isUser,
                  message: m['text']!,
                );
              },
            ),
          ),

          if (chatProvider.isBotTyping)
            const _TypingIndicator(),

          _ChatInputField(
            controller: _controller,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// --- WIDGETS INTERNOS ---

class _ChatMessageBubble extends StatelessWidget {
  final bool isUser;
  final String message;

  const _ChatMessageBubble({required this.isUser, required this.message});

  @override
  Widget build(BuildContext context) {
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? _kBubbleMe : _kBubbleBot;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(_kRadius),
            topRight: const Radius.circular(_kRadius),
            bottomLeft: Radius.circular(isUser ? _kRadius : 4),
            bottomRight: Radius.circular(isUser ? 4 : _kRadius),
          ),
        ),
        child: isUser
            ? SelectableText(
          message,
          style: const TextStyle(color: _kTextMain, height: 1.4),
        )
            : MarkdownBody(
          data: message,
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: const TextStyle(color: _kTextMain, height: 1.4, fontSize: 15),
            strong: const TextStyle(fontWeight: FontWeight.bold, color: _kTextMain),
            em: const TextStyle(fontStyle: FontStyle.italic, color: _kTextSub),
          ),
        ),
      ),
    );
  }
}


class _ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInputField({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        color: _kSurface,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: const TextStyle(color: _kTextMain),
                decoration: InputDecoration(
                  hintText: 'Escribe tu mensaje…',
                  hintStyle: const TextStyle(color: _kTextSub),
                  filled: true,
                  fillColor: _kBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSend,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kAccent,
                ),
                child: const Icon(Icons.send, color: Colors.black, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
            ),
            SizedBox(width: 12),
            Text('Asistente está escribiendo...', style: TextStyle(color: _kTextSub)),
          ],
        ),
      ),
    );
  }
}