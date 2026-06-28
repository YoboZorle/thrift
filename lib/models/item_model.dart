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

  /// Owner's city/state at listing time (used for location-based matching).
  final String city;
  final String state;

  /// If the condition is faulty, this describes the fault/defect.
  final String defectNote;

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
    this.city = '',
    this.state = '',
    this.defectNote = '',
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
    String? city,
    String? state,
    String? defectNote,
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
      city: city ?? this.city,
      state: state ?? this.state,
      defectNote: defectNote ?? this.defectNote,
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
        'city': city,
        'state': state,
        'defectNote': defectNote,
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
        city: (map['city'] ?? '') as String,
        state: (map['state'] ?? '') as String,
        defectNote: (map['defectNote'] ?? '') as String,
        isActive: (map['isActive'] ?? true) as bool,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
