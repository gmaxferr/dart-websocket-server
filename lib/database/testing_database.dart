import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

class TestingDatabase {
  final Database db = sqlite3.open('.testing-database');

  TestingDatabase() {
    _createTables();
  }
  void _createTables() {
    db.execute('''
      CREATE TABLE IF NOT EXISTS TestPlans (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        macros TEXT,
        description TEXT,
        createdDate TEXT NOT NULL,
        updatedDate TEXT NOT NULL,
        createdBy TEXT NOT NULL,
        updatedBy TEXT NOT NULL,
        type INTEGER NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS TestCases (
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        messageToSend TEXT NOT NULL,
        validations TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS TestPlanResults (
        id TEXT PRIMARY KEY,
        testPlanId TEXT NOT NULL,
        ranOn TEXT NOT NULL,
        executionDate TEXT NOT NULL,
        status INTEGER NOT NULL,
        FOREIGN KEY (testPlanId) REFERENCES TestPlans(id)
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS TestCaseResults (
        id TEXT PRIMARY KEY,
        testCaseId TEXT NOT NULL,
        testPlanResultId TEXT NOT NULL,
        ranOn TEXT NOT NULL,
        executionDate TEXT NOT NULL,
        status INTEGER NOT NULL,
        messageSent TEXT NOT NULL,
        messageReceived TEXT NOT NULL,
        resultSummary TEXT,
        FOREIGN KEY (testCaseId) REFERENCES TestCases(id),
        FOREIGN KEY (testPlanResultId) REFERENCES TestPlanResults(id)
      );
    ''');

    db.execute('''
        CREATE TABLE IF NOT EXISTS TestPlanTestCases (
        testPlanId TEXT NOT NULL,
        testCaseId TEXT NOT NULL,
        PRIMARY KEY (testPlanId, testCaseId),
        FOREIGN KEY (testPlanId) REFERENCES TestPlans(id) ON DELETE CASCADE,
        FOREIGN KEY (testCaseId) REFERENCES TestCases(id) ON DELETE CASCADE
      );
    ''');
  }

