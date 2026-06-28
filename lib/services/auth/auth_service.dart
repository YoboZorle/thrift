import 'auth_identity.dart';

/// Identity provider abstraction. Real (Firebase) and dev implementations both
/// satisfy this, so the rest of the app never depends on Firebase directly.
abstract class AuthService {
  Future<void> init();

  /// The currently signed-in identity, or null if signed out.
  Future<AuthIdentity?> currentIdentity();

  /// Starts phone verification. Resolves once the SMS code has been sent
  /// (returning a [PhoneAuthHandle]). On platforms with auto-retrieval,
  /// [onAutoVerified] may fire instead/in addition. [onFailed] reports errors.
  Future<PhoneAuthHandle> verifyPhone({
    required String phoneNumber,
    required void Function(AuthIdentity identity) onAutoVerified,
    required void Function(String message) onFailed,
  });

  Future<AuthIdentity> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  });

  Future<AuthIdentity> signInWithGoogle();
  Future<AuthIdentity> signInWithApple();

  Future<void> signOut();
}
