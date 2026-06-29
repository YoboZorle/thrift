import 'package:uuid/uuid.dart';

import '../core/constants/app_config.dart';
import '../core/constants/app_constants.dart';
import '../models/enums.dart';
import '../models/item_model.dart';
import '../models/match_model.dart';
import '../models/message_model.dart';
import '../models/swipe_model.dart';
import '../models/user_model.dart';
import 'data_repository.dart';
import 'local_storage_service.dart';
import 'seed_data.dart';

/// In-memory cache backed by SharedPreferences. Single source of truth while
/// the backend is local. Every mutation persists immediately.
class LocalDataRepository implements DataRepository {
  LocalDataRepository(this._storage);

  final LocalStorageService _storage;
  static const _uuid = Uuid();

  final List<UserModel> _users = [];
  final List<ItemModel> _items = [];
  final List<SwipeModel> _swipes = [];
  final List<MatchModel> _matches = [];
  final List<MessageModel> _messages = [];

  /// Saved/bookmarked records: each is {'userId':..,'itemId':..}.
  final List<Map<String, String>> _saved = [];

  @override
  Future<void> init() async {
    final alreadySeeded = _storage.readBool(AppConstants.kSeeded);
    if (!alreadySeeded) {
      _users
        ..clear()
        ..addAll(SeedData.users());
      _items
        ..clear()
        ..addAll(SeedData.items());
      _swipes.clear();
      await _persistAll();
      await _storage.writeBool(AppConstants.kSeeded, true);
    } else {
      _loadFromStorage();
    }
  }

  void _loadFromStorage() {
    _users
      ..clear()
      ..addAll(_storage.readList(AppConstants.kUsers).map(UserModel.fromMap));
    _items
      ..clear()
      ..addAll(_storage.readList(AppConstants.kItems).map(ItemModel.fromMap));
    _swipes
      ..clear()
      ..addAll(_storage.readList(AppConstants.kSwipes).map(SwipeModel.fromMap));
    _matches
      ..clear()
      ..addAll(_storage.readList(AppConstants.kMatches).map(MatchModel.fromMap));
    _messages
      ..clear()
      ..addAll(
          _storage.readList(AppConstants.kMessages).map(MessageModel.fromMap));
    _saved
      ..clear()
      ..addAll(_storage.readList(AppConstants.kSaved).map(
          (m) => {'userId': '${m['userId']}', 'itemId': '${m['itemId']}'}));
  }

  Future<void> _persistAll() async {
    await _storage.writeList(
        AppConstants.kUsers, _users.map((e) => e.toMap()).toList());
    await _storage.writeList(
        AppConstants.kItems, _items.map((e) => e.toMap()).toList());
    await _storage.writeList(
        AppConstants.kSwipes, _swipes.map((e) => e.toMap()).toList());
    await _storage.writeList(
        AppConstants.kMatches, _matches.map((e) => e.toMap()).toList());
    await _storage.writeList(
        AppConstants.kMessages, _messages.map((e) => e.toMap()).toList());
  }

  // ----- Users -----
  @override
  Future<List<UserModel>> getUsers() async => List.unmodifiable(_users);

