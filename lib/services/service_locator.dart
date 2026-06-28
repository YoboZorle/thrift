import 'auth/auth_service.dart';
import 'auth/local_auth_service.dart';
import 'data_repository.dart';
import 'local_data_repository.dart';
import 'local_storage_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'permission_service.dart';

/// Builds and holds the app's services. Everything is fully on-device:
/// data + auth sessions persist in local storage, and the only "cloud" feature
/// is omitted by design — no backend is wired up yet. The [AuthService]
/// abstraction is kept so a real backend can be slotted in later without
/// touching the rest of the app.
class ServiceLocator {
  ServiceLocator._();

  static late LocalStorageService storage;
  static late DataRepository repository;
  static late AuthService authService;
  static late PermissionService permissionService;
  static late NotificationService notificationService;
  static late LocationService locationService;

  static Future<void> setup() async {
    storage = await LocalStorageService.create();

    // ---- Data layer: local, persistent (shared_preferences). ----
    final repo = LocalDataRepository(storage);
    await repo.init();
    repository = repo;

    // ---- Auth: local, persistent sessions (no backend). ----
    final auth = LocalAuthService(storage);
    await auth.init();
    authService = auth;

    // ---- Device services. ----
    permissionService = PermissionService();
    locationService = LocationService();
    notificationService = NotificationService();
    await notificationService.init();
  }
}
