import 'dart:convert';

class OcppMessage {
  final int messageType;
  final String messageId;
  final String? actionName;
  final Map<String, dynamic> data;

  OcppMessage._internal({
    required this.messageType,
    required this.messageId,
    required this.data,
    this.actionName,
  });

  static OcppMessage? fromPlainText(String message) {
    try {
      List<dynamic> _parsedMessage = jsonDecode(message);
      if (_parsedMessage.length < 2 || _parsedMessage.length > 4) {
        return null; // Ensuring message format is correct
      }

      final int _messageType = _parsedMessage[0];
      final String _messageId = _parsedMessage[1];
      final String? _actionName = _parsedMessage.length > 2 && _parsedMessage[2] is String ? _parsedMessage[2] : null;
      final Map<String, dynamic> _data = _parsedMessage.length > 3 && _parsedMessage[3] is Map<String, dynamic> ? _parsedMessage[3] : {};

      return OcppMessage._internal(
        messageType: _messageType,
        messageId: _messageId,
        actionName: _actionName,
        data: _data,
      );
    } catch (err) {
      // Optionally, you can log the error or handle it differently
      return null;
    }
  }

  @override
  String toString() {
    List<dynamic> messageList = [messageType, messageId];
    
    // Add actionName to the list if it's not null
    if (actionName != null) {
      messageList.add(actionName);
    }

    // Always add data (which could be an empty map)
    messageList.add(data);

    return jsonEncode(messageList);
  }
}
