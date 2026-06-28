import 'package:uuid/uuid.dart';

import '../models/enums.dart';
import '../models/item_model.dart';
import '../models/swipe_model.dart';
import '../models/user_model.dart';

/// Generates demo content on first launch so the swipe/match flow is alive.
class SeedData {
  static const _uuid = Uuid();

  static String _img(String seed) =>
      'https://picsum.photos/seed/$seed/800/1000';

  /// The signed-in demo persona (your in-app swap identity).
  static const String meId = 'user_me';

  // Downtown Miami-ish anchor for realistic distances.
  static const double _baseLat = 25.7617;
  static const double _baseLng = -80.1918;

  static List<UserModel> users() {
    final now = DateTime.now();
    return [
      UserModel(
        id: meId,
        name: 'You',
        location: 'Miami, Florida',
        bio: 'Decluttering my closet — looking for cool swaps!',
        avatarUrl: _img('avatar-me'),
        createdAt: now,
      ),
      UserModel(
        id: 'user_amara',
        name: 'Amara',
        location: 'Wynwood, Miami',
        bio: 'Sneakerhead. Swap me something fresh.',
        avatarUrl: _img('avatar-amara'),
        createdAt: now,
      ),
      UserModel(
        id: 'user_kunle',
        name: 'Kunle',
        location: 'Brickell, Miami',
        bio: 'Books, gadgets and good vibes.',
        avatarUrl: _img('avatar-kunle'),
        createdAt: now,
      ),
      UserModel(
        id: 'user_zara',
        name: 'Zara',
        location: 'Little Havana, Miami',
        bio: 'Thrift queen vintage everything.',
        avatarUrl: _img('avatar-zara'),
        createdAt: now,
      ),
      UserModel(
        id: 'user_tobi',
        name: 'Tobi',
        location: 'South Beach, Miami',
        bio: 'Minimalist swapping up my home stuff.',
        avatarUrl: _img('avatar-tobi'),
        createdAt: now,
      ),
    ];
  }

  static List<ItemModel> items() {
    final now = DateTime.now();
    ItemModel make(
      String id,
      String owner,
      String title,
      String desc,
      ItemCategory cat,
      ItemCondition cond,
      List<String> seeds,
      double value, {
      double dLat = 0,
      double dLng = 0,
      Duration age = const Duration(days: 5),
    }) {
      return ItemModel(
        id: id,
        ownerId: owner,
        title: title,
        description: desc,
        category: cat,
        condition: cond,
        images: seeds.map(_img).toList(),
        estimatedValue: value,
        latitude: _baseLat + dLat,
        longitude: _baseLng + dLng,
        createdAt: now.subtract(age),
      );
    }

    return [
      // ----- My items -----
      make('item_my_shoe', meId, 'Nike Air Sneakers',
          'Barely worn white Nikes, size 42. Super clean.',
          ItemCategory.shoes, ItemCondition.likeNew, ['shoe1', 'shoe1b'], 120,
          age: const Duration(hours: 5)),
      make('item_my_bag', meId, 'Leather Tote Bag',
          'Genuine leather tote, tons of space. Light wear.',
          ItemCategory.bags, ItemCondition.good, ['bag1', 'bag1b'], 90,
          age: const Duration(days: 2)),
      make('item_my_bed', meId, 'Wooden Bed Frame',
          'Solid oak single bed frame. Pickup only.',
          ItemCategory.home, ItemCondition.good, ['bed1'], 200,
          age: const Duration(days: 6)),

      // ----- Amara -----
      make('item_amara_af1', 'user_amara', 'Nike Air Force 1 High',
          'Crisp white AF1 highs, lightly worn. A grail swap.',
          ItemCategory.shoes, ItemCondition.good, ['af1a', 'af1b', 'af1c'], 190,
          dLat: 0.012, dLng: 0.006, age: const Duration(hours: 2)),
      make('item_amara_shirt', 'user_amara', 'Vintage Denim Shirt',
          'Oversized 90s denim shirt. A vibe.',
          ItemCategory.clothing, ItemCondition.good, ['shirt1', 'shirt1b'], 60,
          dLat: 0.012, dLng: 0.006, age: const Duration(days: 1)),
      make('item_amara_watch', 'user_amara', 'Classic Wristwatch',
          'Silver analog watch, brand new battery.',
          ItemCategory.accessories, ItemCondition.likeNew, ['watch1'], 80,
          dLat: 0.012, dLng: 0.006, age: const Duration(days: 3)),

      // ----- Kunle -----
      make('item_kunle_headphones', 'user_kunle', 'Wireless Headphones',
          'Over-ear, noise cancelling. Great sound.',
          ItemCategory.electronics, ItemCondition.likeNew, ['head1'], 150,
          dLat: -0.018, dLng: 0.004, age: const Duration(hours: 20)),
      make('item_kunle_books', 'user_kunle', 'Box of Novels',
          '15 paperback novels, mixed genres.',
          ItemCategory.books, ItemCondition.good, ['books1'], 45,
          dLat: -0.018, dLng: 0.004, age: const Duration(days: 4)),

      // ----- Zara -----
      make('item_zara_jacket', 'user_zara', 'Vintage Leather Jacket',
          'Classic black biker jacket. Timeless.',
          ItemCategory.clothing, ItemCondition.good, ['jacket1', 'jacket1b'], 130,
          dLat: -0.006, dLng: -0.02, age: const Duration(hours: 9)),
      make('item_zara_heels', 'user_zara', 'Designer Heels',
          'Red block heels, worn twice. Size 39.',
          ItemCategory.shoes, ItemCondition.likeNew, ['heels1'], 95,
          dLat: -0.006, dLng: -0.02, age: const Duration(days: 2)),

      // ----- Tobi -----
      make('item_tobi_lamp', 'user_tobi', 'Modern Floor Lamp',
          'Minimalist standing lamp, warm light.',
          ItemCategory.home, ItemCondition.likeNew, ['lamp1'], 70,
          dLat: 0.03, dLng: 0.025, age: const Duration(days: 3)),
      make('item_tobi_backpack', 'user_tobi', 'Travel Backpack',
          '40L water-resistant backpack. Barely used.',
          ItemCategory.bags, ItemCondition.likeNew, ['pack1'], 85,
          dLat: 0.03, dLng: 0.025, age: const Duration(hours: 30)),
    ];
  }

  /// Pre-seeded incoming likes so "Likes You" is populated and the first match
  /// works instantly: each admirer has already liked one of YOUR items, so the
  /// moment you like any of their items back, it's a match.
  static List<SwipeModel> incomingLikes() {
    final now = DateTime.now();
    SwipeModel like(String swiper, String myItem) {
      return SwipeModel(
        id: _uuid.v4(),
        swiperUserId: swiper,
        targetUserId: meId,
        targetItemId: myItem,
        direction: SwipeDirection.like,
        createdAt: now.subtract(Duration(minutes: 30 + swiper.length)),
      );
    }

    return [
      // Amara already likes your sneakers.
      like('user_amara', 'item_my_shoe'),
      // Zara already likes your leather tote.
      like('user_zara', 'item_my_bag'),
      // Kunle already likes your bed frame.
      like('user_kunle', 'item_my_bed'),
    ];
  }
}
