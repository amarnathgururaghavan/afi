import 'dart:typed_data';

import 'file_saver_io.dart'
    if (dart.library.html) 'file_saver_web.dart' as platform_saver;

/// Universal cross-platform helper that either downloads (web) or shares
/// (mobile/desktop) an in-memory image.
Future<void> saveOrShareImage({
  required Uint8List bytes,
  required String fileName,
  required String text,
}) =>
    platform_saver.saveOrShareImage(
      bytes: bytes,
      fileName: fileName,
      text: text,
    );
