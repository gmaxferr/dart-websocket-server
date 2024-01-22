import 'package:dart_websocket_server/testing/models/test_plan.dart';

class TestCaseResult {
  final int id;
  final int testPlanResultId;
  final int testCaseId;
  // final String result;
  final TestStatus status;
  final String sentMessage;
  final String receivedMessage;
  final String validationDetails;
  final DateTime timestamp;

  TestCaseResult({
    required this.id,
    required this.testPlanResultId,
    required this.testCaseId,
    required this.status,
    // required this.result,
    required this.sentMessage,
    required this.receivedMessage,
    required this.validationDetails,
    required this.timestamp,
  });

  static TestCaseResult from(Map<String, dynamic> map) {
    return TestCaseResult(
      // Column names from the TestCaseResults table
      id: map['id'],
      testPlanResultId: map['testPlanResultId'],
      testCaseId: map['testCaseId'],
      status: TestStatus.values.firstWhere((e) => e.name == map['status']),
      sentMessage: map['sentMessage'],
      receivedMessage: map['receivedMessage'],
      validationDetails: map['validationDetails'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map toMap() {
    return {
      'id': this.id,
      'testPlanResultId': this.testPlanResultId,
      'testCaseId': this.testCaseId,
      'status': this.status.name,
      'sentMessage': this.sentMessage,
      'receivedMessage': this.receivedMessage,
      'validationDetails': this.validationDetails,
      'timestamp': this.timestamp.toIso8601String(),
    };
  }
}
