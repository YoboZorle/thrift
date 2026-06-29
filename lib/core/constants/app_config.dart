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
  /// 48 hours; for testing the matching/expiry flow it's shortened to 15
  /// minutes (enough time to walk the full match + chat + UI flows).
  static const Duration listingWindow = Duration(minutes: 15);

  /// Fallback city label shown before/without location permission.
  static const String fallbackLocationLabel = 'Location off';

  /// Support & reporting. Tapping "Contact support" / "Report" opens a direct
  /// WhatsApp chat with the admin. Replace with your real number in
  /// INTERNATIONAL format, digits only (no '+', spaces or dashes).
  /// e.g. Nigeria: 2348012345678
  static const String adminWhatsAppNumber = '2348000000000';
  static const String supportName = 'ThriftSwap Support';
}
