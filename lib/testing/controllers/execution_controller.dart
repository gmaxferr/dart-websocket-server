import 'dart:convert';
import 'package:dart_websocket_server/testing/services/execution_service.dart';

class ExecutionController {
  final ExecutionService _executionService;

  ExecutionController(this._executionService);

  // Handle HTTP request to execute a TestPlan
  Future<String> executeTestPlan(String deviceId, String testPlanId) async {
    try {
      var result =
          await _executionService.executeTestPlan(testPlanId, deviceId);
      return json.encode({'status': 'success', 'result': result.toJson()});
    } catch (e) {
      return json.encode({'status': 'error', 'message': e.toString()});
    }
  }

  // Handle HTTP request to fetch the latest TestPlanResults
  String fetchLatestExecutions(String? deviceId) {
    try {
      List<Map<String, dynamic>> results;
      if (deviceId != null && deviceId.isNotEmpty) {
        results = _executionService.fetchLatestExecutionsForDevice(deviceId);
      } else {
        results = _executionService.fetchLatestExecutions();
      }

      return json.encode({'status': 'success', 'results': results});
    } catch (e) {
      return json.encode({'status': 'error', 'message': e.toString()});
    }
  }

  // Handle HTTP request to delete a Test plan result
  String deleteTestPlanResult(String testPlanResultId) {
    try {
      _executionService.deleteTestPlanResultById(testPlanResultId);

      return json.encode({
        'status': 'success',
        'message': 'TestPlanResult successufully deleted'
      });
    } catch (e) {
      return json.encode({'status': 'error', 'message': e.toString()});
    }
  }

  // Handle HTTP request to fetch the TestPlanResults by it's status
  String getTestPlanResultByStatus(String deviceId, int status) {
    try {
      final result = _executionService.getTestPlanDeviceIdAndByStatus(deviceId, status);

      return json.encode({
        'status': 'success',
        'data': result
      });
    } catch (e) {
      return json.encode({'status': 'error', 'message': e.toString()});
    }
  }

  List<Map<String, dynamic>>? getTestPlanByIdAndDeviceId(
      String? deviceId, List<String>? testPlanIds) {
    return _executionService.getTestPlanByIdAndDeviceId(deviceId, testPlanIds);
  }
}
