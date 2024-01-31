enum TestCaseResultStatus { success, failed }

class TestCaseResult {
  String id;
  String testCaseId;
  String ranOn;
  DateTime executionDate;
  TestCaseResultStatus status;
  String messageSent;
  String messageReceived;
  String? errorDescription;

  TestCaseResult({
    required this.id,
    required this.testCaseId,
    required this.ranOn,
    required this.executionDate,
    required this.status,
    required this.messageSent,
    required this.messageReceived,
    this.errorDescription,
  });

  factory TestCaseResult.fromJson(Map<String, dynamic> json) => TestCaseResult(
        id: json['id'],
        testCaseId: json['testCaseId'],
        ranOn: json['ranOn'],
        executionDate: DateTime.parse(json['executionDate']),
        status: TestCaseResultStatus.values[json['status']],
        messageSent: json['messageSent'],
        messageReceived: json['messageReceived'],
        errorDescription: json['errorDescription'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'testCaseId': testCaseId,
        'ranOn': ranOn,
        'executionDate': executionDate.toIso8601String(),
        'status': status.index,
        'messageSent': messageSent,
        'messageReceived': messageReceived,
        'errorDescription': errorDescription,
      };
}
