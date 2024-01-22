import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dart_websocket_server/database/database.dart';
import 'package:dart_websocket_server/device_management/device_manager.dart';
import 'package:dart_websocket_server/main.dart';
import 'package:dart_websocket_server/testing/models/test_case.dart';
import 'package:dart_websocket_server/testing/models/test_plan.dart';
import 'package:dart_websocket_server/testing/testing_manager.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

class MyHttpServer {
  final DeviceManager deviceManager;
  final MyDatabase database;
  final TestingManager? testingManager;
  final int port;
  final String httpSchema;
  final String hostname;
  final bool noPortInAPI;

  late HttpServer _server;

  MyHttpServer(this.httpSchema, this.hostname, this.port, this.deviceManager,
      this.database, this.noPortInAPI, this.testingManager);

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

    router.post('/deleteDatabase', (Request request) async {
      database.deleteAll();
      return Response.ok('Database deleted!');
    });

    router.get('/getAllClients', (Request request) async {
      final zipFileBytes = await createAllClientsZip();
      return Response.ok(zipFileBytes, headers: {
        HttpHeaders.contentTypeHeader: 'application/zip',
        HttpHeaders.contentDisposition: 'attachment; filename="all_clients.zip"'
      });
    });

    router.get('/device-status/<deviceId>',
        (Request request, String deviceId) async {
      final connectedIds = deviceManager.getConnectedDeviceIds();
      if (connectedIds.contains(deviceId)) {
        return Response.ok("Device Connected");
      } else {
        return Response.notFound("Device not connected");
      }
    });

    router.get('/force-update', (Request request) async {
      // After sending the response, schedule the restart
      Timer(Duration(seconds: 1), () async {
        MultiServerHandler.stopServerGracefully(onDone: () async {
          print("running `restart_server.sh`");
          await Process.run('/bin/bash', ['lib/restart_server.sh']);
          print("Waiting 10s until complete shutdown");
          await Future.delayed(Duration(seconds: 10));
        });
      });
      // Respond with 200 OK
      return Response.ok('Server will restart in order to update...');
    });

    // Route to return the server version (Git commit ID)
    router.get('/server-version', (Request request) {
      final serverVersion = Platform.environment['GIT_COMMIT_ID'] ?? 'unknown';
      return Response.ok('$serverVersion');
    });

    // Route to serve index.html
    router.get('/simple-client', (Request request) async {
      // Adjusted path to match the new location of index.html
      final indexPath = path.join(
          Directory.current.path, 'lib', 'pages', 'simple-client.html');
      final file = File(indexPath);

      if (await file.exists()) {
        var content = await file.readAsString();

        // Inject environment variables into HTML
        content = content.replaceAll('{{API_SCHEMA}}', httpSchema);
        content = content.replaceAll('{{API_ENDPOINT}}', hostname);
        content = content.replaceAll('{{API_PORT}}', "$port");
        return Response.ok(content, headers: {'Content-Type': 'text/html'});
      } else {
        return Response.notFound('Page not found');
      }
    });

    // Route to serve index.html
    router.get('/ocpp-client', (Request request) async {
      // Adjusted path to match the new location of index.html
      final indexPath =
          path.join(Directory.current.path, 'lib', 'pages', 'ocpp-client.html');
      final file = File(indexPath);

      if (await file.exists()) {
        var content = await file.readAsString();

        // Inject environment variables into HTML
        content = content.replaceAll('{{API_SCHEMA}}', httpSchema);
        if (noPortInAPI) {
          content =
              content.replaceAll('{{API_ENDPOINT}}:{{API_PORT}}', hostname);
        } else {
          content = content.replaceAll('{{API_ENDPOINT}}', hostname);
          content = content.replaceAll('{{API_PORT}}', "$port");
        }
        return Response.ok(content, headers: {'Content-Type': 'text/html'});
      } else {
        return Response.notFound('Page not found');
      }
    });

    // Route to get a TestPlan by ID
    router.get('/testing-enabled', (Request request) async {
      if (this.testingManager == null) {
        return Response.ok(
            'Testing Features are not enabled. Please check the Readme.md',
            headers: {'Content-Type': 'application/json'});
      }
      return Response.ok(
          'Testing Features are enabled',
          headers: {'Content-Type': 'application/json'});
    });

    // Default route for handling non-existent routes
    router.all('/<ignored|.*>', (Request request) {
      final path = request.requestedUri.path;
      return Response.notFound('Route not found ($path)');
    });

    _addTestingManagerEndpoints(router);

