import 'dart:convert';

class ApplianceResult {
  const ApplianceResult({
    required this.deviceName,
    required this.deviceType,
    required this.confidence,
    required this.summary,
    required this.steps,
    required this.safetyWarnings,
    required this.usageTips,
    required this.imageQualityNote,
    required this.buttons,
  });

  final String deviceName;
  final String deviceType;
  final double confidence;
  final String summary;
  final List<String> steps;
  final List<String> safetyWarnings;
  final List<String> usageTips;
  final String imageQualityNote;
  final List<ButtonGuide> buttons;

  factory ApplianceResult.fromJson(Map<String, dynamic> json) {
    final fixedJson = _repairJson(json);

    final deviceName = _asString(
      _read(fixedJson, ['device_name', 'deviceName', 'name', 'ten_thiet_bi']),
    );

    final deviceType = _asString(
      _read(fixedJson, ['device_type', 'deviceType', 'type', 'loai_thiet_bi']),
    );

    final confidence = _normalizeConfidence(
      _read(fixedJson, ['confidence', 'confidence_score', 'do_tin_cay']),
    );

    final summary = _asString(
      _read(fixedJson, ['summary', 'mo_ta', 'description']),
    );

    final steps = _asStringList(
      _read(fixedJson, ['steps', 'usage_steps', 'huong_dan_su_dung']),
    );

    final safetyWarnings = _asStringList(
      _read(fixedJson, [
        'safety_warnings',
        'safetyWarnings',
        'warnings',
        'canh_bao_an_toan',
      ]),
    );

    final usageTips = _asStringList(
      _read(fixedJson, ['usage_tips', 'usageTips', 'tips', 'meo_su_dung']),
    );

    final imageQualityNote = _asString(
      _read(fixedJson, [
        'image_quality_note',
        'imageQualityNote',
        'quality_note',
        'nhan_xet_anh',
      ]),
    );

    final buttonsRaw = _read(fixedJson, [
      'buttons',
      'button_guides',
      'buttonGuides',
      'controls',
      'detected_buttons',
    ]);

    final buttons = _buttonList(buttonsRaw);

    return ApplianceResult(
      deviceName: deviceName.isEmpty ? 'Thiết bị chưa xác định rõ' : deviceName,
      deviceType: deviceType.isEmpty ? 'Đồ gia dụng' : deviceType,
      confidence: confidence,
      summary: summary.isEmpty
          ? 'AI đã nhận diện thiết bị nhưng chưa tạo được mô tả ngắn.'
          : summary,
      steps: steps.isEmpty
          ? const [
        'Quan sát kỹ tên nút và ký hiệu trên thiết bị.',
        'Chỉ thao tác các chức năng cơ bản khi đã chắc chắn.',
        'Dừng sử dụng nếu thiết bị nóng, có mùi khét hoặc hoạt động bất thường.',
      ]
          : steps,
      safetyWarnings: safetyWarnings.isEmpty
          ? const [
        'Không thao tác khi tay ướt nếu thiết bị dùng điện.',
        'Đọc kỹ nhãn cảnh báo trên thiết bị trước khi sử dụng.',
      ]
          : safetyWarnings,
      usageTips: usageTips,
      imageQualityNote: imageQualityNote,
      buttons: buttons,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_name': deviceName,
      'device_type': deviceType,
      'confidence': confidence,
      'summary': summary,
      'steps': steps,
      'safety_warnings': safetyWarnings,
      'usage_tips': usageTips,
      'image_quality_note': imageQualityNote,
      'buttons': buttons.map((button) => button.toJson()).toList(),
    };
  }

  String toSpeechText() {
    final buffer = StringBuffer();

    buffer.writeln('Kết quả nhận diện: $deviceName.');
    buffer.writeln('Loại thiết bị: $deviceType.');

    if (summary.trim().isNotEmpty) {
      buffer.writeln(summary.trim());
    }

    if (steps.isNotEmpty) {
      buffer.writeln('Các bước sử dụng:');
      for (var i = 0; i < steps.length; i++) {
        buffer.writeln('Bước ${i + 1}: ${steps[i]}');
      }
    }

    if (buttons.isNotEmpty) {
      buffer.writeln('Các nút chính:');
      for (final button in buttons.take(6)) {
        buffer.writeln('${button.name}: ${button.function}');
      }
    }

    if (safetyWarnings.isNotEmpty) {
      buffer.writeln('Cảnh báo an toàn:');
      for (final warning in safetyWarnings) {
        buffer.writeln(warning);
      }
    }

    if (usageTips.isNotEmpty) {
      buffer.writeln('Mẹo sử dụng:');
      for (final tip in usageTips) {
        buffer.writeln(tip);
      }
    }

    return buffer.toString().trim();
  }

