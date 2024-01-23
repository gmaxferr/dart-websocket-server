import 'dart:convert';

import 'package:dart_websocket_server/testing/models/test_case.dart';
import 'package:dart_websocket_server/testing/models/test_case_result.dart';
import 'package:dart_websocket_server/testing/models/test_plan.dart';
import 'package:dart_websocket_server/testing/models/test_plan_result.dart';
import 'package:sqlite3/sqlite3.dart';

class TestingDatabase {
  final Database _db = sqlite3.open('.testing-database');

  TestingDatabase() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS TestPlans (
        id INTEGER PRIMARY KEY,
        name TEXT,
        type TEXT,
        variables TEXT
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS TestCases (
        id INTEGER PRIMARY KEY,
        testPlanId INTEGER,
        description TEXT,
        defaultMessage TEXT,
        validationPath TEXT,
        expectedValue TEXT,
        extractionMacro TEXT,
        FOREIGN KEY (testPlanId) REFERENCES TestPlans (id)
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS TestPlanResults (
        id INTEGER PRIMARY KEY,
        testPlanId INTEGER,
        deviceId TEXT,
        status TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (testPlanId) REFERENCES TestPlans (id)
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS TestCaseResults (
        id INTEGER PRIMARY KEY,
        testPlanResultId INTEGER,
        testCaseId INTEGER,
        status TEXT,
        sentMessage TEXT,
        receivedMessage TEXT,
        validationDetails TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (testPlanResultId) REFERENCES TestPlanResults (id),
        FOREIGN KEY (testCaseId) REFERENCES TestCases (id)
      );
    ''');
  }
// Add a new TestPlan to the database
  int addTestPlan(TestPlan testPlan) {
    _db.execute(
        'INSERT INTO TestPlans (name, type, variables) VALUES (?, ?, ?)',
        [testPlan.name, testPlan.type.name, jsonEncode(testPlan.variables)]);
    return _db.lastInsertRowId;
  }

  // Add a new TestCase to the database
  void addTestCase(int testPlanId, TestCase testCase) {
    _db.execute(
        'INSERT INTO TestCases (testPlanId, description, defaultMessage, validationPath, expectedValue, extractionMacro) VALUES (?, ?, ?, ?, ?, ?)',
        [
          testPlanId,
          testCase.description,
          testCase.defaultMessage,
          testCase.validationPath,
          testCase.expectedValue,
          testCase.extractionMacro
        ]);
  }

  // Delete a TestCase by ID
  void deleteTestCase(int id) {
    _db.execute('DELETE FROM TestCases WHERE id = ?', [id]);
  }

  // Delete a TestPlan by ID
  void deleteTestPlan(int id) {
    _db.execute('DELETE FROM TestPlans WHERE id = ?', [id]);
  }

  // Method to add a TestPlanResult
  int addTestPlanResult(int testPlanId, String status, String deviceId) {
    _db.execute(
        'INSERT INTO TestPlanResults (testPlanId, status, deviceId) VALUES (?, ?, ?)',
        [testPlanId, status, deviceId]);
    return _db.lastInsertRowId;
  }

// Method to update test plan macros
  void updateTestPlanMacros(int testPlanId, Map<String, dynamic> macros) {
    String macrosJson = jsonEncode(macros);
    _db.execute('UPDATE TestPlans SET variables = ? WHERE id = ?',
        [macrosJson, testPlanId]);
  }

// Method to update test plan macros
  List<TestPlanResult> getTestPlanResultByTestPlanAndDevice(
      String deviceId, int testPlanId) {
    var results = _db.select(
        'SELECT * FROM TestPlanResults WHERE testPlanId = ? and deviceId = ?',
        [testPlanId, deviceId]);
    return results.map((row) => TestPlanResult.from(row)).toList();
  }

  // Method to update a TestPlanResult
  void updateTestPlanResult(int id, String status) {
    _db.execute(
        'UPDATE TestPlanResults SET status = ? WHERE id = ?', [status, id]);
  }

  // Method to add a TestCaseResult
  void addTestCaseResult(int testPlanResultId, int testCaseId, String status,
      String sentMessage, String receivedMessage, String validationDetails) {
    _db.execute(
        'INSERT INTO TestCaseResults (testPlanResultId, testCaseId, status, sentMessage, receivedMessage, validationDetails) VALUES (?, ?, ?, ?, ?, ?)',
        [
          testPlanResultId,
          testCaseId,
          status,
          sentMessage,
          receivedMessage,
          validationDetails
        ]);
  }

  // Update a TestPlan
  void updateTestPlan(int id, String name, String type, String variables) {
    _db.execute(
        'UPDATE TestPlans SET name = ?, type = ?, variables = ? WHERE id = ?',
        [name, type, variables, id]);
  }

  // Update a TestCase
  void updateTestCase(int id, String description, String defaultMessage,
      String validationPath, String expectedValue, String extractionMacro) {
    _db.execute(
        'UPDATE TestCases SET description = ?, defaultMessage = ?, validationPath = ?, expectedValue = ?, extractionMacro = ? WHERE id = ?',
        [
          description,
          defaultMessage,
          validationPath,
          expectedValue,
          extractionMacro,
          id
        ]);
  }

  // Get TestPlan by Device ID
  List<TestPlan> getAllTestPlans() {
    var results = _db.select('SELECT * FROM TestPlans;');
    return results.map((row) => TestPlan.from(row)).toList();
  }

  // Get TestPlan by Device ID
  List<TestPlan> getTestPlansByDeviceId(String deviceId) {
    var results =
        _db.select('SELECT * FROM TestPlans WHERE deviceId = ?', [deviceId]);
    return results.map((row) => TestPlan.from(row)).toList();
  }

  // Get all TestCases for a TestPlan
  List<TestCase> getTestCasesForTestPlan(int testPlanId) {
    var results = _db
        .select('SELECT * FROM TestCases WHERE testPlanId = ?', [testPlanId]);
    return results.map((row) => TestCase.from(row)).toList();
  }

  // Get Last 'n' TestPlanResults
  List<TestPlanResult> getLastTestPlanResults(int n) {
    var results = _db
        .select('SELECT * FROM TestPlanResults ORDER BY id DESC LIMIT ?', [n]);
    return results.map((row) => TestPlanResult.from(row)).toList();
  }

  // Get TestCaseResult for a TestPlanResult
  List<TestCaseResult> getTestCaseResultsForTestPlanResult(
      int testPlanResultId) {
    var results = _db.select(
        'SELECT * FROM TestCaseResults WHERE testPlanResultId = ?',
        [testPlanResultId]);
    return results.map((row) => TestCaseResult.from(row)).toList();
  }

  TestPlan? getTestPlanById(int testPlanId) {
    var result =
        _db.select('SELECT * FROM TestPlans WHERE id = ?', [testPlanId]);
    if (result.isEmpty) {
      return null;
    }

    var testPlanRow = result.first;
    TestPlan testPlan = TestPlan.from(testPlanRow);

    // Now fetch and attach the test cases to this test plan
    var testCaseResults = _db
        .select('SELECT * FROM TestCases WHERE testPlanId = ?', [testPlanId]);
    List<TestCase> testCases =
        testCaseResults.map((row) => TestCase.from(row)).toList();
    testPlan.testCases = testCases;

    return testPlan;
  }

  bool testPlanResultExists(int testPlanResultId) {
    var result = _db.select(
        'SELECT id FROM TestPlanResults WHERE id = ?', [testPlanResultId]);
    return result.isNotEmpty;
  }

  // Get all TestCases for a given TestPlan ID
  List<TestCase> getTestCasesByTestPlanId(int testPlanId) {
    var results = _db
        .select('SELECT * FROM TestCases WHERE testPlanId = ?', [testPlanId]);
    return results
        .map((row) => TestCase.from(row))
        .toList(); // Assuming a suitable from() method in TestCase
  }

  // Get TestPlanResult by status for a specific deviceId
  List<TestPlanResult> getTestPlanResultByStatus(
      String deviceId, String status) {
    var results = _db.select(
        'SELECT * FROM TestPlanResults WHERE deviceId = ? AND status = ?',
        [deviceId, status]);
    return results
        .map((row) => TestPlanResult.from(row))
        .toList(); // Assuming a suitable from() method in TestPlanResult
  }

  TestCase? getTestCaseById(int id) {
    var results = _db.select('SELECT * FROM TestCases WHERE id = ?', [id]);
    if (results.isEmpty) {
      return null;
    }
    return TestCase.from(
        results.first); // Assuming a suitable from() method in TestCase
  }

  // Dispose/close the database
  void dispose() {
    _db.dispose();
  }

  void deleteAll() {
    _db.execute('DELETE FROM TestCases');
    _db.execute('DELETE FROM TestPlans');
    _db.execute('DELETE FROM TestPlanResults');
    _db.execute('DELETE FROM TestCaseResults');
  }
}
