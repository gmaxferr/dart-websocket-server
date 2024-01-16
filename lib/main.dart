import 'dart:io';
import 'websocket_server.dart';
import 'http_server.dart';
import 'device_manager.dart';
import 'database.dart';

class MultiServerHandler {
  static late MyHttpServer httpServer;
  static late WebSocketServer wsServer;
  final MyDatabase database;
  final DeviceManager deviceManager;

  MultiServerHandler(this.deviceManager, this.database);

  init() {
    // Retrieve ports from environment variables or use default values
    final int websocketPort =
        int.tryParse(Platform.environment['WEBSOCKET_PORT'] ?? '') ?? 9000;
    final int httpPort =
        int.tryParse(Platform.environment['HTTP_PORT'] ?? '') ?? 9001;
    final String _auxSchema = Platform.environment['HTTP_SCHEMA'] ?? '';
    final String _auxHost = Platform.environment['SERVER_HOST'] ?? '';
    final bool noPort = (Platform.environment['SHOW_PORT'] ?? '') == "n";
    final String httpSchema = _auxSchema.isEmpty ? 'http' : _auxSchema;
    final String hostname =
        _auxHost.isEmpty ? 'evcore.demo.glcharge.com' : _auxHost;

    // Initialize and start the WebSocket server
    wsServer = WebSocketServer(websocketPort, deviceManager, database);
    wsServer.start();

    // Initialize and start the HTTP server
    try {
      httpServer = MyHttpServer(
          httpSchema, hostname, httpPort, deviceManager, database, noPort);
      httpServer.start();
    } catch (err, trace) {
      print(err);
      print(trace);
      wsServer.stop();
      print("An error occured - all closed");
      return;
    }

    print(
        'Servers running. WebSocket on port $websocketPort and HTTP on port $httpPort.');
  }

  static Future<void> stopServerGracefully({Future Function()? onDone}) async {
    // Implement graceful shutdown logic
    // For HTTP server:
    await httpServer.stop(force: true);

    // For WebSocket server:
    wsServer.stop();
    if (onDone != null) {
      await onDone();
    }
  }
}

void main() async {
  // Initialize shared instances of DeviceManager and Database
  final database = MyDatabase();
  final deviceManager = DeviceManager(database);
  final handler = MultiServerHandler(deviceManager, database);

  handler.init();
}
