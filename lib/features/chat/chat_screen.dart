// lib/features/chat/presentation/pages/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_drawer2.dart';
import '../../providers/chat_provider.dart';
import '../../services/dialogflow_service.dart'; // Importante para DialogflowResponse

/* --- Constantes de Estilo --- */
const _kBg = Color(0xFF1E1F24);
const _kSurface = Color(0xFF2C2F38);
const _kBubbleMe = Color(0xFF3C4250);
const _kBubbleBot = Color(0xFF2A2D35);
const _kAccent = Color(0xFFEA8E00);
const _kTextMain = Colors.white;
const _kTextSub = Colors.white70;
const _kRadius = 14.0;

class ChatScreen extends StatefulWidget {
  final String userName;
  final String userLastName;
  final String userType;
  final String? companyName;
  final String? companyRuc;

  const ChatScreen({
    super.key,
    required this.userName,
    required this.userLastName,
    required this.userType,
    this.companyName,
    this.companyRuc,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final chatProvider = context.read<ChatProvider>();
        final userParams = {
          'name': widget.userName,
          'lastName': widget.userLastName,
          'type': widget.userType,
          'companyName': widget.companyName ?? '',
          'companyRuc': widget.companyRuc ?? '',
        };
        chatProvider.initializeChat(userParams);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      context.read<ChatProvider>().send(text);
      _textController.clear();
      FocusScope.of(context).unfocus();
    }
  }


  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: const Text('Asistente Virtual', style: TextStyle(color: _kTextMain)),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: _kTextMain),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: widget.userType == 'Gerente'
          ? AppDrawer(
        name: widget.userName,
        lastName: widget.userLastName,
        companyName: widget.companyName ?? '',
        companyRuc: widget.companyRuc ?? '',
      )
          : AppDrawer2(
        name: widget.userName,
        lastName: widget.userLastName,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: chatProvider.scrollController,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              itemCount: chatProvider.messages.length,
              itemBuilder: (_, i) {
                final message = chatProvider.messages[i];
                return _ChatMessageBubble(
                  isUser: message['from'] == 'user',
                  message: message['text']!,
                  payload: message['payload'] as Map<String, dynamic>?,
                );
              },
            ),
          ),
          if (chatProvider.isBotTyping)
            const _TypingIndicator(),
          _ChatInputField(
            controller: _textController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
// --- WIDGETS INTERNOS REUTILIZABLES ---

class _ChatMessageBubble extends StatelessWidget {
  final bool isUser;
  final String message;
  final Map<String, dynamic>? payload; // Recibimos el payload

  const _ChatMessageBubble({
    required this.isUser,
    required this.message,
    this.payload,
  });

  @override
  Widget build(BuildContext context) {
    // Si el mensaje es del usuario, siempre es una burbuja de texto simple.
    if (isUser) {
      return _buildTextBubble(context);
    }

    // Si es del bot, revisamos si tiene un payload para renderizar un widget especial.
    if (payload != null) {
      switch (payload!['type']) {
        case 'summary_card':
          return _SummaryCard(data: payload!);
        case 'list_card':
          return _ListCard(data: payload!);
      // Puedes añadir más 'case' para otros tipos de tarjetas en el futuro.
      }
    }

    // Si no hay payload o el tipo no se reconoce, muestra una burbuja de texto normal.
    return _buildTextBubble(context);
  }

  // Widget para la burbuja de texto estándar
  Widget _buildTextBubble(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? _kBubbleMe : _kBubbleBot,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(_kRadius),
            topRight: const Radius.circular(_kRadius),
            bottomLeft: Radius.circular(isUser ? _kRadius : 4),
            bottomRight: Radius.circular(isUser ? 4 : _kRadius),
          ),
        ),
        child: MarkdownBody(
          data: message.replaceAll('\n', '  \n'),
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: const TextStyle(color: _kTextMain, fontSize: 15, height: 1.5),
            strong: const TextStyle(fontWeight: FontWeight.bold, color: _kAccent),
            listBullet: const TextStyle(color: _kTextMain, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final sections = (data['sections'] as List? ?? []).cast<Map<String, dynamic>>();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kBubbleBot,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections.map((section) => _SummarySection(section: section)).toList(),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final Map<String, dynamic> section;
  const _SummarySection({required this.section});

  @override
  Widget build(BuildContext context) {
    final items = (section['items'] as List? ?? []).cast<Map<String, dynamic>>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_getIconFor(section['icon']?.toString()), style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(section['title']?.toString() ?? 'Sección', style: const TextStyle(color: _kTextMain, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => _SummaryItem(item: item)),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const _SummaryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getIconFor(item['icon']?.toString()), style: TextStyle(color: _getColorFor(item['icon']?.toString()))),
          const SizedBox(width: 10),
          Expanded(child: Text(item['text']?.toString() ?? '', style: const TextStyle(color: _kTextSub, height: 1.4))),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ListCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Resultados';
    final items = (data['items'] as List? ?? []).cast<Map<String, dynamic>>();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: _kBubbleBot,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kSurface.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(title, style: const TextStyle(color: _kTextMain, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(color: _kSurface, height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => _ListItem(item: items[index]),
            separatorBuilder: (context, index) => const Divider(color: _kSurface, height: 1),
          ),
        ],
      ),
    );
  }
}
class _ListItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ListItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final details = (item['Detalles'] as List? ?? []).cast<Map<String, dynamic>>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item['Título']?.toString() ?? '', style: const TextStyle(color: _kAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          if (item['Subtítulo'] != null && item['Subtítulo'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(item['Subtítulo'].toString(), style: const TextStyle(color: _kTextSub)),
            ),
          const SizedBox(height: 10),
          ...details.map((detail) => _DetailRow(
            icon: _getDetailIcon(detail['icon']?.toString()),
            label: detail['key']?.toString() ?? '',
            value: detail['value']?.toString() ?? 'N/A',
          )),
        ],
      ),
    );
  }

  IconData _getDetailIcon(String? iconName) {
    switch (iconName) {
      case 'status': return Icons.label_important_outline;
      case 'driver': return Icons.person_outline;
      case 'vehicle': return Icons.directions_car_outlined;
      case 'time': return Icons.schedule_outlined;
      case 'date': return Icons.calendar_today_outlined;
      case 'type': return Icons.category_outlined;
      case 'telemetry': return Icons.gps_fixed;
      default: return Icons.info_outline;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _kTextSub, size: 16),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: _kTextSub)),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(color: _kTextMain, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

// --- FUNCIONES HELPER GLOBALES (FUERA DE LAS CLASES) ---

String _getIconFor(String? iconName) {
  switch (iconName) {
    case 'route': return '📍';
    case 'total': return '🟢';
    case 'regular':
    case 'event': return '🔹';
    case 'report': return '🔴';
    case 'traffic': return '📌';
    case 'accident': return '📌';
    case 'location': return '🚚';
    case 'vehicle_ok': return '🔹';
    case 'vehicle_warning': return '⚠️';
    default: return '▪️';
  }
}

Color _getColorFor(String? iconName) {
  if (iconName == 'vehicle_warning') {
    return Colors.amber;
  }
  return _kTextSub;
}

IconData _getDetailIcon(String? iconName) {
  switch (iconName) {
    case 'status': return Icons.label_important_outline;
    case 'driver': return Icons.person_outline;
    case 'vehicle': return Icons.directions_car_outlined;
    case 'time': return Icons.schedule_outlined;
    case 'date': return Icons.calendar_today_outlined;
    case 'type': return Icons.category_outlined;
    case 'telemetry': return Icons.gps_fixed;
    default: return Icons.info_outline;
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
        decoration: const BoxDecoration(
            color: _kSurface,
            border: Border(top: BorderSide(color: Colors.black12, width: 1.0))
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: const TextStyle(color: _kTextMain),
                decoration: InputDecoration(
                  hintText: 'Escribe tu mensaje…',
                  hintStyle: const TextStyle(color: _kTextSub),
                  filled: true,
                  fillColor: _kBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _kAccent,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: onSend,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.send, color: Colors.black, size: 22),
                ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
            ),
            const SizedBox(width: 12),
            Text('Asistente está escribiendo...', style: TextStyle(color: _kTextSub)),
          ],
        ),
      ),
    );
  }
}