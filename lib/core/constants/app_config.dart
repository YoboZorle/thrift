/// Build-time configuration. This build is intentionally **backend-free**:
/// all data and auth sessions persist locally on the device. A real backend
/// can be added later behind the existing service interfaces without changing
/// the rest of the app.
class AppConfig {
  AppConfig._();

  /// Items listed within this window show the "JUST LISTED" badge.
  static const int justListedHours = 72;

  /// Fallback city label shown before/without location permission.
  static const String fallbackLocationLabel = 'Location off';
}
