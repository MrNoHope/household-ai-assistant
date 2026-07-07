import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List<CameraDescription> cameras = [];

  try {
    cameras = await availableCameras();
  } catch (_) {
    cameras = [];
  }

  runApp(AIHouseholdApp(cameras: cameras));
}

class AIHouseholdApp extends StatelessWidget {
  const AIHouseholdApp({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Household',
      theme: AppTheme.light,
      home: HomeScreen(cameras: cameras),
    );
  }
}
