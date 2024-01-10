import 'dart:io';
import 'websocket_server.dart';
import 'http_server.dart';
import 'device_manager.dart';
import 'database.dart';

void main() async {
  // Initialize shared instances of DeviceManager and Database
  final database = MyDatabase();
  final deviceManager = DeviceManager(database);

  // Retrieve ports from environment variables or use default values
  final int websocketPort =
      int.tryParse(Platform.environment['WEBSOCKET_PORT'] ?? '') ?? 9000;
  final int httpPort =
      int.tryParse(Platform.environment['HTTP_PORT'] ?? '') ?? 9001;
  final String httpSchema = Platform.environment['HTTP_SCHEMA'] ?? 'http';
  final String hostname = Platform.environment['SERVER_HOST'] ?? '';

  // Initialize and start the WebSocket server
  final websocketServer =
      WebSocketServer(websocketPort, deviceManager, database);
  websocketServer.start();

  // Initialize and start the HTTP server
  try {
    final httpServer =
        MyHttpServer(httpSchema, hostname, httpPort, deviceManager, database);
    httpServer.start();
  } catch (err, trace) {
    print(err);
    print(trace);
    websocketServer.stop();
    print("An error occured - all closed");
    return;
  }

  print(
      'Servers running. WebSocket on port $websocketPort and HTTP on port $httpPort.');
}
