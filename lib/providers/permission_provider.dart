import 'package:flutter/foundation.dart';

import '../services/location_service.dart';
import '../services/permission_service.dart';

/// Tracks real OS notification + location permission state. Permissions are
/// COMPULSORY: the app gates on [needsNotification] / [needsLocation] until both
/// are granted, re-checked on every launch and resume.
class PermissionProvider extends ChangeNotifier {
  PermissionProvider(this._perm, this._location);

  final PermissionService _perm;
  final LocationService _location;

  bool notifGranted = false;
  bool locationGranted = false;
  bool notifPermDenied = false; // permanently denied -> needs Settings
  bool locationPermDenied = false;

  bool get needsNotification => !notifGranted;
  bool get needsLocation => !locationGranted;
  bool get allGranted => notifGranted && locationGranted;

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

  Future<void> openSettings() => _perm.openSettings();
}
