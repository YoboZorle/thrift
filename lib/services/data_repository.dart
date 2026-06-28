import '../models/item_model.dart';
import '../models/match_model.dart';
import '../models/message_model.dart';
import '../models/swipe_model.dart';
import '../models/user_model.dart';

/// Abstract contract for all data access. The app talks ONLY to this interface,
/// which means the local implementation can be swapped for a Firebase one
/// without touching providers or UI.
abstract class DataRepository {
  Future<void> init();

  // ----- Users -----
  Future<List<UserModel>> getUsers();
  Future<UserModel?> getUser(String id);
  Future<void> upsertUser(UserModel user);

  // ----- Items -----
  Future<List<ItemModel>> getAllItems();
  Future<List<ItemModel>> getItemsByOwner(String ownerId);
  Future<ItemModel?> getItem(String id);
  Future<void> addItem(ItemModel item);
  Future<void> updateItem(ItemModel item);
  Future<void> deleteItem(String id);

  /// Items that [currentUserId] can swipe on while offering [activeItemId]:
  /// excludes own items and ones already swiped with that active item.
  Future<List<ItemModel>> getSwipeDeck({
    required String currentUserId,
    required String activeItemId,
  });

  // ----- Swipes & Matches -----
  Future<List<SwipeModel>> getSwipes();
  Future<void> addSwipe(SwipeModel swipe);

  /// Records a swipe and returns a [MatchModel] if it created a match.
  Future<MatchModel?> recordSwipeAndCheckMatch(SwipeModel swipe);

  Future<List<MatchModel>> getMatches(String userId);
  Future<void> markMatchSeen(String matchId);
  Future<void> touchMatch(String matchId);

  /// Incoming likes on the current user's items that haven't been answered yet.
  Future<List<SwipeModel>> getPendingLikesReceived(String userId);

  /// Undo support: remove a swipe (and optionally the match it created).
  Future<void> deleteSwipe(String swipeId);
  Future<void> deleteMatch(String matchId);

  // ----- Saved / bookmarked items -----
  Future<List<String>> getSavedItemIds(String userId);

  /// Toggles saved state and returns the new state (true = now saved).
  Future<bool> toggleSaved(String userId, String itemId);

  // ----- Messages -----
  Future<List<MessageModel>> getMessages(String matchId);
  Future<void> sendMessage(MessageModel message);

  Future<void> resetAll();
}
