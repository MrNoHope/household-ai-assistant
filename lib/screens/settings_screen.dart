import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  bool _demoMode = false;
  bool _loading = true;
  bool _hideKey = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await SettingsService.load();
    if (!mounted) return;
    setState(() {
      _apiKeyController.text = settings.apiKey;
      _modelController.text = settings.model;
      _demoMode = settings.demoMode;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await SettingsService.save(
      AppSettings(
        apiKey: _apiKeyController.text,
        model: _modelController.text,
        demoMode: _demoMode,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu cài đặt')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt AI')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'Gemini API key',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _apiKeyController,
              obscureText: _hideKey,
              decoration: InputDecoration(
                hintText: 'Dán API key vào đây',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hideKey = !_hideKey),
                  icon: Icon(_hideKey ? Icons.visibility : Icons.visibility_off),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Model',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                hintText: 'gemini-2.5-flash',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Nếu model lỗi, hãy mở Google AI Studio để xem model đang được API key của bạn hỗ trợ. Mặc định nên dùng gemini-2.5-flash.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Card(
              child: SwitchListTile(
                value: _demoMode,
                onChanged: (value) => setState(() => _demoMode = value),
                title: const Text('Chế độ demo'),
                subtitle: const Text('Bật để test giao diện không cần API key.'),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Lưu cài đặt'),
            ),
          ],
        ),
      ),
    );
  }
}
