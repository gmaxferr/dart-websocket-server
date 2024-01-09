class Message {
  final int? id;
  final String deviceId;
  final String content;
  final String sender;
  final String timestamp;

  Message({this.id, required this.deviceId, required this.content, required this.sender, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'content': content,
      'sender': sender,
      'timestamp': timestamp
    };
  }

  static Message fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      deviceId: map['deviceId'],
      content: map['content'],
      sender: map['sender'],
      timestamp: map['timestamp'],
    );
  }
}
