// lib/widgets/xbox_controller.dart
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../theme/controller_theme.dart';

class XboxController extends StatefulWidget {
  const XboxController({super.key});

  @override
  XboxControllerState createState() => XboxControllerState();
}

class XboxControllerState extends State<XboxController> {
  IO.Socket? socket;
  bool isConnected = false;

  // Stato dei pulsanti e controlli dalla tua implementazione originale
  Map<String, bool> buttons = {
    'a-button': false,
    'b-button': false,
    'x-button': false,
    'y-button': false,
    'left-bumper': false,
    'right-bumper': false,
    'back-button': false,
    'start-button': false,
  };

  Map<String, double> analogInputs = {
    'left-stick-X': 0.0,
    'left-stick-Y': 0.0,
    'right-stick-X': 0.0,
    'right-stick-Y': 0.0,
    'left-trigger': 0.0,
    'right-trigger': 0.0,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Stack(
          children: [
            _buildAnalogStick('left-stick'),
            _buildAnalogStick('right-stick'),
            // TODO: Aggiungere gli altri controlli
          ],
        ),
      ),
    );
  }

  Widget _buildAnalogStick(String stickId) {
    return Positioned(
      left: stickId == 'left-stick' ? 32 : null,
      right: stickId == 'right-stick' ? 32 : null,
      top: 100,
      child: GestureDetector(
        onPanUpdate: (details) {
          final dx = details.localPosition.dx / 50.0;
          final dy = details.localPosition.dy / 50.0;
          handleAnalogInput('$stickId-X', dx.clamp(-1.0, 1.0));
          handleAnalogInput('$stickId-Y', dy.clamp(-1.0, 1.0));
        },
        onPanEnd: (_) {
          handleAnalogInput('$stickId-X', 0);
          handleAnalogInput('$stickId-Y', 0);
        },
        child: Container(
          width: ControllerTheme.stickSize.width,
          height: ControllerTheme.stickSize.height,
          decoration: ControllerTheme.stickDecoration,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ControllerTheme.stickButton,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Metodi dalla tua implementazione originale
  void connect(String serverUrl) {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': false,
      'forceNew': true,
    });

    socket!.onConnect((_) {
      setState(() => isConnected = true);
      socket!.emit('intro',
          {'device': 'Flutter Controller', 'id': 'x360', 'type': 'Xbox 360'});
    });

    socket!.onDisconnect((_) {
      setState(() => isConnected = false);
    });

    socket!.connect();
  }

  void sendInput(String key, dynamic value) {
    if (socket != null && isConnected) {
      socket!.emit('input', {
        'key': key,
        'value': value,
      });
    }
  }

  void handleButtonPress(String buttonId, bool pressed) {
    buttons[buttonId] = pressed;
    sendInput(buttonId, pressed ? 1 : 0);
  }

  void handleAnalogInput(String controlId, double value) {
    analogInputs[controlId] = value;
    sendInput(controlId, value);
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }
}
