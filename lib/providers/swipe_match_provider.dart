import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/enums.dart';
import '../models/item_model.dart';
import '../models/match_model.dart';
import '../models/message_model.dart';
import '../models/swipe_model.dart';
import '../models/user_model.dart';
import '../services/data_repository.dart';
import '../services/notification_service.dart';

class _LastAction {
  final ItemModel item;
  final String swipeId;
  final String? matchId;
  const _LastAction(this.item, this.swipeId, this.matchId);
}

/// Owns the swipe deck, matches and "likes you" inbox — they are tightly
/// coupled through the matching logic, so they live together.
///
/// Matching is user-level: liking any of another person's items expresses
/// interest, and a match forms once both people have liked something of the
/// other's. The exact items to exchange are arranged in chat afterwards.
class SwipeMatchProvider extends ChangeNotifier {
  SwipeMatchProvider(this._repo, this._notifications);

  final DataRepository _repo;
  final NotificationService _notifications;
  static const _uuid = Uuid();

  List<ItemModel> _deck = [];
  List<MatchModel> _matches = [];
  List<SwipeModel> _likesReceived = [];
  bool _deckLoading = false;

  final Set<String> _savedIds = {};
  _LastAction? _lastAction;

  List<ItemModel> get deck => _deck;
  List<MatchModel> get matches => _matches;
  List<SwipeModel> get likesReceived => _likesReceived;
  bool get deckLoading => _deckLoading;
  bool get canUndo => _lastAction != null;

  int get matchCount => _matches.length;
  int get likesYouCount => _likesReceived.length;
  int get unseenMatchCount => _matches.where((m) => !m.seen).length;

  // ---- Lookup helpers shared with the UI ----
  Future<ItemModel?> item(String id) => _repo.getItem(id);
  Future<UserModel?> user(String id) => _repo.getUser(id);

  /// Most recent message in a thread (for the chat-list preview), or null.
  Future<MessageModel?> lastMessage(String matchId) async {
    final msgs = await _repo.getMessages(matchId);
    return msgs.isEmpty ? null : msgs.last;
  }
  Future<List<ItemModel>> itemsOf(String userId) =>
      _repo.getItemsByOwner(userId);

  /// Full activity history for the current user: their swipes + their matches.
  Future<List<SwipeModel>> mySwipes(String userId) async {
    final all = await _repo.getSwipes();
    final mine = all.where((s) => s.swiperUserId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  Future<List<MatchModel>> matchesFor(String userId) =>
      _repo.getMatches(userId);

  Future<List<ItemModel>> allItems() => _repo.getAllItems();
  Future<List<UserModel>> allUsers() => _repo.getUsers();

  Future<void> loadDeck(String userId) async {
    _deckLoading = true;
    notifyListeners();
    _deck = await _repo.getSwipeDeck(currentUserId: userId);
    _deckLoading = false;
    notifyListeners();
  }

  /// Like or pass an item. Returns a match if liking it completed a reciprocal
  /// pair. The deck list is NOT mutated here — the card stack tracks
  /// progression, which keeps undo clean and avoids skipping cards.
  Future<MatchModel?> swipe({
    required String userId,
    required ItemModel target,
    required SwipeDirection direction,
  }) async {
    final swipeRecord = SwipeModel(
      id: _uuid.v4(),
      swiperUserId: userId,
      targetUserId: target.ownerId,
      targetItemId: target.id,
      direction: direction,
      createdAt: DateTime.now(),
    );

    final match = await _repo.recordSwipeAndCheckMatch(swipeRecord);
    _lastAction = _LastAction(target, swipeRecord.id, match?.id);

    if (match != null) {
      await refreshMatches(userId);
      await loadLikesReceived(userId);
      await _notifyMatch(match, userId);
    }
    notifyListeners();
    return match;
  }

  /// Undo the most recent swipe (re-shown by the card stack).
  Future<ItemModel?> undoLast({required String userId}) async {
    final action = _lastAction;
    if (action == null) return null;
    await _repo.deleteSwipe(action.swipeId);
    if (action.matchId != null) {
      await _repo.deleteMatch(action.matchId!);
    }
    _lastAction = null;
    await refreshMatches(userId);
    await loadLikesReceived(userId);
    notifyListeners();
    return action.item;
  }

  /// Respond to an incoming like from the "Likes You" inbox. Liking back likes
  /// the admirer's most recent active item, which (since they already like
  /// yours) forms the match. Passing dismisses them from the inbox.
  Future<MatchModel?> respondToLike({
    required String userId,
    required SwipeModel incoming,
    required SwipeDirection direction,
  }) async {
    final theirItems = await _repo.getItemsByOwner(incoming.swiperUserId);
    ItemModel? target;
    for (final i in theirItems) {
      if (i.isActive) {
        target = i;
        break;
      }
    }
    if (target == null) {
      // Nothing to act on; just refresh the inbox.
      await loadLikesReceived(userId);
      return null;
    }

    final swipeRecord = SwipeModel(
      id: _uuid.v4(),
      swiperUserId: userId,
      targetUserId: incoming.swiperUserId,
      targetItemId: target.id,
      direction: direction,
      createdAt: DateTime.now(),
    );

    final match = await _repo.recordSwipeAndCheckMatch(swipeRecord);
    await loadLikesReceived(userId);
    await loadDeck(userId);
    if (match != null) {
      await refreshMatches(userId);
      await _notifyMatch(match, userId);
    }
    notifyListeners();
    return match;
  }

  Future<void> _notifyMatch(MatchModel match, String userId) async {
    final other = await _repo.getUser(match.otherUserId(userId));
    await _notifications.showMatch(other?.name ?? 'Someone');
  }

  // ---- Saved / bookmarked ----
  Future<void> loadSaved(String userId) async {
    final ids = await _repo.getSavedItemIds(userId);
    _savedIds
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  bool isSaved(String itemId) => _savedIds.contains(itemId);

  Future<bool> toggleSave(String userId, String itemId) async {
    final nowSaved = await _repo.toggleSaved(userId, itemId);
    if (nowSaved) {
      _savedIds.add(itemId);
    } else {
      _savedIds.remove(itemId);
    }
    notifyListeners();
    return nowSaved;
  }

  Future<List<ItemModel>> savedItems(String userId) async {
    final ids = await _repo.getSavedItemIds(userId);
    final out = <ItemModel>[];
    for (final id in ids) {
      final it = await _repo.getItem(id);
      if (it != null) out.add(it);
    }
    return out;
  }

  Future<void> refreshMatches(String userId) async {
    final list = await _repo.getMatches(userId);
    // Recents at the top, with unread (unseen) matches surfaced first so new
    // chats and unanswered ones lead the list.
    list.sort((a, b) {
      if (a.seen != b.seen) return a.seen ? 1 : -1;
      return b.lastActivity.compareTo(a.lastActivity);
    });
    _matches = list;
    notifyListeners();
  }

  Future<void> loadLikesReceived(String userId) async {
    final list = await _repo.getPendingLikesReceived(userId);
    // Most recent admirers at the top.
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _likesReceived = list;
    notifyListeners();
  }

  Future<void> markSeen(String matchId, String userId) async {
    await _repo.markMatchSeen(matchId);
    await refreshMatches(userId);
  }

  Future<void> refreshAll(String userId) async {
    await Future.wait([
      refreshMatches(userId),
      loadLikesReceived(userId),
      loadSaved(userId),
      loadDeck(userId),
    ]);
  }
}
