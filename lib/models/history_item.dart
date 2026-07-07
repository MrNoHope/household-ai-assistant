import 'appliance_result.dart';

class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.createdAt,
    required this.imagePath,
    required this.qualityWarnings,
    required this.result,
  });

  final String id;
  final DateTime createdAt;
  final String imagePath;
  final List<String> qualityWarnings;
  final ApplianceResult result;

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      imagePath: json['image_path']?.toString() ?? '',
      qualityWarnings: (json['quality_warnings'] as List? ?? const []).map((e) => e.toString()).toList(),
      result: ApplianceResult.fromJson(Map<String, dynamic>.from(json['result'] as Map? ?? const {})),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'image_path': imagePath,
      'quality_warnings': qualityWarnings,
      'result': result.toJson(),
    };
  }
}
