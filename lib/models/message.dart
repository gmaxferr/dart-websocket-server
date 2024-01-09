
class Message {
  final String content;
  final String sender;
  final DateTime timestamp;

  Message(this.content, this.sender, this.timestamp);

  Map<String, dynamic> toJson() => {
        'content': content,
        'sender': sender,
        'timestamp': timestamp.toIso8601String(),
      };

  static Message fromJson(Map<String, dynamic> json) {
    return Message(
      json['content'],
      json['sender'],
      DateTime.parse(json['timestamp']),
    );
  }
}
