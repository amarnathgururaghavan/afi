import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

/// On mobile/native platforms, presents the native OS share sheet.
Future<void> saveOrShareImage({
  required Uint8List bytes,
  required String fileName,
  required String text,
}) async {
  final xFile = XFile.fromData(bytes, mimeType: 'image/png', name: fileName);
  await Share.shareXFiles(
    [xFile],
    text: text,
    subject: 'Engineer Work Schedule',
  );
}
