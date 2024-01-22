import 'package:dart_websocket_server/database/testing_database.dart';
import 'package:dart_websocket_server/device_management/device_manager.dart';
import 'package:dart_websocket_server/testing/models/test_case.dart';
import 'package:dart_websocket_server/testing/models/test_plan.dart';
import 'package:dart_websocket_server/testing/models/test_plan_result.dart';

class TestingManager {
  final TestingDatabase database;
  final DeviceManager deviceManager;

  TestingManager({required this.database, required this.deviceManager});

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
