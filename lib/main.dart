import 'dart:io';

import 'package:dart_websocket_server/core/http_server.dart';
import 'package:dart_websocket_server/core/websocket_server.dart';
import 'package:dart_websocket_server/database/database.dart';
import 'package:dart_websocket_server/database/testing_database.dart';
import 'package:dart_websocket_server/device_management/device_manager.dart';
import 'package:dart_websocket_server/testing/controllers/execution_controller.dart';
import 'package:dart_websocket_server/testing/controllers/test_case_controller.dart';
import 'package:dart_websocket_server/testing/controllers/test_plan_controller.dart';
import 'package:dart_websocket_server/testing/helpers/macro_processor.dart';
import 'package:dart_websocket_server/testing/services/execution_service.dart';
import 'package:dart_websocket_server/testing/services/test_case_service.dart';
import 'package:dart_websocket_server/testing/services/test_plan_service.dart';

class MultiServerHandler {
  static late MyHttpServer httpServer;
  static late WebSocketServer wsServer;
  final MyDatabase database;
  final DeviceManager deviceManager;
  final ExecutionController? executionController;
  final TestPlanController? testPlanController;
  final TestCaseController? testCaseController;

  MultiServerHandler(
    this.deviceManager,
    this.database,
    this.executionController,
    this.testPlanController,
    this.testCaseController,
  );

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
        httpSchema,
        hostname,
        httpPort,
        deviceManager,
        database,
        noPort,
        executionController,
        testPlanController,
        testCaseController,
      );

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
  final bool enableTestingUseCase =
      (Platform.environment['DISABLE_TESTING'] ?? '') == "n";
  final database = MyDatabase();
  final deviceManager = DeviceManager(database);

  ExecutionController? executionController;
  TestPlanController? testPlanController;
  TestCaseController? testCaseController;
  if (enableTestingUseCase) {
    final testingDatabase = TestingDatabase();

    final macroProcessor = MacroProcessor({});
    final executionService =
        ExecutionService(testingDatabase, deviceManager, macroProcessor);
    final testPlanService = TestPlanService(testingDatabase);
    final testCaseService = TestCaseService(testingDatabase);

    executionController = ExecutionController(executionService);
    testPlanController = TestPlanController(testPlanService);
    testCaseController = TestCaseController(testCaseService);
  }

  final handler = MultiServerHandler(
    deviceManager,
    database,
    executionController,
    testPlanController,
    testCaseController,
  );

  handler.init();
}
