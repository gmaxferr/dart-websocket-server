import 'dart:convert';

import 'test_case.dart';

enum TestPlanType { generic, sequential }

class TestPlan {
  String id;
  String title;
  String? description;
  Map<String, dynamic> macros;
  DateTime createdDate;
  DateTime updatedDate;
  String createdBy;
  String updatedBy;
  TestPlanType type;
  List<TestCase> testCases;

  TestPlan({
    required this.id,
    required this.title,
    required this.macros,
    this.description,
    required this.createdDate,
    required this.updatedDate,
    required this.createdBy,
    required this.updatedBy,
    required this.type,
    required this.testCases,
  });

  factory TestPlan.fromJson(Map<String, dynamic> json) => TestPlan(
        id: json['id'],
        title: json['title'],
        macros: Map<String, dynamic>.from(json['macros'] is String
            ? jsonDecode(json['macros'])
            : json['macros'] as Map),
        description: json['description'],
        createdDate: DateTime.parse(json['createdDate']),
        updatedDate: DateTime.parse(json['updatedDate']),
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        type: TestPlanType.values[json['type']],
        testCases: List<TestCase>.from(
          json['testCases'].map((x) => TestCase.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'macros': macros,
        'description': description,
        'createdDate': createdDate.toIso8601String(),
        'updatedDate': updatedDate.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'type': type.index,
        'testCases': List<dynamic>.from(testCases.map((x) => x.toJson())),
      };
}
