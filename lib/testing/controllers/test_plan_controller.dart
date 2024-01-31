import 'dart:convert';
import 'package:dart_websocket_server/testing/models/test_case.dart';
import 'package:dart_websocket_server/testing/models/test_plan.dart';
import 'package:dart_websocket_server/testing/services/test_plan_service.dart';

class TestPlanController {
  final TestPlanService _testPlanService;
  TestPlanController(this._testPlanService);

  // Handle HTTP request to create a new TestPlan
  String createTestPlan(String requestBody) {
    var data = json.decode(requestBody);
    var testPlan = TestPlan.fromJson(data);
    _testPlanService.createTestPlan(testPlan);
    return json.encode(
        {'status': 'success', 'message': 'TestPlan created successfully'});
  }

  // Handle HTTP request to retrieve a TestPlan
  String getTestPlan(String id) {
    var testPlan = _testPlanService.getTestPlan(id);
    if (testPlan != null) {
      return json.encode({'status': 'success', 'data': testPlan.toJson()});
    }
    return json.encode({'status': 'error', 'message': 'TestPlan not found'});
  }

  // Handle HTTP request to retrieve all TestPlans with certain ids
  String getTestPlansByIds(List<String> ids) {
    List<TestPlan> testPlans = [];
    for (final id in ids) {
      var testPlan = _testPlanService.getTestPlan(id);
      if (testPlan != null) {
        testPlans.add(testPlan);
      }
    }
    if (testPlans.isNotEmpty) {
    } else {
      return json.encode({'status': 'success', 'data': testPlans});
    }

    return json.encode({
      'status': 'error',
      'message': 'Did not find any TestPlans with given ids'
    });
  }

  // Handle HTTP request to retrieve all TestPlans
  String getAllTestPlans() {
    List<TestPlan> testPlans = _testPlanService.getAllTestPlans();
    if (testPlans.isNotEmpty) {
      return json.encode({
        'status': 'success',
        'data': testPlans.map((e) => e.toJson()).toList()
      });
    }
    return json.encode({'status': 'error', 'message': 'TestPlan not found'});
  }

  // Handle HTTP request to retrieve all TestPlans
  String getTestCasesByTestPlanId(String testPlanId) {
    List<TestCase> testCases =
        _testPlanService.getTestCasesOfTestPlan(testPlanId);
    if (testCases.isNotEmpty) {
      return json.encode({
        'status': 'success',
        'data': testCases.map((e) => e.toJson()).toList()
      });
    }
    return json.encode({
      'status': 'error',
      'message': 'TestPlan not found or has no test cases'
    });
  }

// Handle HTTP request to update TestPlan macros
  String updateTestPlanMacros(String testPlanId, String requestBody) {
    try {
      Map<String, dynamic> newMacros =
          json.decode(requestBody) as Map<String, dynamic>;
      _testPlanService.updateTestPlanMacros(testPlanId, newMacros);
      return json.encode({
        'status': 'success',
        'message': 'TestPlan macros updated successfully'
      });
    } catch (e) {
      return json.encode({'status': 'error', 'message': e.toString()});
    }
  }

  // Handle HTTP request to update a TestPlan
  String updateTestPlan(String id, String requestBody) {
    try {
      var data = json.decode(requestBody);
      var testPlan = TestPlan.fromJson(data);
      _testPlanService.updateTestPlan(id, testPlan);
      return json.encode(
          {'status': 'success', 'message': 'TestPlan updated successfully'});
    } catch (e) {
      return json.encode({'status': 'error', 'message': e.toString()});
    }
  }

  // Handle HTTP request to update a TestPlan
  String associateTestCaseToTestPlanWithId(
      String planId, Map<String, dynamic> data) {
    try {
      var testCase = TestCase.fromJson(data);
      _testPlanService.addTestCaseToTestPlan(planId, testCase);

      return json.encode(
          {'status': 'success', 'message': 'TestPlan updated successfully'});
    } catch (e) {
      return json.encode({'status': 'error', 'message': e.toString()});
    }
  }

  // Handle HTTP request to delete a TestPlan
  String deleteTestPlan(String id) {
    try {
      _testPlanService.deleteTestPlan(id);
      return json.encode(
          {'status': 'success', 'message': 'TestPlan deleted successfully'});
    } catch (e) {
      return json.encode({'status': 'error', 'message': e.toString()});
    }
  }
}
