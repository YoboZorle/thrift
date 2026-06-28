import 'package:flutter/foundation.dart';

import '../services/location_service.dart';
import '../services/permission_service.dart';

/// Tracks real OS notification + location permission state and drives the
/// "ask wisely" flow: prime once per session, re-check on resume, and surface a
/// settings shortcut when a permission has been permanently denied.
class PermissionProvider extends ChangeNotifier {
  PermissionProvider(this._perm, this._location);

  final PermissionService _perm;
  final LocationService _location;

  bool notifGranted = false;
  bool locationGranted = false;
  bool notifPermDenied = false;
  bool locationPermDenied = false;
  bool _primedThisSession = false;

  bool get allGranted => notifGranted && locationGranted;
  bool get anyMissing => !notifGranted || !locationGranted;
  bool get primedThisSession => _primedThisSession;

  /// Show the priming UI only if something is missing, we haven't primed yet
  /// this session, and at least one missing permission is still askable.
  bool get needsPriming => anyMissing && !_primedThisSession && !_allBlocked;

  /// Every missing permission is permanently denied → only Settings can fix it.
  bool get _allBlocked {
    final notifBlocked = !notifGranted ? notifPermDenied : true;
    final locBlocked = !locationGranted ? locationPermDenied : true;
    return notifBlocked && locBlocked;
  }

  /// True when something is missing AND can only be resolved in Settings.
  bool get blockedInSettings =>
      anyMissing &&
      (!notifGranted ? notifPermDenied : true) &&
      (!locationGranted ? locationPermDenied : true);

  Future<void> refresh() async {
    notifGranted = await _perm.isNotificationGranted();
    locationGranted = await _perm.isLocationGranted();
    notifPermDenied = await _perm.isNotificationPermanentlyDenied();
    locationPermDenied = await _perm.isLocationPermanentlyDenied();
    if (locationGranted) await _location.refresh();
    notifyListeners();
  }

  Future<bool> requestNotification() async {
    final granted = await _perm.requestNotification();
    await refresh();
    return granted;
  }

  Future<bool> requestLocation() async {
    final granted = await _perm.requestLocation();
    if (granted) await _location.refresh();
    await refresh();
    return granted;
  }

  void markPrimed() {
    _primedThisSession = true;
    notifyListeners();
  }

  Future<void> openSettings() => _perm.openSettings();
}
