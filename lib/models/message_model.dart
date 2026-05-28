import 'dart:typed_data';

class Message {
  final String id;
  final String text;
  final String senderId;
  final String time;
  final Uint8List? imageBytes;
  final String? imageName;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.time,
    this.imageBytes,
    this.imageName,
  });

  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;
}
