import 'package:dart_websocket_server/database/testing_database.dart';
import 'package:dart_websocket_server/device_management/device_manager.dart';
import 'package:dart_websocket_server/testing/helpers/helper_functions.dart';
import 'package:dart_websocket_server/testing/helpers/macro_processor.dart';
import 'package:dart_websocket_server/testing/helpers/ocpp_parser.dart';
import 'package:dart_websocket_server/testing/models/test_case.dart';
import 'package:dart_websocket_server/testing/models/test_case_result.dart';
import 'package:dart_websocket_server/testing/models/test_plan.dart';
import 'package:dart_websocket_server/testing/models/test_plan_result.dart';

class ExecutionService {
  final TestingDatabase _dbHelper;
  final DeviceManager _deviceManager;
  final MacroProcessor _macroProcessor;
  final int maxWaitTime;

  ExecutionService(this._dbHelper, this._deviceManager, this._macroProcessor, this.maxWaitTime);

  // Execute multiple TestPlans
  Future<List<TestPlanResult>> executeMultipleTestPlans(
      List<String> testPlanIds, String deviceId) async {
    List<TestPlanResult> results = [];
    Map<String, TestPlanResult> tpResultMap = {};
    Map<String, List<TestCaseResult>> tcsResultsMap = {};
    for (String testPlanId in testPlanIds) {
      // Instantiate TestPlanResult and TestCaseResults with default status 'waiting'
      var tpResult = TestPlanResult(
        id: _generateUniqueId(),
        testPlanId: testPlanId,
        ranOn: deviceId,
        executionDate: DateTime.now(),
        status: TestPlanResultStatus.waiting,
        testCaseResults: [],
      );

      List<TestCase> testCases = _dbHelper
          .getTestCasesOfTestPlan(testPlanId)
          .map<TestCase>((e) => TestCase.fromJson(e))
          .toList();
      List<TestCaseResult> tcResults = testCases
          .map((tc) => TestCaseResult(
                id: _generateUniqueId(),
                testCaseId: tc.id,
                ranOn: deviceId,
                messageReceived: '',
                messageSent: '',
                resultSummary: '',
                executionDate: DateTime.now(),
                status: TestCaseResultStatus.waiting,
              ))
          .toList();
      tpResultMap[testPlanId] = tpResult;
      tcsResultsMap[testPlanId] = tcResults;

      _dbHelper.insertTestPlanResult(tpResult.toJson());
      for (final tc in tcResults) {
        _dbHelper.insertTestCaseResult(tc.toJson());
      }
    }

    for (String testPlanId in testPlanIds) {
      // Execute the test plan
      var executedTpResult = await executeTestPlan(testPlanId, deviceId,
          tpResultMap[testPlanId], tcsResultsMap[testPlanId]);

      results.add(executedTpResult);
    }
    return results;
  }

