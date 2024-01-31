import 'test_case_result.dart';

enum TestPlanResultStatus { waiting, executing, success, allFailed, someFailed, failed }

class TestPlanResult {
  String id;
  String testPlanId;
  String ranOn;
  DateTime executionDate;
  TestPlanResultStatus status;
  List<TestCaseResult> testCaseResults;

  TestPlanResult({
    required this.id,
    required this.testPlanId,
    required this.ranOn,
    required this.executionDate,
    required this.status,
    required this.testCaseResults,
  });

  factory TestPlanResult.fromJson(Map<String, dynamic> json) => TestPlanResult(
        id: json['id'],
        testPlanId: json['testPlanId'],
        ranOn: json['ranOn'],
        executionDate: DateTime.parse(json['executionDate']),
        status: TestPlanResultStatus.values[json['status']],
        testCaseResults: List<TestCaseResult>.from(
          json['testCaseResults'].map((x) => TestCaseResult.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'testPlanId': testPlanId,
        'ranOn': ranOn,
        'executionDate': executionDate.toIso8601String(),
        'status': status.index,
        'testCaseResults': List<dynamic>.from(
            testCaseResults.map((x) => x.toJson())),
      };
}
