import 'package:flutter/material.dart';

import '../services/mock_ai_service.dart';
import 'result_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final MockAiService _mockAiService = MockAiService();

  @override
  void initState() {
    super.initState();
    _analyzeDevice();
  }

  Future<void> _analyzeDevice() async {
    final result = await _mockAiService.analyzeDevice();

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(deviceGuide: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    strokeWidth: 8,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'Đang phân tích thiết bị',
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Vui lòng đợi trong giây lát. Ứng dụng đang đọc thông tin từ ảnh chụp.',
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}