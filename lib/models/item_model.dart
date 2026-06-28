import 'enums.dart';

/// A thrift good a user has listed for swapping.
class ItemModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final ItemCategory category;
  final ItemCondition condition;

  /// Each entry is either a network URL (starts with http) or a local file path.
  final List<String> images;

  /// Optional estimated value (helps users gauge a fair swap). Not money based.
  final double? estimatedValue;

  /// Optional geo for distance display ("2 KM away").
  final double? latitude;
  final double? longitude;

  final bool isActive;
  final DateTime createdAt;

  const ItemModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.images,
    this.estimatedValue,
    this.latitude,
    this.longitude,
    this.isActive = true,
    required this.createdAt,
  });

  String get primaryImage => images.isNotEmpty ? images.first : '';

  ItemModel copyWith({
    String? title,
    String? description,
    ItemCategory? category,
    ItemCondition? condition,
    List<String>? images,
    double? estimatedValue,
    double? latitude,
    double? longitude,
    bool? isActive,
  }) {
    return ItemModel(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      images: images ?? this.images,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'ownerId': ownerId,
        'title': title,
        'description': description,
        'category': category.name,
        'condition': condition.name,
        'images': images,
        'estimatedValue': estimatedValue,
        'latitude': latitude,
        'longitude': longitude,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ItemModel.fromMap(Map<String, dynamic> map) => ItemModel(
        id: map['id'] as String,
        ownerId: map['ownerId'] as String,
        title: map['title'] as String,
        description: (map['description'] ?? '') as String,
        category: ItemCategoryX.fromName(map['category'] as String?),
        condition: ItemConditionX.fromName(map['condition'] as String?),
        images: (map['images'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        estimatedValue: (map['estimatedValue'] as num?)?.toDouble(),
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        isActive: (map['isActive'] ?? true) as bool,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
