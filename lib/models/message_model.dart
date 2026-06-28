class MessageModel {
  final String id;
  final String matchId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'matchId': matchId,
        'senderId': senderId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        id: map['id'] as String,
        matchId: map['matchId'] as String,
        senderId: map['senderId'] as String,
        text: map['text'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
