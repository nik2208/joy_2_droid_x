import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;
  static const String LAST_SERVER_KEY = 'last_server';

  Future<void> connect(String address) async {
    socket = IO.io(address, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket!.onConnect((_) {
      // Salva l'ultimo server utilizzato
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(LAST_SERVER_KEY, address);
      });

      // Invia messaggio di identificazione
      socket!.emit('intro',
          {'device': 'Flutter Controller', 'id': 'x360', 'type': 'Xbox 360'});
    });

    socket!.connect();
  }

  void sendButtonInput(String button, [int value = 1]) {
    socket?.emit('input', {'key': button, 'value': value});
  }

  void sendAnalogInput(String stick, double x, double y) {
    socket?.emit('input', {'key': '$stick-X', 'value': x});
    socket?.emit('input', {'key': '$stick-Y', 'value': y});
  }

  void sendDpadInput(String direction) {
    socket?.emit('input', {'key': direction, 'value': 1});
  }

  void sendTriggerInput(String trigger, double value) {
    socket?.emit('input', {'key': trigger, 'value': value});
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}
