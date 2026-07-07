import 'dart:io';

import 'package:flutter/material.dart';

import '../models/history_item.dart';
import '../services/history_service.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<HistoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = HistoryService.load();
  }

  Future<void> _clear() async {
    await HistoryService.clear();
    if (!mounted) return;
    setState(() => _future = HistoryService.load());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa lịch sử')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử phân tích'),
        actions: [
          IconButton(onPressed: _clear, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: FutureBuilder<List<HistoryItem>>(
        future: _future,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Chưa có lịch sử. Hãy chụp ảnh thiết bị để phân tích.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final file = File(item.imagePath);

              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResultScreen(
                          result: item.result,
                          imagePath: item.imagePath,
                          qualityWarnings: item.qualityWarnings,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: file.existsSync()
                              ? Image.file(file, width: 86, height: 86, fit: BoxFit.cover)
                              : Container(
                                  width: 86,
                                  height: 86,
                                  color: const Color(0xFFE7ECF4),
                                  child: const Icon(Icons.image_not_supported),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.result.deviceName, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(
                                '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                              ),
                              const SizedBox(height: 6),
                              Text('Độ tin cậy ${(item.result.confidence * 100).round()}%'),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
