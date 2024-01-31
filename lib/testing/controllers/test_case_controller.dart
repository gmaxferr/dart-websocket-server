import 'dart:convert';
import 'package:dart_websocket_server/testing/models/test_case.dart';
import 'package:dart_websocket_server/testing/services/test_case_service.dart';

class TestCaseController {
  final TestCaseService _testCaseService;

  TestCaseController(this._testCaseService);

  // Handle HTTP request to create a new TestCase
  String createTestCase(String requestBody) {
    try {
      var data = json.decode(requestBody);
      var testCase = TestCase.fromJson(data);
      _testCaseService.createTestCase(testCase);
      return json.encode(
          {'status': 'success', 'message': 'TestCase created successfully'});
    } catch (e) {
      return json.encode({'status': 'error', 'message': e.toString()});
    }
  }

  // Handle HTTP request to retrieve a TestCase
  String getTestCase(String id) {
    try {
      var testCase = _testCaseService.getTestCase(id);
      if (testCase != null) {
        return json.encode(testCase.toJson());
      }
      return json.encode({'status': 'error', 'message': 'TestCase not found'});
    } catch (e) {
      return json.encode({'status': 'error', 'message': e.toString()});
    }
  }

  // Handle HTTP request to update a TestCase
  String updateTestCase(String id, String requestBody) {
    try {
      var data = json.decode(requestBody);
      var testCase = TestCase.fromJson(data);
      _testCaseService.updateTestCase(id, testCase);
      return json.encode(
          {'status': 'success', 'message': 'TestCase updated successfully'});
    } catch (e) {
      return json.encode({'status': 'error', 'message': e.toString()});
    }
  }

  // Handle HTTP request to delete a TestCase
  String deleteTestCase(String id) {
    try {
      _testCaseService.deleteTestCase(id);
      return json.encode(
          {'status': 'success', 'message': 'TestCase deleted successfully'});
    } catch (e) {
      return json.encode({'status': 'error', 'message': e.toString()});
    }
  }

  // Handle HTTP request to retrieve all TestCases
  String getAllTestCases() {
    try {
      var testCases = _testCaseService.getAllTestCases();
      return json.encode({
        'status': 'success',
        'data': testCases.map((tc) => tc.toJson()).toList()
      });
    } catch (e) {
      return json.encode({'status': 'error', 'message': e.toString()});
    }
  }
}
