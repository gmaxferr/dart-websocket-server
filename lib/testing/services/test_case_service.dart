import 'package:dart_websocket_server/database/testing_database.dart';
import 'package:dart_websocket_server/testing/models/test_case.dart';

class TestCaseService {
  final TestingDatabase _database;

  TestCaseService(this._database);

  // Create a new TestCase
  void createTestCase(TestCase testCase) {
    _database.insertTestCase(testCase.toJson());
  }

  // Retrieve a TestCase by ID
  TestCase? getTestCase(String id) {
    var data = _database.getTestCase(id);
    if (data != null) {
      return TestCase.fromJson(data);
    }
    return null;
  }

  // Update an existing TestCase
  void updateTestCase(String id, TestCase testCase) {
    _database.updateTestCase(id, testCase.toJson());
  }

  // Delete a TestCase
  void deleteTestCase(String id) {
    return _database.deleteTestCase(id);
  }

  // Retrieve all TestCases
  List<TestCase> getAllTestCases() {
    var dataList = _database.getAllTestCases();
    return dataList.map((data) => TestCase.fromJson(data)).toList();
  }

  // Link a TestCase to a TestPlan
  void addTestCaseToTestPlan(String testPlanId, String testCaseId) {
    // Assuming DatabaseHelper has a method to get a TestCase by ID
    var testCaseData = _database.getTestCase(testCaseId);
    if (testCaseData != null) {
      _database.addTestCaseToTestPlan(testPlanId, testCaseData);
    } else {
      throw Exception('TestCase not found');
    }
  }

  // Unlink a TestCase from a TestPlan
  void removeTestCaseFromTestPlan(String testPlanId, String testCaseId) {
    _database.removeTestCaseFromTestPlan(testPlanId, testCaseId);
  }
}
