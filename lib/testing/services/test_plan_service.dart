import 'package:dart_websocket_server/database/testing_database.dart';
import 'package:dart_websocket_server/testing/models/test_case.dart';
import 'package:dart_websocket_server/testing/models/test_plan.dart';

class TestPlanService {
  final TestingDatabase _database;

  TestPlanService(this._database);

  // Create a new TestPlan
  void createTestPlan(TestPlan testPlan) {
    _database.insertTestPlan(testPlan.toJson());
  }

  // Retrieve a TestPlan by ID
  TestPlan? getTestPlan(String id) {
    var data = _database.getTestPlan(id);
    if (data != null) {
      return TestPlan.fromJson(data);
    }
    return null;
  }

  // Update an existing TestPlan
  void updateTestPlan(String id, TestPlan testPlan) {
    _database.updateTestPlan(id, testPlan.toJson());
  }

  // Delete a TestPlan
  void deleteTestPlan(String id) {
    final list = _database.getTestCasesOfTestPlan(id);
    if (list.isEmpty) return;
    List<TestCase> tcs = list.map(TestCase.fromJson).toList();

    for (var tc in tcs) {
      _database.deleteTestCase(tc.id);
    }

    _database.deleteTestPlan(id);
  }

  // Method to update macros of a TestPlan
  void updateTestPlanMacros(String testPlanId, Map<String, dynamic> newMacros) {
    var _testPlan = _database.getTestPlan(testPlanId);
    if (_testPlan != null) {
      TestPlan testPlan = TestPlan.fromJson(_testPlan);
      testPlan.macros = newMacros;
      _database.updateTestPlan(testPlanId, testPlan.toJson());
    } else {
      throw Exception('TestPlan not found');
    }
  }

// Retrieve all TestPlans
  List<TestPlan> getAllTestPlans() {
    var dataList = _database.getAllTestPlans();
    return dataList.map((data) => TestPlan.fromJson(data)).toList();
  }

  // Add a TestCase to a TestPlan
  void addTestCaseToTestPlan(String testPlanId, TestCase testCase) {
    // Assuming the logic to link TestCase to TestPlan is implemented in DatabaseHelper
    _database.addTestCaseToTestPlan(testPlanId, testCase.toJson());
  }

  // Remove a TestCase from a TestPlan
  void removeTestCaseFromTestPlan(String testPlanId, String testCaseId) {
    // Assuming the logic to unlink TestCase from TestPlan is implemented in DatabaseHelper
    _database.removeTestCaseFromTestPlan(testPlanId, testCaseId);
  }

  // Get TestCases of a TestPlan
  List<TestCase> getTestCasesOfTestPlan(String testPlanId) {
    var dataList = _database.getTestCasesOfTestPlan(testPlanId);
    return dataList.map((data) => TestCase.fromJson(data)).toList();
  }
}
