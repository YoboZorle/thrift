/// Build-time configuration. This build is intentionally **backend-free**:
/// all data and auth sessions persist locally on the device. A real backend
/// can be added later behind the existing service interfaces without changing
/// the rest of the app.
class AppConfig {
  AppConfig._();

  /// Items listed within this window show the "JUST LISTED" badge.
  static const int justListedHours = 72;

  /// How long a listing stays live and matchable, and how long a "like" stays
  /// valid waiting for the other person to like back. In production this is
  /// 48 hours; for testing the matching/expiry flow it's shortened to 5 minutes.
  static const Duration listingWindow = Duration(minutes: 5);

  /// Fallback city label shown before/without location permission.
  static const String fallbackLocationLabel = 'Location off';
}
