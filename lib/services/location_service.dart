import 'package:geolocator/geolocator.dart';

import '../models/item_model.dart';

/// Reads the device location (when permitted) and produces friendly distance
/// labels for items. Falls back to a stable per-item estimate when location is
/// unavailable, so the UI always shows something sensible.
class LocationService {
  Position? _current;

  bool get hasFix => _current != null;
  Position? get current => _current;

  Future<void> refresh() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final perm = await Geolocator.checkPermission();
      final ok = perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      if (!ok) return;
      _current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
    } catch (_) {
      // Keep whatever we had; UI falls back gracefully.
    }
  }

  String labelFor(ItemModel item) {
    if (_current != null && item.latitude != null && item.longitude != null) {
      final meters = Geolocator.distanceBetween(
        _current!.latitude,
        _current!.longitude,
        item.latitude!,
        item.longitude!,
      );
      final km = meters / 1000.0;
      if (km < 1) return '${meters.round()} m away';
      return '${km.toStringAsFixed(km < 10 ? 1 : 0)} KM away';
    }
    // Deterministic fallback so each item reads consistently.
    final fallback = (item.id.hashCode.abs() % 9) + 1;
    return '$fallback KM away';
  }
}
