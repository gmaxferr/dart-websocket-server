import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dart_websocket_server/database/testing_database.dart';
import 'package:dart_websocket_server/device_management/device_manager.dart';
import 'package:dart_websocket_server/testing/models/ocpp_message.dart';
import 'package:dart_websocket_server/testing/models/test_case_result.dart';

import 'test_case.dart';

enum TestPlanType { sequential, generic }

enum TestStatus { waiting, executing, success, allFailed, someFailed, failed }

class TestPlan {
  final int? id;
  final String name;
  final TestPlanType type;
  Map<String, dynamic> variables; // Dynamic variables for macro replacement
  List<TestCase>? testCases;

  TestPlan({
    required this.id,
    required this.name,
    required this.type,
    required this.variables,
    this.testCases,
  });
  Future<void> execute(DeviceManager deviceManager, String deviceId,
      TestingDatabase testDatabase, int? testPlanResultId) async {
    int currentTestPlanResultId = testPlanResultId ??
        testDatabase.addTestPlanResult(
            this.id!, TestStatus.waiting.name, deviceId);
    testDatabase.updateTestPlanResult(
        currentTestPlanResultId, TestStatus.executing.name);

    for (TestCase testCase in testCases ?? []) {
      String message = _prepareMessage(testCase, variables);
      OcppMessage? requestMessage = OcppMessage.fromPlainText(message);

      if (requestMessage == null) {
        testDatabase.addTestCaseResult(
            currentTestPlanResultId,
            testCase.id!,
            TestStatus.failed.name,
            message,
            "",
            "Request message parsing failed");
      }

      bool messageSent = requestMessage != null &&
          deviceManager.sendMessage(deviceId, message);
      if (!messageSent && type == TestPlanType.sequential) {
        testDatabase.addTestCaseResult(
            currentTestPlanResultId,
            testCase.id!,
            TestStatus.failed.name,
            message,
            "",
            "Could not send message to device with ID '${deviceId}'");
      }

      String? responseMessage;
      if (messageSent) {
        for (int attempt = 0; attempt < 5; attempt++) {
          responseMessage = await deviceManager.getDeviceResponseTo(
              deviceId, requestMessage.messageId);
          if (responseMessage != null) break;
          await Future.delayed(Duration(seconds: 1));
        }
      }

      TestStatus testCaseStatus = TestStatus.failed;
      if (messageSent && responseMessage != null) {
        OcppMessage? response = OcppMessage.fromPlainText(responseMessage);
        if (response != null &&
            testCase.validateResponse(response, variables)) {
          testCaseStatus = TestStatus.success;
        }
      }

      testDatabase.addTestCaseResult(
          currentTestPlanResultId,
          testCase.id!,
          testCaseStatus.name,
          message,
          responseMessage ?? "No response",
          "Validation details");

      if (type == TestPlanType.sequential &&
          testCaseStatus == TestStatus.failed) {
        break; // Stop further execution for sequential test plans upon failure
      }
    }

    TestStatus finalStatus =
        _determineFinalStatus(testDatabase, currentTestPlanResultId);
    testDatabase.updateTestPlanResult(
        currentTestPlanResultId, finalStatus.name);
  }

  String _generateRandomString(int length) {
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();

    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  String _prepareMessage(TestCase testCase, Map<String, dynamic> variables) {
    String message = testCase.defaultMessage;

    variables.addAll({'__random__': _generateRandomString(7)});

    variables.forEach((macro, value) {
      message = message.replaceAll(macro, value.toString());
    });

    return message;
  }

  TestStatus _determineFinalStatus(
      TestingDatabase testDatabase, int testPlanResultId) {
    List<TestCaseResult> results =
        testDatabase.getTestCaseResultsForTestPlanResult(testPlanResultId);
    bool allSuccess = true;
    bool anyFailed = false;

    for (var result in results) {
      if (result.status == TestStatus.failed.name) {
        anyFailed = true;
        if (this.type == TestPlanType.sequential) {
          return TestStatus
              .failed; // Immediate failure for sequential test plans
        }
      } else if (result.status != TestStatus.success.name) {
        allSuccess = false; // If any status is not success
      }
    }

    if (allSuccess) return TestStatus.success;
    return anyFailed ? TestStatus.someFailed : TestStatus.allFailed;
  }

  static TestPlan from(Map<String, dynamic> map) {
    return TestPlan(
      // Assuming 'id', 'name', 'type', and 'variables' are the column names in the TestPlans table
      id: map['id'],
      name: map['name'],
      type: TestPlanType.values.firstWhere((e) => e.name == map['type']),
      variables: map['variables'] is String
          ? jsonDecode(map['variables'])
          : map['variables'],
      // Initialize testCases as empty, since they are fetched separately
      testCases: [],
    );
  }

  Map toMap() {
    return {
      'id': this.id,
      'name': this.name,
      'type': this.type.name,
      'variables': jsonEncode(this.variables),
      'testCases': (this.testCases ?? []).map((e) => e.toMap()).toList(),
    };
  }
}