  @override
  Future<UserModel?> getUser(String id) async {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> upsertUser(UserModel user) async {
    final i = _users.indexWhere((u) => u.id == user.id);
    if (i >= 0) {
      _users[i] = user;
    } else {
      _users.add(user);
    }
    await _storage.writeList(
        AppConstants.kUsers, _users.map((e) => e.toMap()).toList());
  }

  // ----- Items -----
  @override
  Future<List<ItemModel>> getAllItems() async => List.unmodifiable(_items);

  @override
  Future<List<ItemModel>> getItemsByOwner(String ownerId) async =>
      _items.where((i) => i.ownerId == ownerId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<ItemModel?> getItem(String id) async {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addItem(ItemModel item) async {
    _items.add(item);
    await _generateAdmirers(item);
    await _storage.writeList(
        AppConstants.kItems, _items.map((e) => e.toMap()).toList());
  }

  /// When a user lists an item, a couple of *compatible* community members
  /// (same city/state, or sharing the item's category) like it. This is the
  /// location/interest/category basis for matching: liking any of their items
  /// back forms a match.
  Future<void> _generateAdmirers(ItemModel item) async {
    final compatible = _users.where((u) {
      if (u.id == item.ownerId) return false;
      final sameCity = u.city.isNotEmpty && u.city == item.city;
      final sameState = u.state.isNotEmpty && u.state == item.state;
      final sharesCategory =
          _items.any((i) => i.ownerId == u.id && i.category == item.category);
      return sameCity || sameState || sharesCategory;
    }).toList();

    // Always surface at least someone, so likes/matches/chats stay demoable —
    // compatible swappers first, then anyone else.
    final candidates = compatible.isNotEmpty
        ? compatible
        : _users.where((u) => u.id != item.ownerId).toList();

    // Prefer closest first (city > state > category).
    candidates.sort((a, b) {
      int score(UserModel u) =>
          (u.city == item.city ? 4 : 0) +
          (u.state == item.state ? 2 : 0) +
          (_items.any((i) => i.ownerId == u.id && i.category == item.category)
              ? 1
              : 0);
      return score(b).compareTo(score(a));
    });

    for (final admirer in candidates.take(2)) {
      final already = _swipes.any((s) =>
          s.swiperUserId == admirer.id && s.targetItemId == item.id);
      if (already) continue;
      _swipes.add(SwipeModel(
        id: _uuid.v4(),
        swiperUserId: admirer.id,
        targetUserId: item.ownerId,
        targetItemId: item.id,
        direction: SwipeDirection.like,
        createdAt: DateTime.now(),
      ));
    }
    await _storage.writeList(
        AppConstants.kSwipes, _swipes.map((e) => e.toMap()).toList());
  }

  @override
  Future<void> updateItem(ItemModel item) async {
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i >= 0) _items[i] = item;
    await _storage.writeList(
        AppConstants.kItems, _items.map((e) => e.toMap()).toList());
  }

  @override
  Future<void> deleteItem(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _storage.writeList(
        AppConstants.kItems, _items.map((e) => e.toMap()).toList());
  }

  UserModel? _userById(String id) {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// Compatibility signal used for ranking + admirer generation: same city,
  /// same state, or a shared item-category interest.
  int _affinity(ItemModel item, UserModel? me, Set<ItemCategory> myCategories) {
    var score = 0;
    if (me != null) {
      if (item.city.isNotEmpty && item.city == me.city) score += 4;
      if (item.state.isNotEmpty && item.state == me.state) score += 2;
    }
    if (myCategories.contains(item.category)) score += 1;
    return score;
  }

  // ----- Expiry (48h listing window; 5 min in test) -----

  bool _isExpired(DateTime createdAt) =>
      DateTime.now().difference(createdAt) > AppConfig.listingWindow;

  bool _likeAlive(SwipeModel s) => !_isExpired(s.createdAt);

  /// Ids of items locked into a match (these are taken / off the deck).
  Set<String> _matchedItemIds() {
    final ids = <String>{};
    for (final m in _matches) {
      ids
        ..add(m.itemAId)
        ..add(m.itemBId);
    }
    return ids;
  }

  @override
  Future<List<ItemModel>> getSwipeDeck({
    required String currentUserId,
  }) async {
    final swipedItemIds = _swipes
        .where((s) => s.swiperUserId == currentUserId)
        .map((s) => s.targetItemId)
        .toSet();

    final me = _userById(currentUserId);
    final myCategories = _items
        .where((i) => i.ownerId == currentUserId)
        .map((i) => i.category)
        .toSet();
    final matchedIds = _matchedItemIds();

    final deck = _items
        .where((i) =>
            i.ownerId != currentUserId &&
            i.isActive &&
            !swipedItemIds.contains(i.id) &&
            // Taken (already matched) or past the listing window -> off the deck.
            !matchedIds.contains(i.id) &&
            !_isExpired(i.createdAt))
        .toList();

    // Rank by location + interest affinity, then recency.
    deck.sort((a, b) {
      final sa = _affinity(a, me, myCategories);
      final sb = _affinity(b, me, myCategories);
      if (sa != sb) return sb.compareTo(sa);
      return b.createdAt.compareTo(a.createdAt);
    });
    return deck;
  }

  // ----- Swipes & Matches -----
  @override
  Future<List<SwipeModel>> getSwipes() async => List.unmodifiable(_swipes);

  @override
  Future<void> addSwipe(SwipeModel swipe) async {
    _swipes.add(swipe);
    await _storage.writeList(
        AppConstants.kSwipes, _swipes.map((e) => e.toMap()).toList());
  }

  @override
  Future<MatchModel?> recordSwipeAndCheckMatch(SwipeModel swipe) async {
    _swipes.add(swipe);

    MatchModel? match;
    if (swipe.direction == SwipeDirection.like) {
      final me = swipe.swiperUserId;
      final them = swipe.targetUserId;

      // Reciprocal interest at the USER level: have they liked ANY item of
      // mine — AND is that like still within the 48h window (not expired)?
      SwipeModel? theirLike;
      for (final s in _swipes) {
        if (s.direction == SwipeDirection.like &&
            s.swiperUserId == them &&
            s.targetUserId == me &&
            _likeAlive(s)) {
          theirLike = s;
          break;
        }
      }

      // Only one match per pair of users.
      final alreadyMatched = _matches
          .any((m) => m.involves(me) && m.involves(them));

      if (theirLike != null && !alreadyMatched) {
        match = MatchModel(
          id: _uuid.v4(),
          // itemA belongs to userA (me): the item of mine THEY wanted.
          userAId: me,
          itemAId: theirLike.targetItemId,
          // itemB belongs to userB (them): the item of theirs I just liked.
          userBId: them,
          itemBId: swipe.targetItemId,
          createdAt: DateTime.now(),
          lastActivity: DateTime.now(),
        );
        _matches.add(match);
        _seedOpeningMessage(match);
      }
    }

    await _storage.writeList(
        AppConstants.kSwipes, _swipes.map((e) => e.toMap()).toList());
    await _storage.writeList(
        AppConstants.kMatches, _matches.map((e) => e.toMap()).toList());
    await _storage.writeList(
        AppConstants.kMessages, _messages.map((e) => e.toMap()).toList());
    return match;
  }

  /// On a new match, drop ONE neutral guidance note into the thread (authored
  /// by the system, so it reads identically for both users) with a brief,
  /// safety-minded intro. It shows before anyone types, so both people start
  /// on the same note.
  void _seedOpeningMessage(MatchModel match) {
    String titleOf(String id) {
      for (final i in _items) {
        if (i.id == id) return i.title;
      }
      return 'an item';
    }

    final text =
        '🎉 It\'s a match! You\'re here to swap ${titleOf(match.itemAId)} ⇄ '
        '${titleOf(match.itemBId)}. Quick tips: meet in a public, comfortable '
        'place, inspect items before swapping, make sure your item matches its '
        'photos, and use a courier for delivery where you can. Sort out the '
        'details below 👇';

    _messages.add(MessageModel(
      id: _uuid.v4(),
      matchId: match.id,
      senderId: AppConstants.kSystemSenderId,
      text: text,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<List<MatchModel>> getMatches(String userId) async {
    final list = _matches.where((m) => m.involves(userId)).toList();
    list.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return list;
  }

  @override
  Future<void> markMatchSeen(String matchId) async {
    final i = _matches.indexWhere((m) => m.id == matchId);
    if (i >= 0) {
      _matches[i] = _matches[i].copyWith(seen: true);
      await _storage.writeList(
          AppConstants.kMatches, _matches.map((e) => e.toMap()).toList());
    }
  }

  @override
  Future<void> touchMatch(String matchId) async {
    final i = _matches.indexWhere((m) => m.id == matchId);
    if (i >= 0) {
      _matches[i] = _matches[i].copyWith(lastActivity: DateTime.now());
      await _storage.writeList(
          AppConstants.kMatches, _matches.map((e) => e.toMap()).toList());
    }
  }

  @override
  Future<List<SwipeModel>> getPendingLikesReceived(String userId) async {
    // Latest like per admirer that targets one of my items (and isn't expired)...
    final byAdmirer = <String, SwipeModel>{};
    for (final s in _swipes) {
      if (s.targetUserId != userId ||
          s.direction != SwipeDirection.like ||
          s.swiperUserId == userId ||
          !_likeAlive(s)) {
        continue;
      }
      final existing = byAdmirer[s.swiperUserId];
      if (existing == null || s.createdAt.isAfter(existing.createdAt)) {
        byAdmirer[s.swiperUserId] = s;
      }
    }

    bool isResolved(String admirerId) {
      // Already matched with them, or I've already acted on one of their items.
      final matched =
          _matches.any((m) => m.involves(userId) && m.involves(admirerId));
      final responded = _swipes
          .any((s) => s.swiperUserId == userId && s.targetUserId == admirerId);
      return matched || responded;
    }

    final pending = byAdmirer.entries
        .where((e) => !isResolved(e.key))
        .map((e) => e.value)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return pending;
  }

  // ----- Messages -----
  @override
  Future<void> deleteSwipe(String swipeId) async {
    _swipes.removeWhere((s) => s.id == swipeId);
    await _storage.writeList(
        AppConstants.kSwipes, _swipes.map((e) => e.toMap()).toList());
  }

  @override
  Future<void> deleteMatch(String matchId) async {
    _matches.removeWhere((m) => m.id == matchId);
    _messages.removeWhere((m) => m.matchId == matchId);
    await _storage.writeList(
        AppConstants.kMatches, _matches.map((e) => e.toMap()).toList());
    await _storage.writeList(
        AppConstants.kMessages, _messages.map((e) => e.toMap()).toList());
  }

  @override
  Future<List<String>> getSavedItemIds(String userId) async => _saved
      .where((r) => r['userId'] == userId)
      .map((r) => r['itemId']!)
      .toList();

  @override
  Future<bool> toggleSaved(String userId, String itemId) async {
    final idx = _saved
        .indexWhere((r) => r['userId'] == userId && r['itemId'] == itemId);
    final nowSaved = idx < 0;
    if (nowSaved) {
      _saved.add({'userId': userId, 'itemId': itemId});
    } else {
      _saved.removeAt(idx);
    }
    await _storage.writeList(
        AppConstants.kSaved, _saved.map((e) => Map<String, dynamic>.from(e)).toList());
    return nowSaved;
  }

  @override
  Future<List<MessageModel>> getMessages(String matchId) async {
    final list = _messages.where((m) => m.matchId == matchId).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    _messages.add(message);
    await _storage.writeList(
        AppConstants.kMessages, _messages.map((e) => e.toMap()).toList());
    await touchMatch(message.matchId);
  }

  @override
  Future<void> resetAll() async {
    await _storage.clearAll();
    _users.clear();
    _items.clear();
    _swipes.clear();
    _matches.clear();
    _messages.clear();
    _saved.clear();
    await init();
  }
}
