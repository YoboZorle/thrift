import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/enums.dart';
import '../models/item_model.dart';
import '../models/match_model.dart';
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
class SwipeMatchProvider extends ChangeNotifier {
  SwipeMatchProvider(this._repo, this._notifications);

  final DataRepository _repo;
  final NotificationService _notifications;
  static const _uuid = Uuid();

  ItemModel? _activeItem;
  List<ItemModel> _deck = [];
  List<MatchModel> _matches = [];
  List<SwipeModel> _likesReceived = [];
  bool _deckLoading = false;

  final Set<String> _savedIds = {};
  _LastAction? _lastAction;

  ItemModel? get activeItem => _activeItem;
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

  Future<void> setActiveItem(String userId, ItemModel item) async {
    _activeItem = item;
    _lastAction = null;
    await loadDeck(userId);
  }

  Future<void> loadDeck(String userId) async {
    if (_activeItem == null) {
      _deck = [];
      notifyListeners();
      return;
    }
    _deckLoading = true;
    notifyListeners();
    _deck = await _repo.getSwipeDeck(
      currentUserId: userId,
      activeItemId: _activeItem!.id,
    );
    _deckLoading = false;
    notifyListeners();
  }

  /// Swipe the [target] item while offering [_activeItem]. Returns a match if
  /// one was formed. The deck list is NOT mutated here — the card stack tracks
  /// progression, which keeps undo clean and avoids skipping cards.
  Future<MatchModel?> swipe({
    required String userId,
    required ItemModel target,
    required SwipeDirection direction,
  }) async {
    if (_activeItem == null) return null;

    final swipeRecord = SwipeModel(
      id: _uuid.v4(),
      swiperUserId: userId,
      swiperItemId: _activeItem!.id,
      targetUserId: target.ownerId,
      targetItemId: target.id,
      direction: direction,
      createdAt: DateTime.now(),
    );

    final match = await _repo.recordSwipeAndCheckMatch(swipeRecord);
    _lastAction = _LastAction(target, swipeRecord.id, match?.id);

    if (match != null) {
      await refreshMatches(userId);
      await _notifyMatch(match, userId);
    }
    notifyListeners();
    return match;
  }

  /// Undo the most recent swipe (re-shown by the card stack). Returns the item
  /// that was un-swiped, if any.
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

  /// Responding to an incoming like from the "Likes You" inbox.
  Future<MatchModel?> respondToLike({
    required String userId,
    required SwipeModel incoming,
    required SwipeDirection direction,
  }) async {
    final swipeRecord = SwipeModel(
      id: _uuid.v4(),
      swiperUserId: userId,
      swiperItemId: incoming.targetItemId, // my item they liked
      targetUserId: incoming.swiperUserId,
      targetItemId: incoming.swiperItemId, // their item
      direction: direction,
      createdAt: DateTime.now(),
    );

    final match = await _repo.recordSwipeAndCheckMatch(swipeRecord);
    await loadLikesReceived(userId);
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
    _matches = await _repo.getMatches(userId);
    notifyListeners();
  }

  Future<void> loadLikesReceived(String userId) async {
    _likesReceived = await _repo.getPendingLikesReceived(userId);
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
    ]);
    if (_activeItem != null) await loadDeck(userId);
  }
}
