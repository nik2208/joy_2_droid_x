import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:joy_2_droid_x/services/socket_service.dart';
import 'package:joy_2_droid_x/widgets/debug_overlay.dart';
import 'package:joy_2_droid_x/widgets/qr_scanner.dart'; // Verifica che questo sia aggiornato
import 'package:socket_io_client/socket_io_client.dart' as io;
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
  io.Socket? socket;
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

  // Add connection monitoring timer
  Timer? _connectionMonitor;

  @override
  void initState() {
    super.initState();
    // Rimuovi la connessione automatica
    // _connectToServer();
    
    // Start connection monitoring
    _startConnectionMonitoring();
  }

  // Add this method to monitor connection state
  void _startConnectionMonitoring() {
    _connectionMonitor?.cancel();
    _connectionMonitor = Timer.periodic(Duration(seconds: 1), (timer) {
      final newConnectionState = _socketService.isSocketConnected();
      if (isConnected != newConnectionState) {
        setState(() {
          isConnected = newConnectionState;
          print('Connection state change detected: $isConnected');
        });
      }
    });
  }

  void _connectToServer() async {
    print('Initializing connection to $serverAddress...');
    try {
      await _socketService.connect(serverAddress);
      
      // Important: Force state update after connection attempt
      setState(() {
        isConnected = _socketService.isSocketConnected();
        print('Connection status after connect attempt: $isConnected');
      });
      
      // Double-check after a short delay to ensure UI reflects the correct state
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          isConnected = _socketService.isSocketConnected();
          print('Connection status verification: $isConnected');
        });
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
      top: MediaQuery.of(context).size.height * 0.20,
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
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.50,
      left: MediaQuery.of(context).size.width * 0.1,
      child: _buildJoystick('left_stick', 150, Colors.blueGrey.shade700),
    );
  }

  Widget _buildFaceButtons() {
    // Pulsanti ABXY speculari allo stick sinistro
    return Positioned(
      top: MediaQuery.of(context).size.height *
          0.50, // Stessa altezza dello stick sinistro
      right: MediaQuery.of(context).size.width *
          0.15, // Speculare allo stick sinistro
      child: SizedBox(
        width: ControllerTheme.buttonAreaSize.width,
        height: ControllerTheme.buttonAreaSize.height,
        child: GridView.count(
          crossAxisCount: 3,
          physics: NeverScrollableScrollPhysics(), // Prevent scrolling
          children: [
            Container(),
            _buildFaceButton('y_button', 'X', ControllerTheme.yButton),
            Container(),
            _buildFaceButton('x_button', 'Y', ControllerTheme.xButton),
            Container(),
            _buildFaceButton('b_button', 'A', ControllerTheme.bButton),
            Container(),
            _buildFaceButton('a_button', 'B', ControllerTheme.aButton),
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
      child: _buildJoystick('right_stick', 120, Colors.blueGrey.shade700),
    );
  }

  Widget _buildDpad() {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.05,
      left: MediaQuery.of(context).size.width * 0.32, // Spostato più a sinistra
      child: Container(
        padding: const EdgeInsets.all(8),
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

  Widget _buildJoystick(String stickId, double size, Color color) {
    return SizedBox(
      width: size,
      height: size,
      child: Joystick(
        mode: JoystickMode.all,
        base: JoystickBase(
          size: size,
          decoration: JoystickBaseDecoration(
            color: color.withOpacity(0.5),
            //borderColor: Colors.black26,
            //borderWidth: 2,
            drawOuterCircle: true,
            drawArrows: false,
          ),
        ),
        stick: JoystickStick(
          size: size * 0.4,
          decoration: JoystickStickDecoration(
            color: ControllerTheme.stickButton,
            //borderColor: Colors.black26,
            //borderWidth: 1.5,
          ),
        ),
        //stickOffsetCalculator: const AlignCalc(),
        listener: (details) {
          // Convert joystick values to our format (-1 to 1)
          // The joystick package gives values from -1 to 1 directly
          double dx = details.x;
          double dy = details.y;
          
          // Apply deadzone
          final double distance = sqrt(dx * dx + dy * dy);
          if (distance < 0.15) {
            dx = dy = 0;
          }
          
          // Update state for visualization
          setState(() {
            final String stick = stickId.split('_')[0];
            analogInputs['${stick}_stick_x'] = dx;
            analogInputs['${stick}_stick_y'] = dy;
          });
          
          // Only send non-zero values to reduce traffic
          if (isConnected) {
            final String stick = stickId.split('_')[0];
            if (dx != 0 || dy != 0) {
              _socketService.sendAnalogInput(stick, dx, dy);
            } else {
              // Invia una volta lo zero per resettare la posizione
              _socketService.sendAnalogInput(stick, 0, 0);
            }
          }
        },
      ),
    );
  }

  void _sendInput(String key, dynamic value) {
    if (!isConnected) {
      // Show visual feedback for failed input when disconnected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not connected to server'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    developer.log('Button press: $key = $value');
    
    // Add visual feedback that input was sent
    if (showDebug) {
      // If debug mode is on, show input info on the screen temporarily
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Input sent: $key = $value'),
          backgroundColor: Colors.green.withOpacity(0.7),
          duration: Duration(milliseconds: 300),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.8,
            left: MediaQuery.of(context).size.width * 0.25,
            right: MediaQuery.of(context).size.width * 0.25,
          ),
        ),
      );
    }
    
    if (key.contains('stick')) {
      return;
    } else {
      _socketService.sendButtonInput(key, value as int);
    }
  }

  Widget _buildMenuOverlay() {
  // Directly check connection status from service when building menu
  final bool currentConnectionStatus = _socketService.isSocketConnected();
  
  // If there's a mismatch, update our state
  if (isConnected != currentConnectionStatus) {
    Future.microtask(() => setState(() {
      isConnected = currentConnectionStatus;
      print('Connection state corrected: $isConnected');
    }));
  }
  
  return Positioned(
    top: MediaQuery.of(context).size.height * 0.25,
    left: 0,
    right: 0,
    child: Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8, // More compact width
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(229),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Stack(
              children: [
                Center(
                  child: Text(
                    'Controller Menu',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: InkWell(
                    onTap: () => setState(() => showMenu = false),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white12,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: Colors.white24, height: 24),
            
            // Switches
            SwitchListTile(
              title: Text('Connection',
                  style: TextStyle(color: Colors.white)),
              value: connectionEnabled,
              dense: true,
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
              dense: true,
              onChanged: (bool value) =>
                  setState(() => showDebug = value),
            ),
            
            SizedBox(height: 8),
            
            // Status and Actions Row
            if (connectionEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status indicator and action buttons
                    Row(
                      children: [
                        // Status indicator
                        Row(
                          children: [
                            Icon(
                              isConnected ? Icons.check_circle : Icons.error,
                              color: isConnected ? Colors.green[300] : Colors.red[300],
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              isConnected ? 'Connected' : 'Disconnected',
                              style: TextStyle(
                                color: isConnected ? Colors.green[300] : Colors.red[300],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        
                        Spacer(),
                        
                        // Action buttons in the same row
                        ElevatedButton(
                          onPressed: _connectToServer,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size(10, 10),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Reconnect', style: TextStyle(fontSize: 12)),
                        ),
                        
                        SizedBox(width: 4),
                        
                        if (isConnected)
                          ElevatedButton.icon(
                            onPressed: () {
                              // Send a test button press
                              _socketService.sendButtonInput('a', 1);
                              Future.delayed(Duration(milliseconds: 200), () {
                                _socketService.sendButtonInput('a', 0);
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Test input sent!'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: Icon(Icons.gamepad, size: 14),
                            label: Text('Test', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size(10, 10),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Server Address
                    Text('Server Address:',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(height: 4),
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
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
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
    // Fix '_button' suffix handling to match the expected format
    final buttonId = '${id}_button';
    final bool isPressed = buttons[buttonId] ?? false;
    
    return GestureDetector(
      onTapDown: (_) {
        setState(() => buttons[buttonId] = true);
        _sendInput(buttonId, 1); 
      },
      onTapUp: (_) {
        setState(() => buttons[buttonId] = false);
        _sendInput(buttonId, 0);
      },
      onTapCancel: () {
        setState(() => buttons[buttonId] = false);
        _sendInput(buttonId, 0);
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
    _connectionMonitor?.cancel();
    super.dispose();
  }
}
