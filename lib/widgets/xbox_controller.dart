import 'dart:math';

import 'package:flutter/material.dart';
import 'package:joy_2_droid_x/services/socket_service.dart';
import 'package:joy_2_droid_x/widgets/debug_overlay.dart';
import 'package:joy_2_droid_x/widgets/qr_scanner.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../theme/controller_theme.dart';
import 'dart:developer' as developer;

class StickPainter extends CustomPainter {
  final double x;
  final double y;
  final double innerSize;

  StickPainter({required this.x, required this.y, required this.innerSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Calcola la posizione dello stick limitata al raggio
    final radius = (size.width - innerSize) / 2;
    final stickX = center.dx + (x * radius);
    final stickY = center.dy + (y * radius);

    final paint = Paint()
      ..color = ControllerTheme.stickButton
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(stickX, stickY), innerSize / 2, paint);
  }

  @override
  bool shouldRepaint(StickPainter oldDelegate) {
    return x != oldDelegate.x || y != oldDelegate.y;
  }
}

class XboxController extends StatefulWidget {
  const XboxController({super.key});

  @override
  XboxControllerState createState() => XboxControllerState();
}

class XboxControllerState extends State<XboxController> {
  IO.Socket? socket;
  bool isConnected = false;
  final SocketService _socketService = SocketService();
  bool showDebug = false; // Aggiungi questa variabile di stato
  bool showMenu = false; // Aggiungi questa variabile di stato

  // Aggiungi queste variabili di stato
  String serverAddress = '192.168.188.28:8013';
  bool connectionEnabled = false;

  // State for buttons and controls
  Map<String, bool> buttons = {
    'a_button': false,
    'b_button': false,
    'x_button': false,
    'y_button': false,
    'left_bumper': false,
    'right_bumper': false,
    'back_button': false,
    'start_button': false,
  };

  Map<String, double> analogInputs = {
    'left_stick_x': 0.0,
    'left_stick_y': 0.0,
    'right_stick_x': 0.0,
    'right_stick_y': 0.0,
    'left_trigger': 0.0,
    'right_trigger': 0.0,
  };

  @override
  void initState() {
    super.initState();
    // Rimuovi la connessione automatica
    // _connectToServer();
  }

