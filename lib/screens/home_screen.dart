import 'package:flutter/material.dart';

import 'loading_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _startAnalyze(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoadingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Trợ lý đồ gia dụng',
                style: textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Chụp ảnh bảng điều khiển thiết bị để nhận hướng dẫn sử dụng đơn giản.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_rounded,
                        size: 96,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Khu vực camera',
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Camera thật sẽ được tích hợp ở bước sau',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 86,
                child: ElevatedButton.icon(
                  onPressed: () => _startAnalyze(context),
                  icon: const Icon(
                    Icons.photo_camera_rounded,
                    size: 36,
                  ),
                  label: const Text(
                    'Chụp ảnh',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}