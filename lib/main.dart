// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/controller_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const XboxControllerApp());
}

class XboxControllerApp extends StatelessWidget {
  const XboxControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xbox Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const ControllerScreen(),
    );
  }
}
