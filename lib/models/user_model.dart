import 'enums.dart';

class UserModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String location; // human-readable "City, State"
  final String city;
  final String state;
  final String bio;
  final String? phone;
  final String? email;
  final String? gender;
  final DateTime? dob;
  final DateTime createdAt;

  // Manual identity verification.
  final VerificationStatus verificationStatus;
  final List<String> verificationPhotos; // selfies the user uploaded
  final String? idType; // e.g. "NIN card", "Driver's license"
  final String? idImage; // the uploaded ID document

  const UserModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.location = '',
    this.city = '',
    this.state = '',
    this.bio = '',
    this.phone,
    this.email,
    this.gender,
    this.dob,
    required this.createdAt,
    this.verificationStatus = VerificationStatus.unverified,
    this.verificationPhotos = const [],
    this.idType,
    this.idImage,
  });

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    String? location,
    String? city,
    String? state,
    String? bio,
    String? phone,
    String? email,
    String? gender,
    DateTime? dob,
    VerificationStatus? verificationStatus,
    List<String>? verificationPhotos,
    String? idType,
    String? idImage,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      location: location ?? this.location,
      city: city ?? this.city,
      state: state ?? this.state,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      createdAt: createdAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationPhotos: verificationPhotos ?? this.verificationPhotos,
      idType: idType ?? this.idType,
      idImage: idImage ?? this.idImage,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'location': location,
        'city': city,
        'state': state,
        'bio': bio,
        'phone': phone,
        'email': email,
        'gender': gender,
        'dob': dob?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'verificationStatus': verificationStatus.name,
        'verificationPhotos': verificationPhotos,
        'idType': idType,
        'idImage': idImage,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        name: map['name'] as String,
        avatarUrl: map['avatarUrl'] as String?,
        location: (map['location'] ?? '') as String,
        city: (map['city'] ?? '') as String,
        state: (map['state'] ?? '') as String,
        bio: (map['bio'] ?? '') as String,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        gender: map['gender'] as String?,
        dob: map['dob'] == null ? null : DateTime.tryParse(map['dob'] as String),
        createdAt: DateTime.parse(map['createdAt'] as String),
        verificationStatus:
            VerificationStatusX.fromName(map['verificationStatus'] as String?),
        verificationPhotos:
            ((map['verificationPhotos'] ?? const []) as List).cast<String>(),
        idType: map['idType'] as String?,
        idImage: map['idImage'] as String?,
      );
}