  void _connectToServer() async {
    print('Initializing connection...');
    try {
      await _socketService.connect(serverAddress);
      setState(() {
        isConnected = _socketService.isSocketConnected();
      });
    } catch (e) {
      print('Connection error: $e');
      setState(() => isConnected = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Stack(
          children: [
            _buildMainButton(),
            _buildLeftStick(),
            _buildRightStick(),
            _buildDpad(),
            _buildFaceButtons(),
            _buildBumpers(),
            _buildTriggers(),
            _buildCenterButtons(), // Aggiungi i tasti centrali
            if (showDebug)
              DebugOverlay(
                analogInputs: analogInputs,
                buttons: buttons,
                isConnected: isConnected,
              ),
            if (showMenu) _buildMenuOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.15,
      left: (MediaQuery.of(context).size.width - 48) / 2,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          border: Border.all(
            color: isConnected
                ? ControllerTheme.mainButtonActive
                : ControllerTheme.mainButtonNormal,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(27),
        ),
        child: IconButton(
          icon: Icon(
            Icons.gamepad,
            color: isConnected
                ? ControllerTheme.mainButtonActive
                : ControllerTheme.mainButtonNormal,
          ),
          onPressed: () => _showMenu(),
        ),
      ),
    );
  }

  Widget _buildLeftStick() {
    // Stick sinistro rimane dov'è (è già posizionato bene)
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.45,
      left: MediaQuery.of(context).size.width * 0.1,
      child: _buildAnalogStick('left_stick', true),
    );
  }

  Widget _buildFaceButtons() {
    // Pulsanti ABXY speculari allo stick sinistro
    return Positioned(
      top: MediaQuery.of(context).size.height *
          0.45, // Stessa altezza dello stick sinistro
      right: MediaQuery.of(context).size.width *
          0.1, // Speculare allo stick sinistro
      child: SizedBox(
        width: ControllerTheme.buttonAreaSize.width,
        height: ControllerTheme.buttonAreaSize.height,
        child: GridView.count(
          crossAxisCount: 3,
          physics: NeverScrollableScrollPhysics(), // Prevent scrolling
          children: [
            Container(),
            _buildFaceButton('y_button', 'Y', ControllerTheme.yButton),
            Container(),
            _buildFaceButton('x_button', 'X', ControllerTheme.xButton),
            Container(),
            _buildFaceButton('b_button', 'B', ControllerTheme.bButton),
            Container(),
            _buildFaceButton('a_button', 'A', ControllerTheme.aButton),
            Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceButton(String id, String label, Color color) {
    final bool isPressed = buttons[id] ?? false;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => buttons[id] = true);
        _sendInput(id, 1);
      },
      onTapUp: (_) {
        setState(() => buttons[id] = false);
        _sendInput(id, 0);
      },
      onTapCancel: () {
        setState(() => buttons[id] = false);
        _sendInput(id, 0);
      },
      child: Container(
        decoration: ControllerTheme.getFaceButtonDecoration(
          isPressed ? color.withOpacity(1.0) : color,
        ),
        child: Center(
          child: Text(
            label,
            style: ControllerTheme.buttonTextStyle.copyWith(
              color: isPressed ? Colors.white : ControllerTheme.buttonColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightStick() {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.05,
      right: MediaQuery.of(context).size.width * 0.32, // Spostato più a destra
      child: _buildAnalogStick('right_stick', false),
    );
  }

  Widget _buildDpad() {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.05,
      left: MediaQuery.of(context).size.width * 0.32, // Spostato più a sinistra
      child: Container(
        width: ControllerTheme.dpadSize.width,
        height: ControllerTheme.dpadSize.height,
        decoration: ControllerTheme.dpadDecoration,
        child: GridView.count(
          crossAxisCount: 3,
          children: [
            Container(), // Top-left empty
            _buildDpadButton('up_button', Icons.arrow_upward),
            Container(), // Top-right empty
            _buildDpadButton('left_button', Icons.arrow_back),
            Container(), // Center empty
            _buildDpadButton('right_button', Icons.arrow_forward),
            Container(), // Bottom-left empty
            _buildDpadButton('down_button', Icons.arrow_downward),
            Container(), // Bottom-right empty
          ],
        ),
      ),
    );
  }

  Widget _buildBumpers() {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25,
          left: MediaQuery.of(context).size.width * 0.1,
          child: _buildBumper('left_bumper', 'LB'),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25,
          right: MediaQuery.of(context).size.width * 0.1,
          child: _buildBumper('right_bumper', 'RB'),
        ),
      ],
    );
  }

  Widget _buildBumper(String id, String label) {
    final bool isPressed = buttons[id] ?? false;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => buttons[id] = true);
        _sendInput(id, 1);
      },
      onTapUp: (_) {
        setState(() => buttons[id] = false);
        _sendInput(id, 0);
      },
      onTapCancel: () {
        setState(() => buttons[id] = false);
        _sendInput(id, 0);
      },
      child: Container(
        width: ControllerTheme.bumperSize.width,
        height: ControllerTheme.bumperSize.height,
        decoration: BoxDecoration(
          color: isPressed
              ? ControllerTheme.bumperActiveColor
              : ControllerTheme.buttonColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.black26, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: ControllerTheme.bumperTextStyle
                .copyWith(color: isPressed ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildTriggers() {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).size.height * 0.1,
          left: MediaQuery.of(context).size.width * 0.1,
          child: _buildTrigger('left_trigger', 'LT'),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.1,
          right: MediaQuery.of(context).size.width * 0.1,
          child: _buildTrigger('right_trigger', 'RT'),
        ),
      ],
    );
  }

  Widget _buildTrigger(String id, String label) {
    final bool isPressed = buttons[id] ?? false;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => buttons[id] = true);
        _sendInput(id, 1);
      },
      onTapUp: (_) {
        setState(() => buttons[id] = false);
        _sendInput(id, 0);
      },
      onTapCancel: () {
        setState(() => buttons[id] = false);
        _sendInput(id, 0);
      },
      child: Container(
        width: ControllerTheme.triggerSize.width,
        height: ControllerTheme.triggerSize.height,
        decoration: BoxDecoration(
          color: isPressed
              ? ControllerTheme.triggerActiveColor
              : ControllerTheme.buttonColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.black26, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: ControllerTheme.bumperTextStyle
                .copyWith(color: isPressed ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildDpadButton(String id, IconData icon) {
    final bool isPressed = buttons[id] ?? false;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => buttons[id] = true);
        _sendInput(id, 1);
      },
      onTapUp: (_) {
        setState(() => buttons[id] = false);
        _sendInput(id, 0);
      },
      onTapCancel: () {
        setState(() => buttons[id] = false);
        _sendInput(id, 0);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isPressed
              ? ControllerTheme.buttonColor.withOpacity(1.0)
              : ControllerTheme.buttonColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isPressed ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  void _updateStickPosition(String stickId, Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    double dx = (localPosition.dx - center.dx);
    double dy = (localPosition.dy - center.dy);

    final radius = size.width / 2;
    dx = dx / radius;
    dy = dy / radius;

    final double distance = sqrt(dx * dx + dy * dy);

    if (distance < 0.2) {
      // Deadzone
      dx = dy = 0;
    } else if (distance > 1.0) {
      // Preserva i valori massimi agli angoli invece di normalizzare
      dx = dx.sign * min(dx.abs(), 1.0);
      dy = dy.sign * min(dy.abs(), 1.0);
    }

    setState(() {
      String stick = stickId.split('_')[0];
      analogInputs['${stick}_stick_x'] = dx;
      analogInputs['${stick}_stick_y'] = dy;
    });

    if (isConnected) {
      String stick = stickId.split('_')[0];
      _socketService.sendAnalogInput(stick, dx, dy);
    }
  }

  Widget _buildAnalogStick(String stickId, bool isLarge) {
    final size = isLarge
        ? ControllerTheme.largeStickSize
        : ControllerTheme.smallStickSize;
    final innerSize = size.width * 0.3;

    return Container(
      width: size.width,
      height: size.height,
      decoration: ControllerTheme.stickDecoration,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) =>
            _updateStickPosition(stickId, details.localPosition, size),
        onPanUpdate: (details) =>
            _updateStickPosition(stickId, details.localPosition, size),
        onPanEnd: (_) {
          _updateStickPosition(
              stickId, Offset(size.width / 2, size.height / 2), size);
        },
        onPanCancel: () {
          _updateStickPosition(
              stickId, Offset(size.width / 2, size.height / 2), size);
        },
        child: CustomPaint(
          painter: StickPainter(
            x: analogInputs['${stickId}_x'] ?? 0,
            y: analogInputs['${stickId}_y'] ?? 0,
            innerSize: innerSize,
          ),
          size: Size(size.width, size.height),
        ),
      ),
    );
  }

  void _sendInput(String key, dynamic value) {
    if (!isConnected) return; // Non inviare input se non connesso

    developer.log('Button press: $key = $value');
    if (key.contains('stick')) {
      return;
    } else {
      _socketService.sendButtonInput(key, value as int);
    }
  }

  Widget _buildMenuOverlay() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.2,
      left: 0,
      right: 0,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(229),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Controller Menu',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colonna sinistra - Switches
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            title: Text('Connection',
                                style: TextStyle(color: Colors.white)),
                            value: connectionEnabled,
                            onChanged: (enabled) {
                              setState(() => connectionEnabled = enabled);
                              if (enabled) {
                                _connectToServer();
                              } else {
                                _socketService.disconnect();
                                setState(() => isConnected = false);
                              }
                            },
                          ),
                          SwitchListTile(
                            title: Text('Debug',
                                style: TextStyle(color: Colors.white)),
                            value: showDebug,
                            onChanged: (bool value) =>
                                setState(() => showDebug = value),
                          ),
                        ],
                      ),
                    ),
                    // Colonna destra - Parametri
                    if (connectionEnabled)
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Server Status:',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              Text(
                                isConnected ? 'Connected' : 'Disconnected',
                                style: TextStyle(
                                  color: isConnected
                                      ? Colors.green[300]
                                      : Colors.red[300],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text('Server Address:',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: serverAddress,
                                      style: TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 8),
                                      ),
                                      onChanged: (value) =>
                                          setState(() => serverAddress = value),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.qr_code_scanner,
                                        color: Colors.white),
                                    onPressed: _scanQRCode,
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _connectToServer,
                                child: Text('Reconnect'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                TextButton(
                  child: Text('Close'),
                  onPressed: () => setState(() => showMenu = false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMenu() {
    setState(() => showMenu = !showMenu);
  }

  void _scanQRCode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => QRScanner(
          onCodeScanned: (code) {
            setState(() => serverAddress = code);
            _connectToServer();
          },
        ),
      ),
    );
    if (code != null) {
      setState(() => serverAddress = code);
      _connectToServer();
    }
  }

  Widget _buildCenterButtons() {
    return Stack(
      children: [
        // Tasto Back (sinistra)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.45,
          left: MediaQuery.of(context).size.width * 0.4,
          child: _buildCenterButton('back', 'Back'),
        ),
        // Tasto Start/Menu (destra)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.45,
          right: MediaQuery.of(context).size.width * 0.4,
          child: _buildCenterButton('start', 'Menu'),
        ),
      ],
    );
  }

  Widget _buildCenterButton(String id, String label) {
    final bool isPressed = buttons['${id}_button'] ?? false;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => buttons['${id}_button'] = true);
        _sendInput('${id}_button', 1);
      },
      onTapUp: (_) {
        setState(() => buttons['${id}_button'] = false);
        _sendInput('${id}_button', 0);
      },
      onTapCancel: () {
        setState(() => buttons['${id}_button'] = false);
        _sendInput('${id}_button', 0);
      },
      child: Container(
        width: 60,
        height: 30,
        decoration: BoxDecoration(
          color: isPressed ? Colors.grey[700] : Colors.grey[850],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black26, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isPressed ? Colors.white : Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }
}