  // CRUD for TestPlans
  void insertTestPlan(Map<String, dynamic> data) {
    db.execute('''
      INSERT INTO TestPlans (id, title, description, macros, createdDate, updatedDate, createdBy, updatedBy, type)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      data['id'],
      data['title'],
      data['description'],
      data['macros'] is String ? data['macros'] : jsonEncode(data['macros']),
      data['createdDate'],
      data['updatedDate'],
      data['createdBy'],
      data['updatedBy'],
      data['type']
    ]);
  }

  Map<String, dynamic>? getTestPlan(String id) {
    var result =
        _rsToMap(db.select('SELECT * FROM TestPlans WHERE id = ?', [id]));
    return result.isNotEmpty ? result.first : null;
  }

  void updateTestPlan(String id, Map<String, dynamic> data) {
    db.execute('''
      UPDATE TestPlans
      SET title = ?, description = ?, macros = ?, updatedDate = ?, updatedBy = ?, type = ?
      WHERE id = ?
    ''', [
      data['title'],
      data['description'],
      data['macros'] is String ? data['macros'] : jsonEncode(data['macros']),
      data['updatedDate'],
      data['updatedBy'],
      data['type'],
      id
    ]);
  }

  void deleteTestPlan(String id) {
    db.execute('DELETE FROM TestPlans WHERE id = ?', [id]);
  }

// CRUD for TestCases
  void insertTestCase(Map<String, dynamic> data) {
    db.execute('''
    INSERT INTO TestCases (id, description, messageToSend, validations)
    VALUES (?, ?, ?, ?)
  ''', [
      data['id'],
      data['description'],
      data['messageToSend'],
      data['validations']
    ]);
  }

  Map<String, dynamic>? getTestCase(String id) {
    var result =
        _rsToMap(db.select('SELECT * FROM TestCases WHERE id = ?', [id]));
    return result.isNotEmpty ? result.first : null;
  }

  void updateTestCase(String id, Map<String, dynamic> data) {
    db.execute('''
    UPDATE TestCases
    SET description = ?, messageToSend = ?, validations = ?
    WHERE id = ?
  ''', [data['description'], data['messageToSend'], data['validations'], id]);
  }

  void deleteTestCase(String id) {
    db.execute('DELETE FROM TestCases WHERE id = ?', [id]);
  }

// CRUD for TestPlanResults
  void insertTestPlanResult(Map<String, dynamic> data) {
    db.execute('''
    INSERT INTO TestPlanResults (id, testPlanId, ranOn, executionDate, status)
    VALUES (?, ?, ?, ?, ?)
  ''', [
      data['id'],
      data['testPlanId'],
      data['ranOn'],
      data['executionDate'],
      data['status']
    ]);
  }

  Map<String, dynamic>? getTestPlanResult(String id) {
    var result =
        _rsToMap(db.select('SELECT * FROM TestPlanResults WHERE id = ?', [id]));
    return result.isNotEmpty ? result.first : null;
  }

  void updateTestPlanResult(String id, Map<String, dynamic> data) {
    db.execute('''
    UPDATE TestPlanResults
    SET testPlanId = ?, ranOn = ?, executionDate = ?, status = ?
    WHERE id = ?
  ''', [
      data['testPlanId'],
      data['ranOn'],
      data['executionDate'],
      data['status'],
      id
    ]);
  }

  void deleteTestCaseResultsByPlanResultId(String id) {
    db.execute('DELETE FROM TestCaseResults WHERE testPlanResultId = ?', [id]);
  }

  void deleteTestPlanResult(String id) {
    db.execute('DELETE FROM TestPlanResults WHERE id = ?', [id]);
  }

// CRUD for TestCaseResults
  void insertTestCaseResult(Map<String, dynamic> data) {
    db.execute('''
    INSERT INTO TestCaseResults (id, testCaseId, testPlanResultId, ranOn, executionDate, status, messageSent, messageReceived, resultSummary)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  ''', [
      data['id'],
      data['testCaseId'],
      data['testPlanResultId'],
      data['ranOn'],
      data['executionDate'],
      data['status'],
      data['messageSent'],
      data['messageReceived'],
      data['resultSummary']
    ]);
  }

  Map<String, dynamic>? getTestCaseResult(String id) {
    var result =
        _rsToMap(db.select('SELECT * FROM TestCaseResults WHERE id = ?', [id]));
    return result.isNotEmpty ? result.first : null;
  }

  void updateTestCaseResult(String id, Map<String, dynamic> data) {
    db.execute('''
    UPDATE TestCaseResults
    SET testCaseId = ?, testPlanResultId = ?, ranOn = ?, executionDate = ?, status = ?, messageSent = ?, messageReceived = ?, resultSummary = ?
    WHERE id = ?
  ''', [
      data['testCaseId'],
      data['testPlanResultId'],
      data['ranOn'],
      data['executionDate'],
      data['status'],
      data['messageSent'],
      data['messageReceived'],
      data['resultSummary'],
      id
    ]);
  }

  // Retrieve all TestPlans
  List<Map<String, dynamic>> getAllTestPlans() {
    return _rsToMap(db.select('SELECT * FROM TestPlans'));
  }

  // Add a TestCase to a TestPlan
  void addTestCaseToTestPlan(
      String testPlanId, Map<String, dynamic> testCaseData) {
    // Insert TestCase if it doesn't exist
    db.execute('''
    INSERT OR IGNORE INTO TestCases (id, description, messageToSend, validations)
    VALUES (?, ?, ?, ?)
  ''', [
      testCaseData['id'],
      testCaseData['description'],
      testCaseData['messageToSend'],
      testCaseData['validations']
    ]);

    // Link TestCase to TestPlan
    db.execute('''
    INSERT INTO TestPlanTestCases (testPlanId, testCaseId)
    VALUES (?, ?)
  ''', [testPlanId, testCaseData['id']]);
  }

  // Remove a TestCase from a TestPlan
  void removeTestCaseFromTestPlan(String testPlanId, String testCaseId) {
    db.execute('''
      DELETE FROM TestPlanTestCases
      WHERE testPlanId = ? AND testCaseId = ?
    ''', [testPlanId, testCaseId]);
  }

  // Get TestCases of a TestPlan
  List<Map<String, dynamic>> getTestCasesOfTestPlan(String testPlanId) {
    return _rsToMap(db.select('''
      SELECT TestCases.*
      FROM TestCases
      JOIN TestPlanTestCases ON TestCases.id = TestPlanTestCases.testCaseId
      WHERE TestPlanTestCases.testPlanId = ?
    ''', [testPlanId]));
  }

  void deleteTestCaseResult(String id) {
    db.execute('DELETE FROM TestCaseResults WHERE id = ?', [id]);
  }

  // Retrieve all TestCases
  List<Map<String, dynamic>> getAllTestCases() {
    return _rsToMap(db.select('SELECT * FROM TestCases'));
  }

  // Get the latest TestPlanResults
  List<Map<String, dynamic>> getLatestTestPlanResults() {
    return _rsToMap(db.select('''
      SELECT * FROM TestPlanResults
      ORDER BY executionDate DESC
    '''));
  }

  // Get the latest TestPlanResults for a specific device
  List<Map<String, dynamic>> getLatestTestPlanResultsForDevice(
      String deviceId) {
    return _rsToMap(db.select('''
      SELECT * FROM TestPlanResults
      WHERE ranOn = ?
      ORDER BY executionDate DESC
    ''', [deviceId]));
  }

  List<Map<String, dynamic>> getTestPlanResultsByIdOrDeviceId(
      List<String>? testPlanIds, String? deviceId) {
    // Return an empty list if both parameters are null or empty
    if ((testPlanIds == null || testPlanIds.isEmpty) &&
        (deviceId == null || deviceId.isEmpty)) {
      return [];
    }

    // Constructing the SQL query dynamically
    List<String> conditions = [];
    List<dynamic> parameters = [];

    if (testPlanIds != null && testPlanIds.isNotEmpty) {
      conditions
          .add('testPlanId IN (${testPlanIds.map((_) => '?').join(', ')})');
      parameters.addAll(testPlanIds);
    }

    if (deviceId != null && deviceId.isNotEmpty) {
      conditions.add('ranOn = ?');
      parameters.add(deviceId);
    }

    String whereClause = conditions.join(' OR ');

    ResultSet results = db.select('''
    SELECT * FROM TestPlanResults
    WHERE $whereClause
    ORDER BY executionDate DESC
  ''', parameters);

    List<Map<String, dynamic>> testPlanResults = _rsToMap(results);

    // Populating TestCaseResults for each TestPlanResult
    for (var testPlanResult in testPlanResults) {
      var testCaseResults =
          getTestCaseResultsForTestPlanResultId(testPlanResult['id']);
      testPlanResult['testCaseResults'] = testCaseResults;
    }

    return testPlanResults;
  }

  List<Map<String, dynamic>> getTestPlanResultsByDeviceIdAndStatus(
      String deviceId, int status) {
    // Return an empty list if both parameters are null or empty
    if (deviceId.isEmpty) {
      return [];
    }

    ResultSet results = db.select('''
    SELECT * FROM TestPlanResults
    WHERE ranOn = ? and status = ?
    ORDER BY executionDate DESC
  ''', [deviceId, status]);

    List<Map<String, dynamic>> testPlanResults = _rsToMap(results);

    // Populating TestCaseResults for each TestPlanResult
    for (var testPlanResult in testPlanResults) {
      var testCaseResults =
          getTestCaseResultsForTestPlanResultId(testPlanResult['id']);
      testPlanResult['testCaseResults'] = testCaseResults;
    }

    return testPlanResults;
  }

  // Get TestCaseResults for a specific TestPlanResult
  List<Map<String, dynamic>> getTestCaseResultsForTestPlanResultId(
      String testPlanResultId) {
    return _rsToMap(db.select(
        '''SELECT * FROM TestCaseResults WHERE testPlanResultId = ?;''',
        [testPlanResultId]));
  }

  List<Map<String, dynamic>> _rsToMap(ResultSet results) {
    List<Map<String, dynamic>> list = [];
    for (var row in results) {
      Map<String, dynamic> rowMap = {};
      for (var columnName in row.keys) {
        rowMap[columnName] = row[columnName];
      }
      list.add(rowMap);
    }
    return list;
  }
}
