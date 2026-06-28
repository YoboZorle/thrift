/// App-wide constant values and storage keys.
class AppConstants {
  AppConstants._();

  static const String appName = 'ThriftSwap';
  static const String tagline = 'Swap goods, cashlessly.';

  // SharedPreferences keys
  static const String kUsers = 'ts_users';
  static const String kItems = 'ts_items';
  static const String kSwipes = 'ts_swipes';
  static const String kMatches = 'ts_matches';
  static const String kMessages = 'ts_messages';
  static const String kSaved = 'ts_saved';
  static const String kCurrentUserId = 'ts_current_user_id';
  static const String kProfileSetupDone = 'ts_profile_setup_done';
  static const String kSeeded = 'ts_seeded_v3';

  // Local auth session (persists the signed-in identity across restarts)
  static const String kAuthSession = 'ts_auth_session';

  // Swipe behaviour
  static const double swipeThreshold = 110.0;
  static const double maxRotation = 0.18; // radians
}
