import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/appliance_result.dart';

class GeminiService {
  const GeminiService();

  Future<ApplianceResult> analyzeImage({
    required String imagePath,
    required String apiKey,
    required String model,
  }) async {
    final key = apiKey.trim();

    if (key.isEmpty) {
      throw Exception('Chưa có Gemini API key.');
    }

    final imageFile = File(imagePath);

    if (!await imageFile.exists()) {
      throw Exception('Không tìm thấy ảnh để phân tích.');
    }

    final imageBytes = await imageFile.readAsBytes();
    final imageBase64 = base64Encode(imageBytes);
    final mimeType = _detectMimeType(imagePath);

    final url = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
    );

    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text': _prompt,
            },
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': imageBase64,
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1,
        'topP': 0.8,
        'topK': 32,
        'maxOutputTokens': 2048,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'device_name': {'type': 'STRING'},
            'device_type': {'type': 'STRING'},
            'confidence': {'type': 'NUMBER'},
            'summary': {'type': 'STRING'},
            'steps': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'},
            },
            'safety_warnings': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'},
            },
            'usage_tips': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'},
            },
            'image_quality_note': {'type': 'STRING'},
            'buttons': {
              'type': 'ARRAY',
              'items': {
                'type': 'OBJECT',
                'properties': {
                  'name': {'type': 'STRING'},
                  'function': {'type': 'STRING'},
                  'when_to_use': {'type': 'STRING'},
                  'caution': {'type': 'STRING'},
                },
                'required': ['name', 'function', 'when_to_use', 'caution'],
              },
            },
          },
          'required': [
            'device_name',
            'device_type',
            'confidence',
            'summary',
            'steps',
            'safety_warnings',
            'usage_tips',
            'image_quality_note',
            'buttons',
          ],
        },
      },
    };

    final response = await http
        .post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': key,
      },
      body: jsonEncode(body),
    )
        .timeout(const Duration(seconds: 45));

    final responseText = utf8.decode(response.bodyBytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gemini API lỗi ${response.statusCode}: $responseText');
    }

    final generatedText = _readGeneratedText(responseText);

    if (generatedText.trim().isEmpty) {
      throw Exception('Gemini không trả về nội dung phân tích.');
    }

    final parsed = _parseGeminiJson(generatedText);

    return ApplianceResult.fromJson(parsed);
  }

  String _readGeneratedText(String responseText) {
    final decoded = jsonDecode(responseText);

    if (decoded is! Map) {
      throw Exception('Phản hồi Gemini không hợp lệ.');
    }

    final candidates = decoded['candidates'];

    if (candidates is! List || candidates.isEmpty) {
      throw Exception('Gemini không trả về candidates.');
    }

    final firstCandidate = candidates.first;

    if (firstCandidate is! Map) {
      throw Exception('Candidate Gemini không hợp lệ.');
    }

    final content = firstCandidate['content'];

    if (content is! Map) {
      throw Exception('Nội dung Gemini không hợp lệ.');
    }

    final parts = content['parts'];

    if (parts is! List || parts.isEmpty) {
      throw Exception('Gemini không trả về phần text.');
    }

    final buffer = StringBuffer();

    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text']);
      }
    }

    return buffer.toString().trim();
  }

  Map<String, dynamic> _parseGeminiJson(String text) {
    final cleaned = _extractJsonText(text);

    try {
      final decoded = jsonDecode(cleaned);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      if (decoded is String) {
        final secondCleaned = _extractJsonText(decoded);
        final secondDecoded = jsonDecode(secondCleaned);

        if (secondDecoded is Map<String, dynamic>) {
          return secondDecoded;
        }

        if (secondDecoded is Map) {
          return Map<String, dynamic>.from(secondDecoded);
        }
      }
    } catch (_) {
      throw Exception(
        'AI trả dữ liệu không đúng định dạng JSON. Hãy chụp lại ảnh rõ hơn hoặc thử lại.',
      );
    }

    throw Exception('AI trả dữ liệu không đúng định dạng.');
  }

  String _extractJsonText(String text) {
    var value = text.trim();

    if (value.startsWith('```')) {
      value = value.replaceFirst(
        RegExp(r'^```json\s*', caseSensitive: false),
        '',
      );
      value = value.replaceFirst(RegExp(r'^```\s*'), '');
      value = value.replaceFirst(RegExp(r'\s*```$'), '');
    }

    final first = value.indexOf('{');
    final last = value.lastIndexOf('}');

    if (first >= 0 && last > first) {
      return value.substring(first, last + 1).trim();
    }

    return value;
  }

  String _detectMimeType(String imagePath) {
    final lower = imagePath.toLowerCase();

    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';

    return 'image/jpeg';
  }
}

const String _prompt = '''
Bạn là AI hỗ trợ người dùng Việt Nam, đặc biệt là người lớn tuổi, nhận diện và hướng dẫn sử dụng thiết bị gia dụng từ ảnh chụp.

Nhiệm vụ:
1. Nhìn ảnh và xác định thiết bị hoặc bảng điều khiển.
2. Giải thích bằng tiếng Việt đơn giản, dễ hiểu.
3. Nếu ảnh không phải đồ gia dụng, hãy nói rõ thiết bị là gì, nhưng vẫn trả JSON đúng định dạng.
4. Không bịa quá mức. Nếu không chắc, giảm confidence và ghi rõ trong image_quality_note.
5. Chỉ trả về JSON thuần. Không markdown. Không giải thích ngoài JSON.

Yêu cầu JSON:
{
  "device_name": "Tên thiết bị cụ thể, ví dụ: Điều khiển TV Samsung, Nồi cơm điện, Máy giặt, Củ sạc điện thoại...",
  "device_type": "Loại thiết bị",
  "confidence": 0.0,
  "summary": "Mô tả ngắn gọn thiết bị dùng để làm gì, viết như người bình thường, không ghi key JSON vào đây.",
  "steps": [
    "Bước 1 sử dụng thiết bị",
    "Bước 2 sử dụng thiết bị",
    "Bước 3 sử dụng thiết bị"
  ],
  "safety_warnings": [
    "Cảnh báo an toàn 1",
    "Cảnh báo an toàn 2"
  ],
  "usage_tips": [
    "Mẹo sử dụng 1",
    "Mẹo sử dụng 2"
  ],
  "image_quality_note": "Nhận xét ngắn về độ rõ của ảnh.",
  "buttons": [
    {
      "name": "Tên nút",
      "function": "Nút này dùng để làm gì",
      "when_to_use": "Khi nào nên dùng nút này",
      "caution": "Lưu ý khi dùng nút này"
    }
  ]
}

Quy tắc:
- confidence là số từ 0 đến 1. Ví dụ chắc 95% thì trả 0.95.
- steps phải dễ hiểu, không dài dòng.
- buttons chỉ liệt kê các nút nhìn thấy hoặc suy luận hợp lý từ ảnh.
- summary tuyệt đối không được chứa JSON thô.
- Không dùng tiếng Anh nếu không cần thiết.
''';