import 'enums.dart';

/// A single swipe is directional and product-to-product:
/// "I want to swap MY item (swiperItemId) for THEIR item (targetItemId)".
///
/// A match is formed when a reciprocal like exists for the same item pair.
class SwipeModel {
  final String id;
  final String swiperUserId;
  final String swiperItemId; // the item I'm offering
  final String targetUserId;
  final String targetItemId; // the item I want
  final SwipeDirection direction;
  final DateTime createdAt;

  const SwipeModel({
    required this.id,
    required this.swiperUserId,
    required this.swiperItemId,
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
        swiperItemId: map['swiperItemId'] as String,
        targetUserId: map['targetUserId'] as String,
        targetItemId: map['targetItemId'] as String,
        direction: SwipeDirectionX.fromName(map['direction'] as String?),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
