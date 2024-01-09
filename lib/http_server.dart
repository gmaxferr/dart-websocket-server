import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'device_manager.dart';
import 'database.dart';

class MyHttpServer {
  final DeviceManager deviceManager;
  final MyDatabase database;
  final int port;

  late HttpServer _server;

  MyHttpServer(this.port, this.deviceManager, this.database);

  Handler get handler {
    final router = Router();

    // Endpoint to send a message to a connected device
    router.post('/sendMessage/<deviceId>',
        (Request request, String deviceId) async {
      if (!deviceManager.isConnected(deviceId)) {
        return Response.notFound('Device not connected');
      }

      String messageContent = await request.readAsString();
      if (await deviceManager.sendMessage(deviceId, messageContent)) {
        database.storeMessage(deviceId, messageContent, 'server');
        return Response.ok('Message sent');
      } else {
        return Response.internalServerError(body: 'Failed to send message');
      }
    });

    // Endpoint to retrieve message history for a device
    router.get('/getHistory/<deviceId>',
        (Request request, String deviceId) async {
      final messages =
          (await database.getMessages(deviceId)).map((m) => m.toMap()).toList();
      return Response.ok(jsonEncode(messages),
          headers: {'Content-Type': 'application/json'});
    });

    router.get('/downloadChatHistory', (Request request) async {
      final zipFileBytes = await createChatHistoryZip();
      return Response.ok(zipFileBytes, headers: {
        HttpHeaders.contentTypeHeader: 'application/zip',
        HttpHeaders.contentDisposition:
            'attachment; filename="chat_history.zip"'
      });
    });

    return router;
  }

  Future<List<int>> createChatHistoryZip() async {
    // Create a new archive
    final archive = Archive();
    final ids = await database.getAllDeviceIdsInDatabase();
    // Add chat history files for each device
    for (var deviceId in ids) {
      final messages =
          (await database.getMessages(deviceId)).map((m) => m.toMap()).toList();
      final fileName = '$deviceId.txt';
      final fileContent = jsonEncode(messages);

      // Add a file to the archive
      final file =
          ArchiveFile(fileName, fileContent.length, fileContent.codeUnits);
      archive.addFile(file);
    }

    // Encode the archive as a ZIP
    return ZipEncoder().encode(archive) ?? [];
  }

  Future<void> start() async {
    _server = await io.serve(_corsHeadersMiddleware().addHandler(handler),
        InternetAddress.anyIPv4, port);
    print('HTTP Server running on http://localhost:${_server.port}');
  }

  Future<void> stop() async {
    await _server.close();
  }
}

// Middleware for setting CORS headers
Middleware _corsHeadersMiddleware() {
  return createMiddleware(
    requestHandler: (Request request) {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*', // Adjust as needed
          'Access-Control-Allow-Headers': 'Content-Type',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        });
      }
      return null;
    },
    responseHandler: (Response response) {
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*', // Adjust as needed
        // Add other headers as needed
      });
    },
  );
}
