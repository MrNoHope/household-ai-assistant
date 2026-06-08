import 'package:flutter/material.dart';

import '../models/device_guide.dart';

class ResultScreen extends StatelessWidget {
  final DeviceGuide deviceGuide;

  const ResultScreen({
    super.key,
    required this.deviceGuide,
  });

  void _goHome(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              Text(
                deviceGuide.deviceName,
                style: textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _InfoCard(
                title: 'Công dụng chính',
                child: Text(
                  deviceGuide.mainFunction,
                  style: textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 20),
              _InfoCard(
                title: 'Các bước sử dụng',
                child: Column(
                  children: List.generate(
                    deviceGuide.steps.length,
                        (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: colorScheme.primary,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                deviceGuide.steps[index],
                                style: textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _InfoCard(
                title: 'Lưu ý an toàn',
                child: Text(
                  deviceGuide.safetyNote,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 72,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.volume_up_rounded, size: 32),
                  label: const Text(
                    'Đọc to hướng dẫn',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 72,
                child: OutlinedButton.icon(
                  onPressed: () => _goHome(context),
                  icon: const Icon(Icons.home_rounded, size: 32),
                  label: const Text(
                    'Về trang chủ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
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

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}