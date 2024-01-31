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

  ExecutionService(this._dbHelper, this._deviceManager, this._macroProcessor);

  // Execute a TestPlan by ID
  Future<TestPlanResult> executeTestPlan(
      String testPlanId, String deviceId) async {
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

    List<TestCaseResult> testCaseResults = [];
    bool hasFailed = false;

    for (var testCase in testPlan.testCases) {
      var result = await _executeTestCase(testCase, deviceId);
      testCaseResults.add(result);

      if (testPlan.type == TestPlanType.sequential &&
          result.status == TestCaseResultStatus.failed) {
        hasFailed = true;
        break;
      }
    }

    TestPlanResultStatus overallStatus =
        _determineOverallStatus(testPlan.type, testCaseResults, hasFailed);
    var testPlanResult = TestPlanResult(
      id: _generateUniqueId(),
      testPlanId: testPlanId,
      ranOn: deviceId,
      executionDate: DateTime.now(),
      status: overallStatus,
      testCaseResults: testCaseResults,
    );

    _dbHelper.insertTestPlanResult(testPlanResult.toJson());
    return testPlanResult;
  }

  // Execute a single TestCase
  Future<TestCaseResult> _executeTestCase(
      TestCase testCase, String deviceId) async {
    // Check device connection
    if (!_deviceManager.isConnected(deviceId)) {
      return TestCaseResult(
        id: _generateUniqueId(),
        testCaseId: testCase.id,
        executionDate: DateTime.now(),
        status: TestCaseResultStatus.failed,
        ranOn: deviceId,
        messageSent: '',
        messageReceived: '',
        errorDescription: 'Device is not connected to the server.',
      );
    }

    // Process macros in the messageToSend
    String messageToSend = _macroProcessor.process(testCase.messageToSend);
    OcppMessage? message = OcppParser.parseMessage(messageToSend);
    if (message == null) {
      throw Exception(
          'Message to send is not in a valid OCPP Format. Cannot send.');
    }

    _deviceManager.sendMessage(deviceId, messageToSend);

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
      return TestCaseResult(
        id: _generateUniqueId(),
        testCaseId: testCase.id,
        ranOn: deviceId,
        executionDate: DateTime.now(),
        status: TestCaseResultStatus.failed,
        messageSent: messageToSend,
        messageReceived: '',
        errorDescription: 'Device did not send response in time.',
      );
    }

    // Validate the response and determine the status
    OcppMessage? resMessage = OcppParser.parseMessage(response);
    bool isSuccess = resMessage != null &&
        testCase.validations
            .every((validation) => validation.validateResponse(resMessage.data
              ..addAll({
                "#actionName": resMessage.actionName,
                "#msgId": resMessage.messageId,
                "#msgType": resMessage.messageType
              })));
    var status =
        isSuccess ? TestCaseResultStatus.success : TestCaseResultStatus.failed;

    return TestCaseResult(
      id: _generateUniqueId(),
      testCaseId: testCase.id,
      ranOn: deviceId,
      executionDate: DateTime.now(),
      status: status,
      messageSent: messageToSend,
      messageReceived: response,
      errorDescription: isSuccess ? null : 'Validation failed',
    );
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
