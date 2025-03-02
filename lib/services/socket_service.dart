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

  Future<void> connect(String address) async {
    // Cleanup any existing connection
    disconnect();

    // Store address for fallback
    if (!address.contains('://')) {
      _serverUrl = 'http://$address';
    } else {
      _serverUrl = address;
    }

    print('Trying to connect to $_serverUrl...');

    try {
      // First try regular Socket.IO
      socket = io.io(
        _serverUrl!,
        {
          'transports': ['polling'],
          'autoConnect': false,
          'forceNew': true,
        },
      );

      socket!.onConnect((_) {
        print('Connected to server successfully!');
        isConnected = true;
        socket!.emit('intro', {'device': 'Flutter', 'id': 'x360'});
      });

      socket!.onConnectError((error) {
        print('Socket.IO connection error: $error');
        _tryHttpFallback();
      });

      socket!.onDisconnect((_) {
        print('Disconnected from server');
        isConnected = false;
      });

      socket!.connect();

      // If not connected after 3 seconds, try HTTP fallback
      Future.delayed(Duration(seconds: 3), () {
        if (!isConnected) {
          print('Socket.IO connection timeout, trying HTTP fallback');
          _tryHttpFallback();
        }
      });
    } catch (e) {
      print('Exception during socket setup: $e');
      _tryHttpFallback();
    }
  }

  void _tryHttpFallback() {
    // Clean up socket if it exists
    socket?.disconnect();
    socket?.dispose();
    socket = null;

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

        // Start heartbeat
        _startHeartbeat();

        // Send intro
        _httpSendMessage(
            'intro', {'device': 'Flutter Controller', 'id': 'x360'});
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
    return isConnected;
  }

  void sendButtonInput(String button, int value) {
    if (!isConnected) return;

    final String mappedButton = switch (button.replaceAll('_button', '')) {
      'a' => 'a-button',
      'b' => 'b-button',
      'x' => 'x-button',
      'y' => 'y-button',
      'left_bumper' => 'left-bumper',
      'right_bumper' => 'right-bumper',
      'left_trigger' => 'left-trigger',
      'right_trigger' => 'right-trigger',
      'back' => 'back-button',
      'start' => 'start-button',
      'up' => 'up-button',
      'down' => 'down-button',
      'left' => 'left-button',
      'right' => 'right-button',
      _ => button,
    };

    try {
      if (socket != null && socket!.connected) {
        socket?.emit('input', {
          'key': mappedButton,
          'value': value == 1,
        });
      } else {
        _httpSendMessage('input', {
          'key': mappedButton,
          'value': value == 1,
        });
      }
      developer.log('Button sent: $mappedButton=${value == 1}');
    } catch (e) {
      print('Error sending button input: $e');
    }
  }

  void sendAnalogInput(String stick, double x, double y) {
    if (!isConnected) return;

    final String mappedStick = switch (stick) {
      'left' => 'left-stick',
      'right' => 'right-stick',
      _ => stick,
    };

    try {
      if (socket != null && socket!.connected) {
        socket?.emit('input', {'key': '$mappedStick-X', 'value': x});
        socket?.emit('input', {'key': '$mappedStick-Y', 'value': -y});
      } else {
        _httpSendMessage('input', {'key': '$mappedStick-X', 'value': x});
        _httpSendMessage('input', {'key': '$mappedStick-Y', 'value': -y});
      }
      developer.log('Analog sent: $mappedStick X=$x Y=${-y}');
    } catch (e) {
      print('Error sending analog input: $e');
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
