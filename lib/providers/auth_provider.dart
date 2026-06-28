import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../services/auth/auth_identity.dart';
import '../services/auth/auth_service.dart';
import '../services/data_repository.dart';
import '../services/local_storage_service.dart';
import '../services/seed_data.dart';

/// Bridges a *real* authenticated identity (phone / Google / Apple via
/// [AuthService]) to the in-app "swap persona" stored in the data layer.
///
/// The persona is pinned to the seeded `user_me` record so the matchmaking demo
/// (sample listings + incoming likes) works end-to-end the moment you sign in.
/// Your real phone/email/name are overlaid onto that persona.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth, this._repo, this._storage);

  final AuthService _auth;
  final DataRepository _repo;
  final LocalStorageService _storage;

  AuthIdentity? _identity;
  UserModel? _currentUser;
  bool _loading = true;
  bool _profileSetupDone = false;

  // Phone verification state
  PhoneAuthHandle? _phoneHandle;
  String? _pendingPhone;
  String? phoneError;
  String? otpError;
  String? lastError;
  bool sendingCode = false;
  bool verifyingCode = false;
  bool busy = false;

  // ---- Getters ----
  AuthIdentity? get identity => _identity;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _loading;
  bool get isAuthenticated => _identity != null;
  bool get needsProfileSetup => isAuthenticated && !_profileSetupDone;
  bool get codeSent => _phoneHandle != null;
  String? get pendingPhone => _pendingPhone;

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();

    await _auth.init();
    _identity = await _auth.currentIdentity();
    _profileSetupDone = _storage.readBool(AppConstants.kProfileSetupDone);

    if (_identity != null) {
      await _bindPersona();
    }

    _loading = false;
    notifyListeners();
  }

  /// Resolve (and persist) the swap persona for the current identity.
  Future<void> _bindPersona() async {
    final savedId =
        _storage.readString(AppConstants.kCurrentUserId) ?? SeedData.meId;
    var persona =
        await _repo.getUser(savedId) ?? await _repo.getUser(SeedData.meId);

    persona ??= UserModel(
      id: SeedData.meId,
      name: 'You',
      location: '',
      createdAt: DateTime.now(),
    );

    // Overlay verified contact info from the real identity.
    persona = persona.copyWith(
      phone: _identity!.phoneNumber ?? persona.phone,
      email: _identity!.email ?? persona.email,
    );
    // Adopt the provider's name only if the persona is still the default.
    final dn = _identity!.displayName;
    if ((persona.name.isEmpty || persona.name == 'You') &&
        dn != null &&
        dn.isNotEmpty) {
      persona = persona.copyWith(name: dn);
    }

    await _repo.upsertUser(persona);
    await _storage.writeString(AppConstants.kCurrentUserId, persona.id);
    _currentUser = persona;
  }

  Future<void> _onAuthenticated(AuthIdentity id) async {
    _identity = id;
    await _bindPersona();
    notifyListeners();
  }

  // ---- Phone ----
  Future<bool> startPhoneAuth(String phoneE164) async {
    _pendingPhone = phoneE164;
    phoneError = null;
    _phoneHandle = null;
    sendingCode = true;
    notifyListeners();
    try {
      _phoneHandle = await _auth.verifyPhone(
        phoneNumber: phoneE164,
        onAutoVerified: (id) async => _onAuthenticated(id),
        onFailed: (m) {
          phoneError = m;
          sendingCode = false;
          notifyListeners();
        },
      );
      sendingCode = false;
      notifyListeners();
      return _phoneHandle != null;
    } catch (e) {
      phoneError = e is AuthException ? e.message : 'Could not send the code.';
      sendingCode = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmCode(String code) async {
    if (_phoneHandle == null) {
      otpError = 'Request a new code.';
      notifyListeners();
      return false;
    }
    otpError = null;
    verifyingCode = true;
    notifyListeners();
    try {
      final id = await _auth.confirmSmsCode(
        verificationId: _phoneHandle!.verificationId,
        smsCode: code,
      );
      await _onAuthenticated(id);
      verifyingCode = false;
      notifyListeners();
      return true;
    } catch (e) {
      otpError = e is AuthException ? e.message : 'Invalid code.';
      verifyingCode = false;
      notifyListeners();
      return false;
    }
  }

  void resetPhoneFlow() {
    _phoneHandle = null;
    _pendingPhone = null;
    phoneError = null;
    otpError = null;
    notifyListeners();
  }

  // ---- Social / guest ----
  Future<bool> _runSocial(Future<AuthIdentity> Function() fn) async {
    lastError = null;
    busy = true;
    notifyListeners();
    try {
      final id = await fn();
      await _onAuthenticated(id);
      busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e is AuthException ? e.message : 'Sign-in failed.';
      busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> continueWithGoogle() => _runSocial(_auth.signInWithGoogle);
  Future<bool> continueWithApple() => _runSocial(_auth.signInWithApple);
  Future<bool> continueAsGuest() => _runSocial(() => _auth.signInGuest());

  // ---- Profile setup ----
  Future<void> completeProfileSetup({
    required String name,
    required String location,
    String bio = '',
    String? avatarUrl,
  }) async {
    if (_currentUser != null) {
      final updated = _currentUser!.copyWith(
        name: name,
        location: location,
        bio: bio,
        avatarUrl: avatarUrl,
      );
      await _repo.upsertUser(updated);
      _currentUser = updated;
    }
    _profileSetupDone = true;
    await _storage.writeBool(AppConstants.kProfileSetupDone, true);
    notifyListeners();
  }

  Future<void> skipProfileSetup() async {
    _profileSetupDone = true;
    await _storage.writeBool(AppConstants.kProfileSetupDone, true);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? location,
    String? bio,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(
      name: name,
      location: location,
      bio: bio,
      avatarUrl: avatarUrl,
    );
    await _repo.upsertUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  /// Dev helper: switch the in-app persona (NOT the auth identity) to another
  /// seeded account so you can like back and test reciprocal matches.
  Future<void> devSwitchPersona(String userId) async {
    final user = await _repo.getUser(userId);
    if (user == null) return;
    _currentUser = user;
    await _storage.writeString(AppConstants.kCurrentUserId, userId);
    notifyListeners();
  }

  Future<List<UserModel>> demoAccounts() => _repo.getUsers();

  Future<void> signOut() async {
    await _auth.signOut();
    _identity = null;
    resetPhoneFlow();
    notifyListeners();
  }
}
