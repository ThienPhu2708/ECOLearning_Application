import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../data/repositories/teacher_chat_repository.dart';

/// Image bytes are requested with the authenticated client, never cached on disk.
class ChatMedia extends StatefulWidget {
  final int messageId;
  final TeacherChatRepository repository;
  const ChatMedia({
    super.key,
    required this.messageId,
    required this.repository,
  });
  @override
  State<ChatMedia> createState() => _ChatMediaState();
}

class _ChatMediaState extends State<ChatMedia> {
  late Future<Uint8List> _bytes = widget.repository.image(widget.messageId);
  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _bytes,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton.icon(
          onPressed: () => setState(() {
            _bytes = widget.repository.image(widget.messageId);
          }),
          icon: const Icon(Icons.refresh),
          label: const Text('Tải lại ảnh'),
        );
      }
      if (!snapshot.hasData) {
        return const SizedBox(
          width: 160,
          height: 120,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      return GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(child: Image.memory(snapshot.data!)),
                ),
                SafeArea(
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            snapshot.data!,
            width: 220,
            errorBuilder: (_, _, _) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Không đọc được ảnh'),
            ),
          ),
        ),
      );
    },
  );
}
