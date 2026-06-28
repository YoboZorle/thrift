/// A match links two items (and their owners). Chat is scoped to this match,
/// i.e. to that specific product-for-product swap.
class MatchModel {
  final String id;
  final String userAId;
  final String itemAId;
  final String userBId;
  final String itemBId;
  final DateTime createdAt;
  final DateTime lastActivity;
  final bool seen; // has the receiving user opened it yet

  const MatchModel({
    required this.id,
    required this.userAId,
    required this.itemAId,
    required this.userBId,
    required this.itemBId,
    required this.createdAt,
    required this.lastActivity,
    this.seen = false,
  });

  bool involves(String userId) => userAId == userId || userBId == userId;

  /// Returns the item id that belongs to [userId] within this match.
  String myItemId(String userId) => userAId == userId ? itemAId : itemBId;

  /// Returns the other party's item id.
  String theirItemId(String userId) => userAId == userId ? itemBId : itemAId;

  /// Returns the other party's user id.
  String otherUserId(String userId) => userAId == userId ? userBId : userAId;

  MatchModel copyWith({DateTime? lastActivity, bool? seen}) => MatchModel(
        id: id,
        userAId: userAId,
        itemAId: itemAId,
        userBId: userBId,
        itemBId: itemBId,
        createdAt: createdAt,
        lastActivity: lastActivity ?? this.lastActivity,
        seen: seen ?? this.seen,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userAId': userAId,
        'itemAId': itemAId,
        'userBId': userBId,
        'itemBId': itemBId,
        'createdAt': createdAt.toIso8601String(),
        'lastActivity': lastActivity.toIso8601String(),
        'seen': seen,
      };

  factory MatchModel.fromMap(Map<String, dynamic> map) => MatchModel(
        id: map['id'] as String,
        userAId: map['userAId'] as String,
        itemAId: map['itemAId'] as String,
        userBId: map['userBId'] as String,
        itemBId: map['itemBId'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        lastActivity: DateTime.parse(
            (map['lastActivity'] ?? map['createdAt']) as String),
        seen: (map['seen'] ?? false) as bool,
      );
}
