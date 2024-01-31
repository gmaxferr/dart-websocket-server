class ValidationMechanism {
  String type; // Type of validation (e.g., "assertExactValueOfKey")
  dynamic expectedValue; // The expected value or pattern for validation
  String? key; // Key used for some validations

  ValidationMechanism({
    required this.type,
    this.expectedValue,
    this.key,
  });

  factory ValidationMechanism.fromJson(Map<String, dynamic> json) {
    return ValidationMechanism(
      type: json['type'],
      expectedValue: json['expectedValue'],
      key: json['key'],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'expectedValue': expectedValue,
        'key': key,
      };

  bool validateResponse(Map<String, dynamic> response) {
    switch (type) {
      case 'assertExactValueOfKey':
        return response[key] == expectedValue;
      case 'assertExistsKey':
        return response.containsKey(key);
      case 'assertValueOfKeyWithRegex':
        RegExp regex = RegExp(expectedValue);
        return regex.hasMatch(response[key].toString());
      case 'assertExactActionName':
        return response['#actionName'] == expectedValue;
      case 'storeExtractionOnXPath':
        return _extractAndStore(response);
      default:
        return false;
    }
  }

  bool _extractAndStore(Map<String, dynamic> response) {
    // Split the key by dots to handle nested JSON objects
    List<String> pathParts = key!.split('.');

    var currentElement = response;
    for (String part in pathParts) {
      // Check if the current element is a Map and contains the key
      // ignore: unnecessary_type_check
      if (currentElement is Map<String, dynamic> &&
          currentElement.containsKey(part)) {
        currentElement = currentElement[part];
      } else {
        // Path not found in the response
        return false;
      }
    }

    // At this point, currentElement is the extracted value
    // Here you would store currentElement in an external storage or state
    // For demonstration, we'll just print it
    print('Extracted Value: $currentElement');

    // Returning true for successful extraction
    return true;
  }
}
