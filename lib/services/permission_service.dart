import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Wraps the real OS permission prompts for notifications and location.
class PermissionService {
  // ---- Notifications (permission_handler) ----
  Future<bool> isNotificationGranted() async =>
      await Permission.notification.isGranted;

  Future<bool> isNotificationPermanentlyDenied() async =>
      await Permission.notification.isPermanentlyDenied;

  /// Triggers the OS prompt. Returns true if granted.
  Future<bool> requestNotification() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // ---- Location (geolocator) ----
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  Future<bool> isLocationGranted() async {
    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<bool> isLocationPermanentlyDenied() async {
    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.deniedForever;
  }

  /// Triggers the OS prompt. Returns true if granted.
  Future<bool> requestLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      // Can't grant a usable permission while the service is off.
      final perm = await Geolocator.checkPermission();
      return perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<void> openSettings() => openAppSettings();
}
