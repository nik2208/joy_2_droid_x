import 'package:flutter/material.dart';

class ControllerTheme {
  // Colori principali
  static const mainButtonNormal = Color(0xFF33691E);
  static const mainButtonActive = Color(0xFF76FF03);
  static const stickButton = Color(0xFF212121);
  static const stickBackground = Color(0xFF4E342E);
  static const stickBorder = Color(0xFF3E2723);
  static const buttonColor = Color(0xFF757575);

  // Colori pulsanti faccia
  static const yButton = Color(0xBFFFEA00); // Giallo con opacità
  static const xButton = Color(0xBF1565C0); // Blu con opacità
  static const aButton = Color(0xBF64DD17); // Verde con opacità
  static const bButton = Color(0xBFD50000); // Rosso con opacità

  // Dimensioni e proporzioni
  static const largeStickSize = Size(160, 160); // Stick principale e ABXY
  static const smallStickSize = Size(130, 130); // Controlli centrali più grandi
  static const dpadSize = Size(130, 130); // D-pad uguale allo stick piccolo
  static const buttonAreaSize = Size(160, 160); // Area ABXY invariata
  static const stickSize = Size(120, 120); // Dimensione base stick analogico
  static const faceButtonSize = Size(60, 60); // Dimensione base pulsanti faccia
  static const bumperSize = Size(120, 40); // Bumper più piccoli
  static const triggerSize = Size(80, 40); // Trigger più piccoli e rettangolari

  // Colori per bumper e trigger
  static const bumperActiveColor = Color(0xFF1E88E5); // Blu quando premuto
  static const triggerActiveColor = Color(0xFFE53935); // Rosso quando premuto

  // Stili bordi
  static final buttonDecoration = BoxDecoration(
    color: stickButton,
    borderRadius: BorderRadius.circular(100),
    border: Border.all(
      color: stickBorder,
      width: 3,
    ),
  );

  static final stickDecoration = BoxDecoration(
    color: stickBackground,
    borderRadius: BorderRadius.circular(75),
    border: Border.all(
      color: stickBorder,
      width: 3,
    ),
  );

  static final dpadDecoration = BoxDecoration(
    color: stickBackground,
    borderRadius: BorderRadius.circular(75),
    border: Border.all(
      color: stickBorder,
      width: 3,
    ),
  );

  // Stili pulsanti faccia
  static BoxDecoration getFaceButtonDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(100),
      border: Border.all(
        color: stickBorder,
        width: 2,
      ),
    );
  }

  // Stili testo
  static const buttonTextStyle = TextStyle(
    color: buttonColor,
    fontSize: 24,
    fontWeight: FontWeight.w500,
  );

  static const bumperTextStyle = TextStyle(
    color: buttonColor,
    fontSize: 18,
    fontWeight: FontWeight.normal,
  );
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
