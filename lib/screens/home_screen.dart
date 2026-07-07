import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_config.dart';
import '../models/history_item.dart';
import '../services/gemini_service.dart';
import '../services/history_service.dart';
import '../services/image_quality_service.dart';
import '../services/image_storage_service.dart';
import 'history_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _picker = ImagePicker();
  final _gemini = const GeminiService();

  CameraController? _controller;
  Future<void>? _cameraFuture;
  bool _busy = false;
  String _busyText = '';
  int _cameraVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraVersion++;
    final controller = _controller;
    _controller = null;
    _cameraFuture = null;
    unawaited(controller?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _controller == null) {
      unawaited(_initCamera());
    }
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty || _busy) return;

    final version = ++_cameraVersion;
    final old = _controller;

    if (mounted) {
      setState(() {
        _controller = null;
        _cameraFuture = null;
      });
    }

    await old?.dispose();

    final controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    final future = controller.initialize();

    if (!mounted || version != _cameraVersion) {
      await controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
      _cameraFuture = future;
    });

    try {
      await future;
      if (!mounted || version != _cameraVersion) return;
      setState(() {});
    } catch (e) {
      if (!mounted || version != _cameraVersion) return;

      setState(() {
        _controller = null;
        _cameraFuture = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không mở được camera: $e')),
      );
    }
  }

  Future<void> _capture() async {
    if (_busy) return;

    final controller = _controller;
    final future = _cameraFuture;

    if (controller == null || future == null) return;

    try {
      await future;

      if (!mounted) return;
      if (!controller.value.isInitialized) return;
      if (controller.value.isTakingPicture) return;

      final file = await controller.takePicture();
      await _processImage(file.path);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không chụp được ảnh, vui lòng thử lại: $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );

    if (file == null) return;
    await _processImage(file.path);
  }

  Future<void> _processImage(String path) async {
    setState(() {
      _busy = true;
      _busyText = 'Đang kiểm tra chất lượng ảnh...';
    });

    try {
      final report = await ImageQualityService.analyze(path);
      if (!mounted) return;

      setState(() => _busy = false);

      if (report.shouldWarn) {
        final shouldContinue = await _showQualityWarning(report);
        if (shouldContinue != true) return;
      }

      await _analyze(path, report.warnings);
    } catch (e) {
      if (!mounted) return;

      setState(() => _busy = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xử lý được ảnh: $e')),
      );
    }
  }

  Future<void> _analyze(String path, List<String> qualityWarnings) async {
    if (!ApiConfig.hasKey) {
      await _showMissingApiKey();
      return;
    }

    setState(() {
      _busy = true;
      _busyText = 'AI đang nhận diện thiết bị...';
    });

    try {
      final savedImagePath = await ImageStorageService.persist(path);

      final result = await _gemini.analyzeImage(
        imagePath: savedImagePath,
        apiKey: ApiConfig.apiKey,
        model: ApiConfig.geminiModel,
      );

      final item = HistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        imagePath: savedImagePath,
        qualityWarnings: qualityWarnings,
        result: result,
      );

      await HistoryService.add(item);

      if (!mounted) return;

      setState(() => _busy = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            result: result,
            imagePath: savedImagePath,
            qualityWarnings: qualityWarnings,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _busy = false);
      await _showAnalyzeError(e.toString());
    }
  }

  Future<bool?> _showQualityWarning(ImageQualityReport report) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ảnh chưa thật rõ',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Điểm ảnh: ${report.score}/100 • ${report.width}x${report.height}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                ...report.warnings.map(
                      (warning) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            warning,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Phân tích luôn'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Chụp lại'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMissingApiKey() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chưa có Gemini API key'),
        content: const Text(
          'App đã bỏ chế độ demo. Bạn cần dán Gemini API key vào file lib/core/api_config.dart, dòng localGeminiApiKey, rồi chạy lại app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAnalyzeError(String error) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI chưa phân tích được'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  void _showHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaptureHelpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 44),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'CHỤP ẢNH THIẾT BỊ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Đưa thiết bị vào giữa khung hình',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            const Text(
                              'Hãy chụp rõ toàn bộ các nút bấm',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _MiniCircleButton(
                        icon: Icons.photo_library_outlined,
                        background: Colors.white,
                        foreground: Colors.black,
                        borderColor: const Color(0xFFE5E7EB),
                        onTap: _busy ? null : _pickFromGallery,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: _CaptureFrame(
                        controller: _controller,
                        cameraFuture: _cameraFuture,
                        hasCamera: widget.cameras.isNotEmpty,
                        onRetry: _initCamera,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 82,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _MiniCircleButton(
                            icon: Icons.history,
                            background: Colors.white,
                            foreground: Colors.black,
                            borderColor: const Color(0xFFE5E7EB),
                            onTap: _busy ? null : _openHistory,
                          ),
                        ),
                        _CaptureButton(onTap: _busy ? null : _capture),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _MiniCircleButton(
                            icon: Icons.question_mark,
                            background: Colors.black,
                            foreground: Colors.white,
                            onTap: _busy ? null : _showHelp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_busy)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Center(
                    child: Card(
                      color: Colors.white,
                      margin: const EdgeInsets.all(26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 18),
                            Text(
                              _busyText,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CaptureFrame extends StatelessWidget {
  const _CaptureFrame({
    required this.controller,
    required this.cameraFuture,
    required this.hasCamera,
    required this.onRetry,
  });

  final CameraController? controller;
  final Future<void>? cameraFuture;
  final bool hasCamera;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.62,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 430),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FA),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CameraContent(
                controller: controller,
                cameraFuture: cameraFuture,
                hasCamera: hasCamera,
                onRetry: onRetry,
              ),
              const _CornerBrackets(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraContent extends StatelessWidget {
  const _CameraContent({
    required this.controller,
    required this.cameraFuture,
    required this.hasCamera,
    required this.onRetry,
  });

  final CameraController? controller;
  final Future<void>? cameraFuture;
  final bool hasCamera;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!hasCamera) {
      return _FrameMessage(
        title: 'Không tìm thấy camera',
        message:
        'Bạn vẫn có thể bấm biểu tượng ảnh ở góc trên để chọn ảnh từ thư viện.',
        onRetry: onRetry,
      );
    }

    final activeController = controller;
    final activeFuture = cameraFuture;

    if (activeController == null || activeFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<void>(
      future: activeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            activeController.value.isInitialized) {
          return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: activeController.value.previewSize?.height ?? 1,
              height: activeController.value.previewSize?.width ?? 1,
              child: CameraPreview(activeController),
            ),
          );
        }

        if (snapshot.hasError) {
          return _FrameMessage(
            title: 'Camera chưa sẵn sàng',
            message: 'Hãy cấp quyền camera rồi thử lại.',
            onRetry: onRetry,
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _FrameMessage extends StatelessWidget {
  const _FrameMessage({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 44, color: Color(0xFF111827)),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Stack(
          children: [
            _Corner(alignment: Alignment.topLeft),
            _Corner(alignment: Alignment.topRight),
            _Corner(alignment: Alignment.bottomLeft),
            _Corner(alignment: Alignment.bottomRight),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment.x < 0;
    final isTop = alignment.y < 0;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          children: [
            Positioned(
              left: isLeft ? 0 : null,
              right: isLeft ? null : 0,
              top: isTop ? 0 : null,
              bottom: isTop ? null : 0,
              child: Container(width: 3, height: 34, color: Colors.black),
            ),
            Positioned(
              left: isLeft ? 0 : null,
              right: isLeft ? null : 0,
              top: isTop ? 0 : null,
              bottom: isTop ? null : 0,
              child: Container(width: 34, height: 3, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 74,
        height: 74,
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
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniCircleButton extends StatelessWidget {
  const _MiniCircleButton({
    required this.icon,
    required this.background,
    required this.foreground,
    this.borderColor,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: borderColor == null ? null : Border.all(color: borderColor!),
        ),
        child: Icon(icon, color: foreground, size: 22),
      ),
    );
  }
}

class CaptureHelpScreen extends StatelessWidget {
  const CaptureHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HƯỚNG DẪN',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FA),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HelpItem(text: 'Đưa phần nút bấm vào giữa khung hình.'),
                      _HelpItem(
                        text: 'Chụp đủ sáng, tránh bóng tối và ánh đèn lóa.',
                      ),
                      _HelpItem(
                        text:
                        'Giữ điện thoại song song với bảng điều khiển.',
                      ),
                      _HelpItem(
                        text:
                        'Không cần chụp toàn bộ thiết bị, ưu tiên nút và chữ.',
                      ),
                    ],
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

class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}