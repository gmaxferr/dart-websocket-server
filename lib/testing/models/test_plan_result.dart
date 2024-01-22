import 'package:dart_websocket_server/testing/models/test_case_result.dart';
import 'package:dart_websocket_server/testing/models/test_plan.dart';

class TestPlanResult {
  final int id;
  final int testPlanId;
  final DateTime timestamp;
  final String deviceId;
  final TestStatus status;
  List<TestCaseResult>? testCaseResults;

  TestPlanResult({
    required this.id,
    required this.testPlanId,
    required this.timestamp,
    required this.status,
    required this.deviceId,
    this.testCaseResults,
  });

  static TestPlanResult from(Map<String, dynamic> map) {
    return TestPlanResult(
      // Column names from the TestPlanResults table
      id: map['id'],
      testPlanId: map['testPlanId'],
      deviceId: map['deviceId'],
      status: TestStatus.values.firstWhere((e) => e.name == map['status']),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map toMap() {
    return {
      'id': this.id,
      'testPlanId': this.testPlanId,
      'deviceId': this.deviceId,
      'status': this.status.name,
      'testCaseResults': (this.testCaseResults ?? []).map((e) => e.toMap()).toList(),
      'timestamp': this.timestamp.toIso8601String(),
    };
  }
}
