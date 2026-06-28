import 'dart:convert';

import '../../core/constants/app_constants.dart';
import '../local_storage_service.dart';
import 'auth_identity.dart';
import 'auth_service.dart';

/// Local, persistent authentication — no backend required. The realistic
/// sign-in *flow* is preserved end-to-end; only the verification is simulated:
///
/// - Phone: a code is "sent" and any 6-digit code is accepted (try `123456`).
/// - Google / Apple: create a persistent local profile (stubbed until a real
///   backend is added).
///
/// Sessions are saved to local storage, so you stay signed in across restarts.
class LocalAuthService implements AuthService {
  LocalAuthService(this._storage);

  final LocalStorageService _storage;
  AuthIdentity? _identity;
  String? _pendingPhone;

  @override
  Future<void> init() async {
    final raw = _storage.readString(AppConstants.kAuthSession);
    if (raw != null && raw.isNotEmpty) {
      try {
        _identity = AuthIdentity.fromMap(
            Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {
        _identity = null;
      }
    }
  }

  Future<void> _persist(AuthIdentity id) async {
    _identity = id;
    await _storage.writeString(
        AppConstants.kAuthSession, jsonEncode(id.toMap()));
  }

  @override
  Future<AuthIdentity?> currentIdentity() async => _identity;

  @override
  Future<PhoneAuthHandle> verifyPhone({
    required String phoneNumber,
    required void Function(AuthIdentity identity) onAutoVerified,
    required void Function(String message) onFailed,
  }) async {
    _pendingPhone = phoneNumber;
    // Simulate the round-trip of sending an SMS.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return PhoneAuthHandle('local-${phoneNumber.hashCode}');
  }

  @override
  Future<AuthIdentity> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (smsCode.trim().length < 6) {
      throw const AuthException('Enter the 6-digit code (try 123456).');
    }
    final phone = _pendingPhone ?? '+10000000000';
    final id = AuthIdentity(
      uid: 'phone_${phone.hashCode}',
      phoneNumber: phone,
      provider: 'phone',
    );
    await _persist(id);
    return id;
  }

  @override
  Future<AuthIdentity> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    const id = AuthIdentity(
      uid: 'google_local',
      email: 'demo.user@gmail.com',
      displayName: 'Demo User',
      provider: 'google',
    );
    await _persist(id);
    return id;
  }

  @override
  Future<AuthIdentity> signInWithApple() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    const id = AuthIdentity(
      uid: 'apple_local',
      email: 'demo.user@icloud.com',
      displayName: 'Demo User',
      provider: 'apple',
    );
    await _persist(id);
    return id;
  }

  @override
  Future<void> signOut() async {
    _identity = null;
    await _storage.writeString(AppConstants.kAuthSession, '');
  }
}
