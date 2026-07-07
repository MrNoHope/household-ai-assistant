import 'dart:io';

import 'package:flutter/material.dart';

import '../models/appliance_result.dart';
import '../services/tts_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.imagePath,
    required this.qualityWarnings,
  });

  final ApplianceResult result;
  final String imagePath;
  final List<String> qualityWarnings;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _speaking = false;

  Future<void> _toggleSpeak() async {
    if (_speaking) {
      await TtsService.instance.stop();
      if (mounted) {
        setState(() => _speaking = false);
      }
      return;
    }

    setState(() => _speaking = true);
    await TtsService.instance.speakResult(widget.result);

    if (mounted) {
      setState(() => _speaking = false);
    }
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _showButtonGuide(ButtonGuide button) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFEAFBFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  button.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  button.function,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.3,
                    color: Colors.black,
                  ),
                ),
                if (button.whenToUse.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Khi dùng: ${button.whenToUse}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                ],
                if (button.caution.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Lưu ý: ${button.caution}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đã hiểu'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullGuide() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        final result = widget.result;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.40,
          maxChildSize: 0.94,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              children: [
                Text(
                  result.deviceName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${result.deviceType} • Độ tin cậy ${(result.confidence * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  result.summary,
                  style: const TextStyle(fontSize: 17, height: 1.35),
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Các bước sử dụng'),
                ...result.steps.asMap().entries.map(
                      (entry) => _NumberLine(
                    number: entry.key + 1,
                    text: entry.value,
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionTitle('Cảnh báo an toàn'),
                ...result.safetyWarnings.map(
                      (warning) => _WarningLine(text: warning),
                ),
                if (result.usageTips.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const _SectionTitle('Mẹo sử dụng'),
                  ...result.usageTips.map(
                        (tip) => _TipLine(text: tip),
                  ),
                ],
                if (result.buttons.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const _SectionTitle('Các nút đã nhận diện'),
                  const SizedBox(height: 10),
                  ...result.buttons.asMap().entries.map(
                        (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ButtonInfoCard(
                        index: entry.key + 1,
                        button: entry.value,
                        onTap: () => _showButtonGuide(entry.value),
                      ),
                    ),
                  ),
                ],
                if (result.imageQualityNote.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const _SectionTitle('Nhận xét ảnh'),
                  Text(
                    result.imageQualityNote,
                    style: const TextStyle(fontSize: 16, height: 1.35),
                  ),
                ],
                if (widget.qualityWarnings.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const _SectionTitle('Cảnh báo chất lượng ảnh'),
                  ...widget.qualityWarnings.map(
                        (warning) => _WarningLine(text: warning),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttons = widget.result.buttons;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'KẾT QUẢ HƯỚNG DẪN',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Các nút cơ bản đã được nhận diện',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 0.68,
                        child: Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Không hiển thị được ảnh',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ResultSummaryCard(result: widget.result),
                  const SizedBox(height: 18),
                  const _SectionTitle('Các nút đã nhận diện'),
                  const SizedBox(height: 10),
                  if (buttons.isEmpty)
                    const _NoButtonBox()
                  else
                    ...buttons.asMap().entries.map(
                          (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ButtonInfoCard(
                          index: entry.key + 1,
                          button: entry.value,
                          onTap: () => _showButtonGuide(entry.value),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: _showFullGuide,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(120, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Chi tiết',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _SpeakButton(
                      speaking: _speaking,
                      onTap: _toggleSpeak,
                    ),
                    const Spacer(),
                    const SizedBox(width: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSummaryCard extends StatelessWidget {
  const _ResultSummaryCard({required this.result});

  final ApplianceResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.deviceName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${result.deviceType} • Độ tin cậy ${(result.confidence * 100).round()}%',
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            result.summary,
            style: const TextStyle(
              fontSize: 16,
              height: 1.35,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonInfoCard extends StatelessWidget {
  const _ButtonInfoCard({
    required this.index,
    required this.button,
    required this.onTap,
  });

  final int index;
  final ButtonGuide button;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF8CB6F2),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    button.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    button.function,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _NoButtonBox extends StatelessWidget {
  const _NoButtonBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'AI chưa xác định được nút rõ ràng.\nBạn có thể bấm "Chi tiết" để xem hướng dẫn tổng quát.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          height: 1.35,
        ),
      ),
    );
  }
}

class _SpeakButton extends StatelessWidget {
  const _SpeakButton({
    required this.speaking,
    required this.onTap,
  });

  final bool speaking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: const Color(0xFF8CB6F2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8CB6F2).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          speaking ? Icons.stop : Icons.volume_up,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Colors.black,
      ),
    );
  }
}

class _NumberLine extends StatelessWidget {
  const _NumberLine({
    required this.number,
    required this.text,
  });

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF8CB6F2),
            child: Text(
              '$number',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningLine extends StatelessWidget {
  const _WarningLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipLine extends StatelessWidget {
  const _TipLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}