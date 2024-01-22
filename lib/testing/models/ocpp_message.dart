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
      final _messageType = _parsedMessage[0];
      final _messageId = _parsedMessage[1];
      final _actionName = _parsedMessage.length > 2 ? _parsedMessage[2] : null;
      final _data = _parsedMessage.length > 3 ? _parsedMessage[3] : {};

      return OcppMessage._internal(
          data: _data,
          messageId: _messageId,
          messageType: _messageType,
          actionName: _actionName);
    } catch (err) {
      return null;
    }
  }
}