  static ApplianceResult demo() {
    return const ApplianceResult(
      deviceName: 'Điều khiển TV',
      deviceType: 'Thiết bị giải trí',
      confidence: 0.92,
      summary:
      'Đây là điều khiển TV. Các nút chính gồm nút nguồn, tăng giảm âm lượng, chuyển kênh và nút điều hướng.',
      steps: [
        'Bấm nút nguồn để bật hoặc tắt TV.',
        'Dùng nút âm lượng để tăng hoặc giảm tiếng.',
        'Dùng nút điều hướng để chọn mục trên màn hình.',
      ],
      safetyWarnings: [
        'Không để điều khiển gần nước.',
        'Thay pin đúng chiều âm dương.',
      ],
      usageTips: [
        'Hướng đầu điều khiển về phía TV khi bấm.',
      ],
      imageQualityNote: 'Ảnh demo dùng để kiểm tra giao diện.',
      buttons: [
        ButtonGuide(
          name: 'Nút nguồn',
          function: 'Dùng để bật hoặc tắt thiết bị.',
          whenToUse: 'Bấm một lần khi muốn bật hoặc tắt TV.',
          caution: 'Không bấm liên tục quá nhanh.',
        ),
        ButtonGuide(
          name: 'Âm lượng',
          function: 'Dùng để tăng hoặc giảm tiếng.',
          whenToUse: 'Dùng khi âm thanh quá nhỏ hoặc quá lớn.',
          caution: '',
        ),
      ],
    );
  }
}

class ButtonGuide {
  const ButtonGuide({
    required this.name,
    required this.function,
    required this.whenToUse,
    required this.caution,
  });

  final String name;
  final String function;
  final String whenToUse;
  final String caution;

  factory ButtonGuide.fromJson(Map<String, dynamic> json) {
    final name = _asString(
      _read(json, ['name', 'button_name', 'buttonName', 'ten_nut']),
    );

    final function = _asString(
      _read(json, ['function', 'purpose', 'usage', 'cong_dung']),
    );

    final whenToUse = _asString(
      _read(json, ['when_to_use', 'whenToUse', 'when', 'khi_nao_dung']),
    );

    final caution = _asString(
      _read(json, ['caution', 'warning', 'note', 'luu_y']),
    );

    return ButtonGuide(
      name: name.isEmpty ? 'Nút chưa rõ' : name,
      function: function.isEmpty
          ? 'Chức năng của nút này chưa được xác định rõ.'
          : function,
      whenToUse: whenToUse,
      caution: caution,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'function': function,
      'when_to_use': whenToUse,
      'caution': caution,
    };
  }
}

dynamic _read(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) return json[key];
  }
  return null;
}

Map<String, dynamic> _repairJson(Map<String, dynamic> json) {
  final summary = _asString(_read(json, ['summary', 'description', 'mo_ta']));
  final nested = _decodeJsonObject(summary);

  if (nested == null) return json;

  final hasRealDeviceData = nested.containsKey('device_name') ||
      nested.containsKey('deviceName') ||
      nested.containsKey('device_type') ||
      nested.containsKey('deviceType');

  if (!hasRealDeviceData) return json;

  return {
    ...json,
    ...nested,
  };
}

Map<String, dynamic>? _decodeJsonObject(String text) {
  final cleaned = _extractJsonText(text);
  if (cleaned.isEmpty) return null;

  try {
    final decoded = jsonDecode(cleaned);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {
    return null;
  }

  return null;
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

  return value.trim();
}

String _asString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is num || value is bool) return value.toString();
  return '';
}

List<String> _asStringList(dynamic value) {
  if (value == null) return [];

  if (value is List) {
    return value
        .map(_asString)
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return [];

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) return _asStringList(decoded);
    } catch (_) {}

    return trimmed
        .split(RegExp(r'\n+|;\s*'))
        .map(
          (item) => item
          .replaceFirst(RegExp(r'^\s*[-•\d.)]+\s*'), '')
          .trim(),
    )
        .where((item) => item.isNotEmpty)
        .toList();
  }

  return [];
}

List<ButtonGuide> _buttonList(dynamic value) {
  if (value == null) return [];

  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => ButtonGuide.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.name.trim().isNotEmpty)
        .toList();
  }

  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      return _buttonList(decoded);
    } catch (_) {
      return [];
    }
  }

  return [];
}

double _normalizeConfidence(dynamic value) {
  if (value == null) return 0;

  double? number;

  if (value is num) {
    number = value.toDouble();
  } else if (value is String) {
    final cleaned = value.replaceAll('%', '').trim();
    number = double.tryParse(cleaned);
  }

  if (number == null) return 0;

  if (number > 1) {
    number = number / 100;
  }

  if (number < 0) return 0;
  if (number > 1) return 1;

  return number;
}