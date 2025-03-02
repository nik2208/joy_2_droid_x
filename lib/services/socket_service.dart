import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:developer' as developer;

class SocketService {
  io.Socket? socket;
  bool isConnected = false;
  static const String LAST_SERVER_KEY = 'last_server';

  // HTTP fallback
  String? _serverUrl;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int MAX_RECONNECT_ATTEMPTS = 3;

  Future<void> connect(String address) async {
    // Cleanup any existing connection
    disconnect();
    _reconnectAttempts = 0;

    // Store address for fallback
    if (!address.contains('://')) {
      _serverUrl = 'http://$address';
    } else {
      _serverUrl = address;
    }

    print('Trying to connect to $_serverUrl...');
    _connectSocketIO();
  }

  void _connectSocketIO() {
    try {
      socket = io.io(
        _serverUrl!,
        <String, dynamic>{
          'transports': ['websocket', 'polling'],
          'autoConnect': true,
          'forceNew': true,
          'reconnection': true,
          'reconnectionAttempts': 3,
          'reconnectionDelay': 1000,
          'timeout': 10000,
          'extraHeaders': {'Origin': 'flutter-joy2droidx'},
        },
      );

      socket!.onConnect((_) {
        print('Connected to server successfully!');
        isConnected = true; // Set to true on connect
        _reconnectAttempts = 0;
        
        // Request Xbox controller immediately after connection
        socket!.emit('xbox');
      });

      socket!.onConnectError((error) {
        print('Socket.IO connection error: $error');
        isConnected = false; // Set to false on error
        _reconnectAttempts++;
        
        if (_reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
          print('Max reconnection attempts reached, trying HTTP fallback');
          _tryHttpFallback();
        }
      });

      socket!.onDisconnect((_) {
        print('Disconnected from server');
        isConnected = false; // Set to false on disconnect
      });

      // If not connected after 5 seconds, try HTTP fallback
      Future.delayed(Duration(seconds: 5), () {
        if (!socket!.connected) {
          print('Socket.IO connection timeout, trying HTTP fallback');
          isConnected = false; // Make sure flag is updated
          _tryHttpFallback();
        }
      });
    } catch (e) {
      print('Exception during socket setup: $e');
      isConnected = false; // Set to false on exception
      _tryHttpFallback();
    }
  }

  void _tryHttpFallback() {
    // Clean up socket if it exists
    if (socket != null) {
      if (socket!.connected) {
        socket!.disconnect();
      }
      socket!.dispose();
      socket = null;
    }

    // Try to connect via HTTP
    _httpConnect();
  }

