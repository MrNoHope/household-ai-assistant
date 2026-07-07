import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_item.dart';

class HistoryService {
  static const _key = 'analysis_history';
  static const _maxItems = 20;

  static Future<List<HistoryItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .whereType<Map>()
          .map((e) => HistoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(HistoryItem item) async {
    final items = await load();
    final updated = [item, ...items].take(_maxItems).toList();
    await _saveAll(updated);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> _saveAll(List<HistoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
