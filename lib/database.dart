import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Database {
  static const String _messagesKey = 'messages';
  late final SharedPreferences _prefs;

  Database() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> storeMessage(String deviceId, String content, String sender) async {
    await _init(); // Ensure _prefs is initialized
    final message = Message(content, sender, DateTime.now());
    final messageJson = message.toJson();

    // Load existing messages for this device
    List<dynamic> deviceMessages = jsonDecode(_prefs.getString(deviceId) ?? '[]');
    deviceMessages.add(messageJson);

    // Store the updated message list
    await _prefs.setString(deviceId, jsonEncode(deviceMessages));
    print('Message stored for device $deviceId');
  }

  Future<List<Message>> getMessages(String deviceId) async {
    await _init(); // Ensure _prefs is initialized
    final messagesJson = jsonDecode(_prefs.getString(deviceId) ?? '[]') as List;
    
    return messagesJson.map((json) => Message.fromJson(json)).toList();
  }

  Future<List<String>> getAllDeviceIdsInDatabase() async {
    await _init(); // Ensure _prefs is initialized
    Set<String> keys = _prefs.getKeys();

    // Filter out non-deviceId keys if there are any
    return keys.where((k) => k != _messagesKey).toList();
  }
}