    return router;
  }

  void _addTestingManagerEndpoints(Router router) {
    if (testingManager == null) return;

    // Route to get a TestPlan by ID
    router.get('/getAllTestPlans', (Request request) async {
      List<TestPlan> allTestPlans = testingManager!.getAllTestPlans();
      if (allTestPlans.isNotEmpty) {
        return Response.ok(
            jsonEncode(allTestPlans.map((e) => e.toMap()).toList()),
            headers: {'Content-Type': 'application/json'});
      }
      return Response.notFound('No TestPlans found in database',
          headers: {'Content-Type': 'application/json'});
    });

    // Route to get a TestPlan by ID
    router.get('/testPlan/<id>', (Request request, String id) async {
      int testPlanId = int.parse(id);
      TestPlan? testPlan = testingManager!.getTestPlanById(testPlanId);
      if (testPlan != null) {
        return Response.ok(jsonEncode(testPlan.toMap()),
            headers: {'Content-Type': 'application/json'});
      }
      return Response.notFound('TestPlan not found',
          headers: {'Content-Type': 'application/json'});
    });

    // Route to get all TestCases for a TestPlan
    router.get('/testCases/<testPlanId>',
        (Request request, String testPlanId) async {
      try {
        int id = int.parse(testPlanId);
        var testCases = testingManager!.getTestCasesByTestPlanId(id);
        return Response.ok(
            jsonEncode(testCases.map((tc) => tc.toMap()).toList()),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.notFound('TestCases not found');
      }
    });

    // Route to get TestPlan by status for a specific deviceId
    router.get('/getTestPlanByStatus/<deviceId>/<status>',
        (Request request, String deviceId, String status) async {
      try {
        var testPlans = testingManager!.getTestPlanByStatus(deviceId, status);
        return Response.ok(
            jsonEncode(testPlans.map((tp) => tp.toMap()).toList()),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.notFound('TestPlans not found for status $status');
      }
    });

    // Route to get a TestCase by ID
    router.get('/getTestCaseById/<id>', (Request request, String id) async {
      int testCaseId = int.parse(id);
      TestCase? testCase = testingManager!.getTestCaseById(testCaseId);
      if (testCase != null) {
        return Response.ok(jsonEncode(testCase.toMap()),
            headers: {'Content-Type': 'application/json'});
      }
      return Response.notFound(jsonEncode(testCase!.toMap()),
          headers: {'Content-Type': 'application/json'});
    });

    // Route to get TestPlans by a list of IDs
    router.post('/getTestPlansByIds', (Request request) async {
      try {
        var ids = jsonDecode(await request.readAsString()) as List<dynamic>;
        var testPlans = testingManager!.getTestPlansByIds(ids.cast<int>());
        return Response.ok(
            jsonEncode(testPlans.map((tp) => tp.toMap()).toList()),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: 'Error processing request');
      }
    });

    // Route to get TestPlans by Device ID
    router.get('/getTestPlansByDeviceId/<deviceId>',
        (Request request, String deviceId) async {
      var testPlans = testingManager!.getTestPlansByDeviceId(deviceId);
      if (testPlans.isEmpty) {
        return Response.notFound('TestPlans not found for deviceId $deviceId');
      }
      return Response.ok(jsonEncode(testPlans.map((tp) => tp.toMap()).toList()),
          headers: {'Content-Type': 'application/json'});
    });
  }

  Future<List<int>> createChatHistoryZip() async {
    // Create a new archive
    final archive = Archive();
    final ids = await database.getAllDeviceIdsInDatabase();
    // Add chat history files for each device
    for (var deviceId in ids) {
      final messages = (await database.getMessages(deviceId))
          .map((m) =>
              "${m.timestamp} ${m.sender == "server" ? "[SERVER] " : "[CHARGER]"} sent: '${m.content}'")
          .toList();
      final fileName = '$deviceId.txt';
      final fileContent = messages.join("\n");

      // Add a file to the archive
      final file =
          ArchiveFile(fileName, fileContent.length, fileContent.codeUnits);
      archive.addFile(file);
    }

    // Encode the archive as a ZIP
    return ZipEncoder().encode(archive) ?? [];
  }

  Future<List<int>> createAllClientsZip() async {
    final archive = Archive();

    // Define the path to the HTML directory
    final htmlDirPath = path.join(Directory.current.path, 'lib', 'pages');
    print(htmlDirPath);
    final htmlDir = Directory(htmlDirPath);

    // Check if the directory exists
    if (await htmlDir.exists()) {
      // List all HTML files
      final List<FileSystemEntity> files = htmlDir.listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.html')) {
          final fileName = path.basename(file.path);

          var fileContent = await file.readAsString();
          fileContent = fileContent.replaceAll('{{API_SCHEMA}}', httpSchema);
          fileContent = fileContent.replaceAll('{{API_ENDPOINT}}', hostname);
          fileContent = fileContent.replaceAll('{{API_PORT}}', "$port");

          final fileBytes = utf8.encode(fileContent);

          // Add the file to the archive
          archive.addFile(ArchiveFile(fileName, fileBytes.length, fileBytes));
        }
      }
    }

    // Encode the archive as a ZIP
    return ZipEncoder().encode(archive) ?? [];
  }

  Future<void> start() async {
    _server = await io.serve(_corsHeadersMiddleware().addHandler(handler),
        InternetAddress.anyIPv4, port);
    print('HTTP Server running on http://localhost:${_server.port}');
  }

  Future<void> stop({bool force = false}) async {
    await _server.close(force: force);
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