  Future<void> _httpConnect() async {
    try {
      // Simple connection test
      final response = await http.get(Uri.parse('$_serverUrl/status'));

      if (response.statusCode == 200) {
        print('HTTP fallback connection successful');
        isConnected = true;

        // Request controller creation
        await _httpSendMessage('xbox', {});

        // Start heartbeat
        _startHeartbeat();
      } else {
        print('HTTP fallback failed with status: ${response.statusCode}');
        isConnected = false;
      }
    } catch (e) {
      print('HTTP fallback exception: $e');
      isConnected = false;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (isConnected) {
        _httpSendMessage('ping', {});
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _httpSendMessage(String event, dynamic data) async {
    if (!isConnected) return;

    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/message'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'event': event,
          'data': data,
        }),
      );

      if (response.statusCode != 200) {
        print('HTTP message failed: ${response.statusCode}');
      }
    } catch (e) {
      print('HTTP send error: $e');
      isConnected = false;
    }
  }

  bool isSocketConnected() {
    // Check both our flag and the actual socket connection
    return isConnected && (socket?.connected ?? false);
  }

  void sendButtonInput(String button, int value) {
    if (!isConnected) return;

    // Fix button mappings for menu, back, and trigger buttons
    final String mappedButton = switch (button.replaceAll('_button', '')) {
      'a' => 'a-button',
      'b' => 'b-button',
      'x' => 'x-button',
      'y' => 'y-button',
      'left_bumper' => 'left-bumper',
      'right_bumper' => 'right-bumper',
      'left_trigger' => 'zl-button',        // Fixed: now maps to ZL (minus button)
      'right_trigger' => 'zr-button',       // Fixed: now maps to ZR (plus button)
      'back' => 'select-button',            // Fixed: now maps to select (back) button
      'start' => 'start-button',            // Fixed: now maps to start (menu) button
      'up' => 'dpad-up',                    // Fixed: use dpad- prefix for D-pad
      'down' => 'dpad-down',                // Fixed: use dpad- prefix for D-pad
      'left' => 'dpad-left',                // Fixed: use dpad- prefix for D-pad
      'right' => 'dpad-right',              // Fixed: use dpad- prefix for D-pad
      _ => button,
    };

    final boolValue = value == 1;
    final payload = {
      'key': mappedButton,
      'value': boolValue,
    };
    
    // Add detailed debug output
    print('[OUTGOING] Button Input: ${json.encode(payload)}');
    developer.log('SENDING: Button $mappedButton=${boolValue}', name: 'J2DX');

    try {
      if (socket != null && socket!.connected) {
        socket?.emit('input', payload);
      } else {
        _httpSendMessage('input', payload);
      }
    } catch (e) {
      print('Error sending button input: $e');
    }
  }

  // Variabili per ottimizzare gli invii analogici
  final Map<String, double> _lastSentAnalogX = {};
  final Map<String, double> _lastSentAnalogY = {};
  static const double ANALOG_THRESHOLD = 0.02; // Soglia minima di cambiamento per inviare un nuovo valore

  void sendAnalogInput(String stick, double x, double y) {
    if (!isConnected) return;

    final String mappedStick = switch (stick) {
      'left' => 'left-stick',
      'right' => 'right-stick',
      _ => stick,
    };
    
    // Ottimizzazione: invia solo se il valore è cambiato significativamente
    final String xKey = '$mappedStick-X';
    final String yKey = '$mappedStick-Y';
    
    final double lastX = _lastSentAnalogX[xKey] ?? 0.0;
    final double lastY = _lastSentAnalogY[yKey] ?? 0.0;
    
    // Fix the left stick's Y-axis inversion - for left stick we need to negate Y
    final double adjustedY = (stick == 'left') ? y : -y;
    
    // Verifica se i valori sono cambiati abbastanza da essere inviati
    final bool shouldSendX = (x - lastX).abs() > ANALOG_THRESHOLD;
    final bool shouldSendY = (adjustedY - lastY).abs() > ANALOG_THRESHOLD;
    
    if (shouldSendX || shouldSendY) {
      // Aggiorna i valori memorizzati
      if (shouldSendX) {
        _lastSentAnalogX[xKey] = x;
        final payloadX = {'key': xKey, 'value': x};
        
        print('[OUTGOING] Analog Input X: ${json.encode(payloadX)}');
        developer.log('SENDING: $mappedStick X=$x', name: 'J2DX');
        
        _sendInputPayload(payloadX);
      }
      
      if (shouldSendY) {
        _lastSentAnalogY[yKey] = adjustedY;
        final payloadY = {'key': yKey, 'value': adjustedY};
        
        print('[OUTGOING] Analog Input Y: ${json.encode(payloadY)}');
        developer.log('SENDING: $mappedStick Y=$adjustedY', name: 'J2DX');
        
        _sendInputPayload(payloadY);
      }
    }
  }
  
  // Helper per evitare duplicazione codice
  void _sendInputPayload(Map<String, dynamic> payload) {
    try {
      if (socket != null && socket!.connected) {
        socket?.emit('input', payload);
      } else {
        _httpSendMessage('input', payload);
      }
    } catch (e) {
      print('Error sending input: $e');
    }
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (socket != null) {
      try {
        socket!.disconnect();
        socket!.dispose();
      } catch (e) {
        print('Error during socket disconnect: $e');
      }
      socket = null;
    }

    isConnected = false;
  }

  Future<void> saveLastServer(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LAST_SERVER_KEY, address);
  }

  Future<String?> getLastServer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(LAST_SERVER_KEY);
  }
}
