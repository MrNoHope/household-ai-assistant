import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  static Future<String> persist(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) return sourcePath;

    final baseDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${baseDir.path}/captured_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final ext = sourcePath.split('.').last.toLowerCase();
    final safeExt = ext.length <= 5 ? ext : 'jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    final target = File('${imageDir.path}/$fileName');
    await source.copy(target.path);
    return target.path;
  }
}