  // Execute a TestPlan by ID
  Future<TestPlanResult> executeTestPlan(String testPlanId, String deviceId,
      TestPlanResult? tpResult, List<TestCaseResult>? testCaseResults) async {
    // Update TestPlanResult status to 'executing' if it exists, otherwise create a new one
    var testPlanResult = tpResult ??
        TestPlanResult(
          id: _generateUniqueId(),
          testPlanId: testPlanId,
          ranOn: deviceId,
          executionDate: DateTime.now(),
          status:
              TestPlanResultStatus.executing, // Initial status as 'executing'
          testCaseResults: [],
        );

    testPlanResult.executionDate = DateTime.now();
    if (tpResult == null) {
      _dbHelper.insertTestPlanResult(testPlanResult.toJson());
    } else {
      _dbHelper.updateTestPlanResult(
        testPlanResult.id,
        testPlanResult.toJson(),
      );
    }

    var _testPlan = await _dbHelper.getTestPlan(testPlanId);
    if (_testPlan == null) {
      throw Exception('TestPlan not found');
    }
    TestPlan testPlan = TestPlan.fromJson(_testPlan);
    List<TestCase> _testCases = _dbHelper
        .getTestCasesOfTestPlan(testPlan.id)
        .map<TestCase>((e) => TestCase.fromJson(e))
        .toList();
    testPlan.testCases = _testCases;

    List<TestCaseResult> _finalTestCaseResults = [];
    bool hasFailed = false;

    for (var testCase in testPlan.testCases) {
      TestCaseResult? res = testCaseResults
          ?.where((element) => element.testCaseId == testCase.id)
          .toList()
          .firstOrNull;
      var result = await _executeTestCase(testCase, deviceId, res);
      _finalTestCaseResults.add(result);

      if (testPlan.type == TestPlanType.sequential &&
          result.status == TestCaseResultStatus.failed) {
        hasFailed = true;
        break;
      }
    }

    testPlanResult.status = _determineOverallStatus(
        testPlan.type, _finalTestCaseResults, hasFailed);
    testPlanResult.testCaseResults = _finalTestCaseResults;
    _dbHelper.updateTestPlanResult(testPlanResult.id, testPlanResult.toJson());

    return testPlanResult;
  }

  // Execute a single TestCase
  Future<TestCaseResult> _executeTestCase(
      TestCase testCase, String deviceId, TestCaseResult? tcDefault) async {
    final testCaseResult = tcDefault ??
        TestCaseResult(
          id: _generateUniqueId(),
          testCaseId: testCase.id,
          executionDate: DateTime.now(),
          status: TestCaseResultStatus.executing,
          ranOn: deviceId,
          messageSent: '',
          messageReceived: '',
          resultSummary: '',
        );

    testCaseResult.executionDate = DateTime.now();

    _dbHelper.updateTestCaseResult(testCaseResult.id, testCaseResult.toJson());
    // Check device connection
    if (!_deviceManager.isConnected(deviceId)) {
      testCaseResult.status = TestCaseResultStatus.failed;
      testCaseResult.resultSummary = 'Device is not connected to the server.';
      _dbHelper.updateTestCaseResult(
          testCaseResult.id, testCaseResult.toJson());
      return testCaseResult;
    }

    // Process macros in the messageToSend
    String messageToSend = _macroProcessor.process(testCase.messageToSend);
    OcppMessage? message = OcppParser.parseMessage(messageToSend);
    if (message == null) {
      testCaseResult.status = TestCaseResultStatus.failed;
      testCaseResult.resultSummary =
          'Message to send is not in a valid OCPP Format. Cannot send.';
      _dbHelper.updateTestCaseResult(
          testCaseResult.id, testCaseResult.toJson());
      return testCaseResult;
    }

    bool success = _deviceManager.sendMessage(deviceId, messageToSend);

    if (!success) {
      testCaseResult.status = TestCaseResultStatus.failed;
      testCaseResult.resultSummary =
          'Error sending message, device disconnected or does not exist.';
      _dbHelper.updateTestCaseResult(
          testCaseResult.id, testCaseResult.toJson());
      return testCaseResult;
    }
    // Receive the response and process it
    String? response;
    int attempts = 0;
    while (attempts < 5) {
      response =
          await _deviceManager.getDeviceResponseTo(deviceId, message.messageId);
      if (response != null) break;
      attempts++;
      Future.delayed(Duration(seconds: 1));
    }

    if (response == null) {
      testCaseResult.status = TestCaseResultStatus.failed;
      testCaseResult.resultSummary = 'Device did not send response in time.';
      _dbHelper.updateTestCaseResult(
          testCaseResult.id, testCaseResult.toJson());
      return testCaseResult;
    }

    // Validate the response and determine the status
    OcppMessage? resMessage = OcppParser.parseMessage(response);
    if (resMessage == null) {
      testCaseResult.status = TestCaseResultStatus.failed;
      testCaseResult.resultSummary =
          'Response from device was not OCPP format or could not parse.';
      _dbHelper.updateTestCaseResult(
          testCaseResult.id, testCaseResult.toJson());
      return testCaseResult;
    }

    final msgData = resMessage.data
      ..addAll({
        "#actionName": resMessage.actionName,
        "#msgId": resMessage.messageId,
        "#msgType": resMessage.messageType
      });
    bool isSuccess = true;
    String summary = 'Validations:';
    for (final validation in testCase.validations) {
      bool res = validation.validateResponse(msgData);

      summary += "\n > ${validation.type} | ${res ? "OK" : "NOK"}";

      if (!res) isSuccess = false;
    }

    var status =
        isSuccess ? TestCaseResultStatus.success : TestCaseResultStatus.failed;

    testCaseResult.status = status;
    testCaseResult.resultSummary = summary;
    _dbHelper.updateTestCaseResult(testCaseResult.id, testCaseResult.toJson());
    return testCaseResult;
  }

