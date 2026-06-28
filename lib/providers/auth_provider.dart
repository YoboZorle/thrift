import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../services/auth/auth_identity.dart';
import '../services/auth/auth_service.dart';
import '../services/data_repository.dart';
import '../services/local_storage_service.dart';

/// Bridges a *real* authenticated identity (phone / Google / Apple via
/// [AuthService]) to a UNIQUE in-app user record keyed by the identity's uid.
/// Every signed-in account therefore owns its own profile, items, matches and
/// chats. Required profile setup (name, gender, DOB, city/state) fills in the
/// rest before the app unlocks.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth, this._repo, this._storage);

  final AuthService _auth;
  final DataRepository _repo;
  final LocalStorageService _storage;

  AuthIdentity? _identity;
  UserModel? _currentUser;
  bool _loading = true;

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

  /// Setup is required until the unique user has the essentials filled in.
  bool get needsProfileSetup {
    final u = _currentUser;
    if (!isAuthenticated || u == null) return false;
    return u.name.trim().isEmpty ||
        u.gender == null ||
        u.dob == null ||
        u.city.trim().isEmpty;
  }

  bool get codeSent => _phoneHandle != null;
  String? get pendingPhone => _pendingPhone;

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();

    await _auth.init();
    _identity = await _auth.currentIdentity();

    if (_identity != null) {
      await _bindPersona();
    }

    _loading = false;
    notifyListeners();
  }

  /// Resolve (and persist) the unique user record for the current identity.
  Future<void> _bindPersona() async {
    final uid = _identity!.uid;
    var user = await _repo.getUser(uid);
    user ??= UserModel(id: uid, name: '', createdAt: DateTime.now());

    // Overlay verified contact info from the real identity.
    user = user.copyWith(
      phone: _identity!.phoneNumber ?? user.phone,
      email: _identity!.email ?? user.email,
    );
    final dn = _identity!.displayName;
    if (user.name.trim().isEmpty && dn != null && dn.isNotEmpty) {
      user = user.copyWith(name: dn);
    }

    await _repo.upsertUser(user);
    await _storage.writeString(AppConstants.kCurrentUserId, uid);
    _currentUser = user;
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

  // ---- Profile setup (required) ----
  Future<void> completeProfileSetup({
    required String name,
    required String city,
    required String state,
    required String gender,
    required DateTime dob,
    String bio = '',
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(
      name: name,
      city: city,
      state: state,
      location: '$city, $state',
      gender: gender,
      dob: dob,
      bio: bio,
      avatarUrl: avatarUrl,
    );
    await _repo.upsertUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? city,
    String? state,
    String? bio,
    String? gender,
    DateTime? dob,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;
    final city0 = city ?? _currentUser!.city;
    final state0 = state ?? _currentUser!.state;
    final updated = _currentUser!.copyWith(
      name: name,
      city: city,
      state: state,
      location: (city != null || state != null) ? '$city0, $state0' : null,
      bio: bio,
      gender: gender,
      dob: dob,
      avatarUrl: avatarUrl,
    );
    await _repo.upsertUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _identity = null;
    resetPhoneFlow();
    notifyListeners();
  }
}
