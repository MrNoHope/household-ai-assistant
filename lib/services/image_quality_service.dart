import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

class ImageQualityReport {
  const ImageQualityReport({
    required this.score,
    required this.warnings,
    required this.brightness,
    required this.sharpness,
    required this.width,
    required this.height,
  });

  final int score;
  final List<String> warnings;
  final double brightness;
  final double sharpness;
  final int width;
  final int height;

  bool get shouldWarn => warnings.isNotEmpty || score < 75;
}

class ImageQualityService {
  static Future<ImageQualityReport> analyze(String path) async {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return const ImageQualityReport(
        score: 30,
        warnings: ['Không đọc được ảnh. Hãy chụp lại bằng camera.'],
        brightness: 0,
        sharpness: 0,
        width: 0,
        height: 0,
      );
    }

    final resized = img.copyResize(decoded, width: math.min(180, decoded.width));
    final brightness = _brightness(resized);
    final sharpness = _sharpness(resized);
    final warnings = <String>[];
    var score = 100;

    if (decoded.width < 700 || decoded.height < 700) {
      warnings.add('Ảnh hơi nhỏ, nên chụp gần bảng điều khiển hơn.');
      score -= 18;
    }

    if (brightness < 55) {
      warnings.add('Ảnh hơi tối, nên bật thêm đèn hoặc đưa máy gần hơn.');
      score -= 22;
    } else if (brightness > 235) {
      warnings.add('Ảnh quá sáng, có thể bị lóa nút hoặc chữ.');
      score -= 18;
    }

    if (sharpness < 80) {
      warnings.add('Ảnh có thể bị mờ, nên giữ điện thoại chắc hơn rồi chụp lại.');
      score -= 28;
    }

    if (decoded.width / decoded.height > 3.2 || decoded.height / decoded.width > 3.2) {
      warnings.add('Khung ảnh hơi lệch, nên để bảng điều khiển nằm gọn trong ảnh.');
      score -= 12;
    }

    if (warnings.isNotEmpty) {
      warnings.add('Khi chụp, hãy giữ camera song song với mặt bảng điều khiển.');
    }

    return ImageQualityReport(
      score: score.clamp(0, 100).toInt(),
      warnings: warnings,
      brightness: brightness,
      sharpness: sharpness,
      width: decoded.width,
      height: decoded.height,
    );
  }

  static double _brightness(img.Image image) {
    var total = 0.0;
    var count = 0;

    for (var y = 0; y < image.height; y += 2) {
      for (var x = 0; x < image.width; x += 2) {
        final p = image.getPixel(x, y);
        total += (0.2126 * p.r) + (0.7152 * p.g) + (0.0722 * p.b);
        count++;
      }
    }

    return count == 0 ? 0 : total / count;
  }

  static double _sharpness(img.Image image) {
    if (image.width < 3 || image.height < 3) return 0;

    final values = <double>[];
    for (var y = 1; y < image.height - 1; y += 2) {
      for (var x = 1; x < image.width - 1; x += 2) {
        final center = _gray(image.getPixel(x, y));
        final left = _gray(image.getPixel(x - 1, y));
        final right = _gray(image.getPixel(x + 1, y));
        final top = _gray(image.getPixel(x, y - 1));
        final bottom = _gray(image.getPixel(x, y + 1));
        values.add((4 * center - left - right - top - bottom).abs());
      }
    }

    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return variance.toDouble();
  }

  static double _gray(img.Pixel p) {
    return ((0.299 * p.r) + (0.587 * p.g) + (0.114 * p.b)).toDouble();
  }
}
