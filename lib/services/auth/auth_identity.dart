/// Provider-agnostic representation of an authenticated identity.
class AuthIdentity {
  final String uid;
  final String? phoneNumber;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String provider; // 'phone' | 'google' | 'apple' | 'dev'

  const AuthIdentity({
    required this.uid,
    this.phoneNumber,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.provider,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'phoneNumber': phoneNumber,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'provider': provider,
      };

  factory AuthIdentity.fromMap(Map<String, dynamic> map) => AuthIdentity(
        uid: map['uid'] as String,
        phoneNumber: map['phoneNumber'] as String?,
        email: map['email'] as String?,
        displayName: map['displayName'] as String?,
        photoUrl: map['photoUrl'] as String?,
        provider: (map['provider'] ?? 'dev') as String,
      );
}

/// Handle returned once an SMS code has been dispatched.
class PhoneAuthHandle {
  final String verificationId;
  const PhoneAuthHandle(this.verificationId);
}

/// Thrown for auth failures so the UI can show a friendly message.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
