import 'package:dart_websocket_server/testing/models/ocpp_message.dart';

class TestCase {
  final int id;
  final String description;
  final String
      defaultMessage; // The default message to send, may contain macros
  final String
      validationPath; // XPath-like string or special case "#actionName"
  final String expectedValue; // The value expected in the response
  final String? extractionMacro; // The macro name for storing extracted values

  TestCase({
    required this.id,
    required this.description,
    required this.defaultMessage,
    required this.validationPath,
    required this.expectedValue,
    this.extractionMacro,
  });

  bool validateResponse(
      OcppMessage response, Map<String, dynamic> testPlanVariables) {
    // if (response == null) {
    //   return false;
    // }

    dynamic actualValue;
    if (validationPath == "#actionName") {
      actualValue = response.actionName;
    } else {
      actualValue = extractValueFromJson(response.data, validationPath);
    }

    // Store the extracted value in the test plan variables if extractionMacro is defined
    if (extractionMacro != null && actualValue != null) {
      testPlanVariables[extractionMacro!] = actualValue;
    }

    return actualValue == expectedValue;
  }

  dynamic extractValueFromJson(Map<String, dynamic> json, String path) {
    dynamic current = json;
    for (String part in path.split('.')) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  static TestCase from(Map<String, dynamic> map) {
    return TestCase(
      // Assuming these are the column names in the TestCases table
      id: map['id'],
      description: map['description'],
      defaultMessage: map['defaultMessage'],
      validationPath: map['validationPath'],
      expectedValue: map['expectedValue'],
      extractionMacro: map['extractionMacro'],
    );
  }

  Map toMap() {
    return {
      'id': this.id,
      'description': this.description,
      'defaultMessage': this.defaultMessage,
      'validationPath': this.validationPath,
      'expectedValue': this.expectedValue,
      'extractionMacro': this.extractionMacro,
    };
  }
}
