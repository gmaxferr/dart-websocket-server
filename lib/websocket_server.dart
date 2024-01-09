import 'dart:io';
import 'package:dart_websocket_server/database.dart';

import 'device_manager.dart';

class WebSocketServer {
  late HttpServer _server;
  final int port;
  final DeviceManager deviceManager;
  final MyDatabase database;

  WebSocketServer(this.port, this.deviceManager, this.database);

  Future<void> start({HttpServer? server}) async {
    _server = server ?? await HttpServer.bind(InternetAddress.anyIPv4, port);
    print('WebSocket Server is running on ws://localhost:$port');

    await for (var request in _server) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        // Extract the deviceId from the request URL.
        final deviceId = extractDeviceId(request.uri.path);
        if (deviceId != null) {
          var socket = await WebSocketTransformer.upgrade(request);
          handleConnection(socket, deviceId);
        } else {
          // If the deviceId is not present in the URL, reject the request.
          request.response
            ..statusCode = HttpStatus.badRequest
            ..close();
        }
      } else {
        // Normal HTTP requests not handled here
        request.response
          ..statusCode = HttpStatus.forbidden
          ..close();
      }
    }
  }

  void stop(){
    print("Stopping Websocket Server...");
    _server.close(force: true);
  }

  void handleConnection(WebSocket socket, String deviceId) {
    var isAdded = deviceManager.addDevice(deviceId, socket);
    if (!isAdded) {
      socket.add('Device ID already in use. Disconnecting.');
      socket.close();
      return;
    }

    socket.listen((data) {
      // Handle messages from the connected device.
      handleMessage(deviceId, data);
    }, onDone: () {
      // Handle disconnection.
      deviceManager.removeDevice(deviceId);
    }, onError: (error) {
      print('Error on socket for device $deviceId: $error');
      deviceManager.removeDevice(deviceId);
    });
  }

  void handleMessage(String deviceId, String message) async {
    print('Message from device $deviceId: $message');

    // Store the message in the database
    database.storeMessage(deviceId, message, deviceId);
  }

  String? extractDeviceId(String path) {
    var segments = path.split('/');
    // Assuming the path format is "/<deviceID>", adjust if necessary.
    if (segments.length == 2 && segments[1].isNotEmpty) {
      return segments[1];
    }
    return null;
  }
}
