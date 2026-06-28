import 'enums.dart';

/// A directional expression of interest: "User [swiperUserId] likes item
/// [targetItemId] (owned by [targetUserId])."
///
/// A match is formed at the USER level: when two people have each liked at
/// least one of the other's items. The specific items to exchange are then
/// arranged in chat. [swiperItemId] is retained (optional) so a future backend
/// can attach a specific offered item if desired.
class SwipeModel {
  final String id;
  final String swiperUserId;
  final String swiperItemId; // optional: a specific offered item ('' if none)
  final String targetUserId;
  final String targetItemId; // the item being liked
  final SwipeDirection direction;
  final DateTime createdAt;

  const SwipeModel({
    required this.id,
    required this.swiperUserId,
    this.swiperItemId = '',
    required this.targetUserId,
    required this.targetItemId,
    required this.direction,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'swiperUserId': swiperUserId,
        'swiperItemId': swiperItemId,
        'targetUserId': targetUserId,
        'targetItemId': targetItemId,
        'direction': direction.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SwipeModel.fromMap(Map<String, dynamic> map) => SwipeModel(
        id: map['id'] as String,
        swiperUserId: map['swiperUserId'] as String,
        swiperItemId: (map['swiperItemId'] ?? '') as String,
        targetUserId: map['targetUserId'] as String,
        targetItemId: map['targetItemId'] as String,
        direction: SwipeDirectionX.fromName(map['direction'] as String?),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
