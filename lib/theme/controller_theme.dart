import 'package:flutter/material.dart';

class ControllerTheme {
  // Colors for buttons
  static const Color aButton = Color(0xFF2ECC71);
  static const Color bButton = Color(0xFFE74C3C);
  static const Color xButton = Color(0xFF3498DB);
  static const Color yButton = Color(0xFFF1C40F);
  
  // Main Xbox button colors
  static const Color mainButtonActive = Color(0xFF2ECC71);
  static const Color mainButtonNormal = Color(0xFFAAAAAA);
  
  // Base colors
  static final Color buttonColor = Colors.grey.shade300;
  static final Color stickBackground = Colors.grey.shade800;
  static final Color stickButton = Colors.grey.shade300;
  
  // Active colors
  static final Color bumperActiveColor = Colors.blue.shade300;
  static final Color triggerActiveColor = Colors.blue.shade600;
  
  // Sizes
  static const Size bumperSize = Size(120, 50);
  static const Size triggerSize = Size(120, 50);
  static const Size dpadSize = Size(140, 140);
  static const Size buttonAreaSize = Size(200, 200);
  static const Size largeStickSize = Size(200, 200);
  static const Size smallStickSize = Size(140, 140);
  
  // Box decorations
  static final BoxDecoration stickDecoration = BoxDecoration(
    color: stickBackground,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 8,
        spreadRadius: 1,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static final BoxDecoration dpadDecoration = BoxDecoration(
    color: buttonColor.withOpacity(0.8),
    borderRadius: BorderRadius.circular(50),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 5,
        spreadRadius: 1,
      ),
    ],
  );
  
  // Text styles
  static const TextStyle buttonTextStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );
  
  static const TextStyle bumperTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );
  
  // Helper method for face button decoration
  static BoxDecoration getFaceButtonDecoration(Color color) {
    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 5,
          spreadRadius: 1,
        ),
      ],
    );
  }
}

// Dimensioni relative per il layout responsivo
class ControllerLayout {
  static const mainButtonTopRatio = 0.15;
  static const stickWidthRatio = 0.25;
  static const stickHeightRatio = 0.50;
  static const dpadWidthRatio = 0.20;
  static const dpadHeightRatio = 0.35;
  static const faceButtonsWidthRatio = 0.30;
  static const faceButtonsHeightRatio = 0.50;

  // Margini e padding
  static const defaultPadding = 8.0;
  static const buttonSpacing = 4.0;
}
