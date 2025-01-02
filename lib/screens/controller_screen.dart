// lib/screens/controller_screen.dart
import 'package:flutter/material.dart';
import '../widgets/xbox_controller.dart';

class ControllerScreen extends StatelessWidget {
  const ControllerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: XboxController(),
    );
  }
}
