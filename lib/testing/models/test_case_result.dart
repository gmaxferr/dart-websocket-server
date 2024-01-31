enum TestCaseResultStatus { waiting, executing, success, failed }

class TestCaseResult {
  String id;
  String testCaseId;
  String ranOn;
  DateTime executionDate;
  TestCaseResultStatus status;
  String messageSent;
  String messageReceived;
  String? resultSummary;

  TestCaseResult({
    required this.id,
    required this.testCaseId,
    required this.ranOn,
    required this.executionDate,
    required this.status,
    required this.messageSent,
    required this.messageReceived,
    this.resultSummary,
  });

  factory TestCaseResult.fromJson(Map<String, dynamic> json) => TestCaseResult(
        id: json['id'],
        testCaseId: json['testCaseId'],
        ranOn: json['ranOn'],
        executionDate: DateTime.parse(json['executionDate']),
        status: TestCaseResultStatus.values[json['status']],
        messageSent: json['messageSent'],
        messageReceived: json['messageReceived'],
        resultSummary: json['resultSummary'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'testCaseId': testCaseId,
        'ranOn': ranOn,
        'executionDate': executionDate.toIso8601String(),
        'status': status.index,
        'messageSent': messageSent,
        'messageReceived': messageReceived,
        'resultSummary': resultSummary,
      };
}
