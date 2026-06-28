import 'package:uuid/uuid.dart';

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
      _swipes
        ..clear()
        ..addAll(SeedData.incomingLikes());
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
    await _storage.writeList(
        AppConstants.kItems, _items.map((e) => e.toMap()).toList());
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

  @override
  Future<List<ItemModel>> getSwipeDeck({
    required String currentUserId,
  }) async {
    final swipedItemIds = _swipes
        .where((s) => s.swiperUserId == currentUserId)
        .map((s) => s.targetItemId)
        .toSet();

    final deck = _items
        .where((i) =>
            i.ownerId != currentUserId &&
            i.isActive &&
            !swipedItemIds.contains(i.id))
        .toList();
    deck.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

      // Reciprocal interest at the USER level: have they liked ANY item of mine?
      SwipeModel? theirLike;
      for (final s in _swipes) {
        if (s.direction == SwipeDirection.like &&
            s.swiperUserId == them &&
            s.targetUserId == me) {
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
      }
    }

    await _storage.writeList(
        AppConstants.kSwipes, _swipes.map((e) => e.toMap()).toList());
    await _storage.writeList(
        AppConstants.kMatches, _matches.map((e) => e.toMap()).toList());
    return match;
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
    // Latest like per admirer that targets one of my items...
    final byAdmirer = <String, SwipeModel>{};
    for (final s in _swipes) {
      if (s.targetUserId != userId ||
          s.direction != SwipeDirection.like ||
          s.swiperUserId == userId) {
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
