class UserModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String location;
  final String bio;
  final String? phone;
  final String? email;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.location = '',
    this.bio = '',
    this.phone,
    this.email,
    required this.createdAt,
  });

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    String? location,
    String? bio,
    String? phone,
    String? email,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'location': location,
        'bio': bio,
        'phone': phone,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        name: map['name'] as String,
        avatarUrl: map['avatarUrl'] as String?,
        location: (map['location'] ?? '') as String,
        bio: (map['bio'] ?? '') as String,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
