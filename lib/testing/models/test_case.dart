import 'package:dart_websocket_server/testing/models/validation_mechanism.dart';

class TestCase {
  String id;
  String description;
  String messageToSend;
  List<ValidationMechanism> validations;

  TestCase({
    required this.id,
    required this.description,
    required this.messageToSend,
    required this.validations,
  });

  factory TestCase.fromJson(Map<String, dynamic> json) => TestCase(
        id: json['id'],
        description: json['description'],
        messageToSend: json['messageToSend'],
        validations: List<ValidationMechanism>.from(
          json['validations'].map((x) => ValidationMechanism.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'messageToSend': messageToSend,
        'validations': List<dynamic>.from(validations.map((x) => x.toJson())),
      };
}

// Assuming ValidationMechanism is a class you have defined elsewhere.
