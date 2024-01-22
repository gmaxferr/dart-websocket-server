import 'package:dart_websocket_server/database/testing_database.dart';
import 'package:dart_websocket_server/device_management/device_manager.dart';
import 'package:dart_websocket_server/testing/models/test_case.dart';
import 'package:dart_websocket_server/testing/models/test_case_result.dart';
import 'package:dart_websocket_server/testing/models/test_plan.dart';
import 'package:dart_websocket_server/testing/models/test_plan_result.dart';

class TestingManager {
  final TestingDatabase database;
  final DeviceManager deviceManager;

  TestingManager({required this.database, required this.deviceManager});

  void addTestCaseToTestPlanWithId(
      int testPlanId, Map<String, dynamic> testCaseData) {
    // Extract test case  testCaseData and create TestCase
    var testCase = TestCase.from(testCaseData);
    database.addTestCase(testPlanId, testCase);
  }

  void deleteTesCaseWithId(int testCaseId) {
    database.deleteTestCase(testCaseId);
  }

  void updateTestPlanMacros(int testPlanId, Map<String, dynamic> macros) {
    database.updateTestPlanMacros(testPlanId, macros);
  }

  void createTestPlan(Map<String, dynamic> testPlanData,
      List<Map<String, dynamic>> testCasesData) {
    // Extract test plan details from testPlanData and create TestPlan
    var testPlan = TestPlan.from(testPlanData);
    database.addTestPlan(testPlan);

    // Iterate over testCasesData, create each TestCase and add to the database
    for (var testCaseData in testCasesData) {
      var testCase = TestCase.from(testCaseData);
      database.addTestCase(testPlan.id, testCase);
    }
  }

  TestPlan? getTestPlanById(int id) {
    TestPlan? testPlan = database.getTestPlanById(id);
    if (testPlan != null) {
      testPlan.testCases = database.getTestCasesByTestPlanId(id);
    }
    return testPlan;
  }

  List<TestPlan> getTestPlansByIds(List<int> testPlanIds) {
    List<TestPlan> testPlans = [];
    for (int id in testPlanIds) {
      TestPlan? testPlan = getTestPlanById(id);
      if (testPlan != null) {
        testPlans.add(testPlan);
      }
    }
    return testPlans;
  }

  List<TestPlan> getAllTestPlans() {
    List<TestPlan> testPlans = [];
    List<TestPlan> testPlansAux = database.getAllTestPlans();
    for (TestPlan tp in testPlansAux) {
      TestPlan? testPlan = getTestPlanById(tp.id);
      if (testPlan != null) {
        testPlans.add(testPlan);
      }
    }
    return testPlans;
  }

  List<TestPlan> getTestPlansByDeviceId(String deviceId) {
    List<TestPlan> testPlans = database.getTestPlansByDeviceId(deviceId);
    for (TestPlan testPlan in testPlans) {
      testPlan.testCases = database.getTestCasesByTestPlanId(testPlan.id);
    }
    return testPlans;
  }

  List<TestPlanResult> getTestPlanAndTestCaseResultsForTestPlanId(String deviceId, int planId) {
    List<TestPlanResult> testPlanResults =
        database.getTestPlanResultByTestPlanAndDevice(deviceId, planId);

    List<TestPlanResult> toReturn = [];
    for(var tpr in testPlanResults){
      List<TestCaseResult> testCaseResults = database.getTestCaseResultsForTestPlanResult(tpr.id);
      tpr.testCaseResults = testCaseResults;
      toReturn.add(tpr);
    }
    return toReturn;
  }

  List<TestPlan> getTestPlanByStatus(String deviceId, String status) {
    List<TestPlanResult> testPlanResults =
        database.getTestPlanResultByStatus(deviceId, status);
    List<TestPlan> result = [];
    List<TestPlan?> aux = testPlanResults
        .map((result) => getTestPlanById(result.testPlanId))
        .where((element) => element != null)
        .toList();
    for (TestPlan? p in aux) {
      result.add(p!);
    }

    return result;
  }

  TestCase? getTestCaseById(int id) {
    return database
        .getTestCaseById(id); // Assuming this method exists in database
  }

  List<TestCase> getTestCasesByTestPlanId(int testPlanId) {
    return database.getTestCasesByTestPlanId(testPlanId);
  }

  Future<void> runTestPlan(
      String deviceId, int testPlanId, int? testPlanResultId) async {
    TestPlan? testPlan =
        database.getTestPlanById(testPlanId); // Assuming this method exists
    if (testPlan == null) {
      if (testPlanResultId != null &&
          database.testPlanResultExists(testPlanResultId)) {
        database.updateTestPlanResult(testPlanResultId, TestStatus.failed.name);
      } else {
        database.addTestPlanResult(
            testPlanId, TestStatus.failed.name, deviceId);
      }
      print(
          "TestPlan #${testPlanId} failed since this identifier does not exist in the database.");
      return;
    }
    if (testPlanResultId == null ||
        !database.testPlanResultExists(testPlanResultId)) {
      testPlanResultId = database.addTestPlanResult(
          testPlanId, TestStatus.waiting.name, deviceId);
    }
    await testPlan.execute(deviceManager, deviceId, database, testPlanResultId);
  }

  Future<void> runMultipleTestPlans(
      String deviceId, List<int> testPlanIds) async {
    Map<int, int> testPlans = {};
    for (int testPlanId in testPlanIds) {
      int testPlanResultId = database.addTestPlanResult(
          testPlanId, TestStatus.waiting.name, deviceId);

      testPlans.putIfAbsent(testPlanResultId, () => testPlanId);
    }
    for (int testPlanResultId in testPlans.keys) {
      await runTestPlan(
          deviceId, testPlans[testPlanResultId]!, testPlanResultId);
    }
  }
}