  // Determine the overall status of a TestPlan based on its type and the results of its TestCases
  TestPlanResultStatus _determineOverallStatus(
      TestPlanType type, List<TestCaseResult> results, bool hasFailed) {
    if (type == TestPlanType.sequential) {
      return hasFailed
          ? TestPlanResultStatus.failed
          : TestPlanResultStatus.success;
    } else {
      if (results
          .every((result) => result.status == TestCaseResultStatus.success)) {
        return TestPlanResultStatus.success;
      } else if (results
          .every((result) => result.status == TestCaseResultStatus.failed)) {
        return TestPlanResultStatus.allFailed;
      } else {
        return TestPlanResultStatus.someFailed;
      }
    }
  }

  // Delete a test plan result by it's Id, along with all test case results associated
  void deleteTestPlanResultById(String testPlanResultId) {
    _dbHelper.deleteTestCaseResultsByPlanResultId(testPlanResultId);
    _dbHelper.deleteTestPlanResult(testPlanResultId);
  }

  // Utility method to generate unique IDs for results
  String _generateUniqueId() {
    return generateRandomString(length: 16);
  }

  // Fetch the latest TestPlanResults and their TestCaseResults
  List<Map<String, dynamic>> fetchLatestExecutions() {
    var testPlanResults = _dbHelper.getLatestTestPlanResults();
    return _populateTestCaseResults(testPlanResults);
  }

  // Fetch the latest TestPlanResults for a specific device and their TestCaseResults
  List<Map<String, dynamic>> fetchLatestExecutionsForDevice(String deviceId) {
    var testPlanResults = _dbHelper.getLatestTestPlanResultsForDevice(deviceId);
    return _populateTestCaseResults(testPlanResults);
  }

  // Helper method to populate TestCaseResults for each TestPlanResult

  List<Map<String, dynamic>>? getTestPlanByIdAndDeviceId(
      String? deviceId, List<String>? testPlanId) {
    List<Map<String, dynamic>> testplanResults =
        _dbHelper.getTestPlanResultsByIdOrDeviceId(testPlanId, deviceId);
    return testplanResults;
  }

  List<Map<String, dynamic>>? getTestPlanDeviceIdAndByStatus(
      String deviceId, int status) {
    List<Map<String, dynamic>> testplanResults =
        _dbHelper.getTestPlanResultsByDeviceIdAndStatus(deviceId, status);
    return testplanResults;
  }

  // Helper method to populate TestCaseResults for each TestPlanResult
  List<Map<String, dynamic>> _populateTestCaseResults(
      List<Map<String, dynamic>> testPlanResults) {
    for (var testPlanResult in testPlanResults) {
      var testCaseResults =
          _dbHelper.getTestCaseResultsForTestPlanResultId(testPlanResult['id']);
      testPlanResult['testCaseResults'] = testCaseResults;
    }
    return testPlanResults;
  }
}
