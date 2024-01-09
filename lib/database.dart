import 'package:dart_websocket_server/models/message.dart';
import 'package:sqlite3/sqlite3.dart';

class MyDatabase {
  final Database _db = sqlite3.open('.database');

  MyDatabase() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deviceId TEXT,
        content TEXT,
        sender TEXT,
        timestamp TEXT
      );
    ''');
  }

  void storeMessage(String deviceId, String content, String sender) {
    final statement = _db.prepare('INSERT INTO messages (deviceId, content, sender, timestamp) VALUES (?, ?, ?, ?)');
    statement.execute([deviceId, content, sender, DateTime.now().toIso8601String()]);
    statement.dispose();
  }

  List<Message> getMessages(String deviceId) {
    final result = _db.select('SELECT * FROM messages WHERE deviceId = ?', [deviceId]);
    return result.map((row) => Message.fromMap(row)).toList();
  }

  List<String> getAllDeviceIdsInDatabase() {
    final result = _db.select('SELECT DISTINCT deviceId FROM messages');
    return result.map((row) => row['deviceId'] as String).toList();
  }

  // Close the database
  void close() {
    _db.dispose();
  }
}
