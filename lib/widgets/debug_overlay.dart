import 'package:flutter/material.dart';

class DebugOverlay extends StatelessWidget {
  final Map<String, double> analogInputs;
  final Map<String, bool> buttons;
  final bool isConnected;

  const DebugOverlay({
    super.key,
    required this.analogInputs,
    required this.buttons,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.3, // Spostato più in basso
      left: 0,
      right: 0,
      child: Center(
        // Centrato orizzontalmente
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(204),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connection: ${isConnected ? "✅" : "❌"}',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                'Left Stick: (${analogInputs['left_stick_x']?.toStringAsFixed(2)}, ${analogInputs['left_stick_y']?.toStringAsFixed(2)})',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                'Right Stick: (${analogInputs['right_stick_x']?.toStringAsFixed(2)}, ${analogInputs['right_stick_y']?.toStringAsFixed(2)})',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                'Active Buttons: ${buttons.entries.where((e) => e.value).map((e) => e.key).join(", ")}',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
