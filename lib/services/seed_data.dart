import '../models/enums.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';

/// Seeds a community of other swappers + their items on first launch, so a
/// freshly signed-in user has people and goods to discover and match with.
///
/// The signed-in user is NOT seeded — they get a unique account tied to their
/// auth identity, with their own items, matches and chats. Every seeded record
/// here is unique (unique ids + unique, product-relevant images).
class SeedData {
  static const double _baseLat = 25.7617; // Miami-ish anchor
  static const double _baseLng = -80.1918;

  /// Product-relevant photo (keyworded, deterministic via `lock`) — not random.
  static String _photo(String keywords, int lock) =>
      'https://loremflickr.com/800/1000/$keywords?lock=$lock';

  /// Real-photo avatar, deterministic by index.
  static String _avatar(int n) => 'https://i.pravatar.cc/400?img=$n';

  static List<UserModel> users() {
    final now = DateTime.now();
    UserModel u(
      String id,
      String name,
      String city,
      String state,
      String bio,
      String gender,
      int age,
      int avatar,
    ) {
      return UserModel(
        id: id,
        name: name,
        location: '$city, $state',
        city: city,
        state: state,
        bio: bio,
        gender: gender,
        dob: DateTime(now.year - age, 4, 12),
        avatarUrl: _avatar(avatar),
        createdAt: now,
      );
    }

    return [
      u('user_amara', 'Amara', 'Miami', 'Florida',
          'Sneakerhead. Swap me something fresh.', 'Female', 27, 5),
      u('user_kunle', 'Kunle', 'Miami', 'Florida',
          'Books, gadgets and good vibes.', 'Male', 31, 12),
      u('user_zara', 'Zara', 'Orlando', 'Florida',
          'Thrift queen — vintage everything.', 'Female', 24, 9),
      u('user_tobi', 'Tobi', 'Miami', 'Florida',
          'Minimalist swapping up my home stuff.', 'Male', 29, 14),
      u('user_lola', 'Lola', 'Atlanta', 'Georgia',
          'Closet refresh in progress. Open to trades!', 'Female', 26, 16),
      u('user_diego', 'Diego', 'Miami', 'Florida',
          'Sports gear and tech. Let\'s deal.', 'Male', 33, 33),
      u('user_mei', 'Mei', 'Tampa', 'Florida',
          'Books, home & little treasures.', 'Female', 28, 20),
      u('user_sam', 'Sam', 'Austin', 'Texas',
          'Outdoors and everyday carry swaps.', 'Male', 30, 52),
      u('user_priya', 'Priya', 'Miami', 'Florida',
          'Accessories & smart-casual pieces.', 'Female', 25, 25),
      u('user_marcus', 'Marcus', 'Jacksonville', 'Florida',
          'Tech tinkerer and runner.', 'Male', 34, 60),
      u('user_nina', 'Nina', 'Atlanta', 'Georgia',
          'Cozy home goods and totes.', 'Female', 27, 45),
      u('user_omar', 'Omar', 'Houston', 'Texas',
          'Books, board games, good trades.', 'Male', 32, 13),
    ];
  }

  static List<ItemModel> items() {
    final now = DateTime.now();

    // Owner -> (city, state, dLat, dLng) so distances + location match line up.
    const place = <String, List<dynamic>>{
      'user_amara': ['Miami', 'Florida', 0.012, 0.006],
      'user_kunle': ['Miami', 'Florida', -0.018, 0.004],
      'user_zara': ['Orlando', 'Florida', 1.6, 0.9],
      'user_tobi': ['Miami', 'Florida', 0.03, 0.025],
      'user_lola': ['Atlanta', 'Georgia', 6.0, 4.2],
      'user_diego': ['Miami', 'Florida', -0.01, 0.02],
      'user_mei': ['Tampa', 'Florida', 1.1, -1.3],
      'user_sam': ['Austin', 'Texas', 4.2, -17.5],
      'user_priya': ['Miami', 'Florida', -0.02, -0.01],
      'user_marcus': ['Jacksonville', 'Florida', 3.0, 0.6],
      'user_nina': ['Atlanta', 'Georgia', 6.1, 4.1],
      'user_omar': ['Houston', 'Texas', 4.0, -15.0],
    };

    var lockSeed = 100; // unique, deterministic image lock per photo

    ItemModel make(
      String id,
      String owner,
      String title,
      String desc,
      ItemCategory cat,
      ItemCondition cond,
      String keywords,
      int photoCount,
      double value, {
      Duration age = const Duration(days: 5),
    }) {
      final p = place[owner]!;
      final images = List.generate(photoCount, (_) => _photo(keywords, lockSeed++));
      return ItemModel(
        id: id,
        ownerId: owner,
        title: title,
        description: desc,
        category: cat,
        condition: cond,
        images: images,
        estimatedValue: value,
        latitude: _baseLat + (p[2] as double),
        longitude: _baseLng + (p[3] as double),
        city: p[0] as String,
        state: p[1] as String,
        // Test window is short (5 min), so compress each item's relative age
        // into seconds — older listings have less time left, but all start
        // live. (With the production 48h window, use real ages instead.)
        createdAt: now
            .subtract(Duration(seconds: age.inHours.clamp(0, 240).toInt())),
      );
    }

    return [
      // ----- Amara (Miami) -----
      make('item_amara_af1', 'user_amara', 'Nike Air Force 1 High',
          'Crisp white AF1 highs, lightly worn. A grail swap.',
          ItemCategory.shoes, ItemCondition.good, 'sneakers', 3, 190,
          age: const Duration(hours: 2)),
      make('item_amara_shirt', 'user_amara', 'Vintage Denim Shirt',
          'Oversized 90s denim shirt. A vibe.',
          ItemCategory.clothing, ItemCondition.good, 'denim,shirt', 2, 60,
          age: const Duration(days: 1)),
      make('item_amara_watch', 'user_amara', 'Classic Wristwatch',
          'Silver analog watch, brand new battery.',
          ItemCategory.accessories, ItemCondition.likeNew, 'wristwatch', 2, 80,
          age: const Duration(days: 3)),

      // ----- Kunle (Miami) -----
      make('item_kunle_headphones', 'user_kunle', 'Wireless Headphones',
          'Over-ear, noise cancelling. Great sound.',
          ItemCategory.electronics, ItemCondition.likeNew, 'headphones', 2, 150,
          age: const Duration(hours: 20)),
      make('item_kunle_books', 'user_kunle', 'Box of Novels',
          '15 paperback novels, mixed genres.',
          ItemCategory.books, ItemCondition.good, 'books', 2, 45,
          age: const Duration(days: 4)),

      // ----- Zara (Orlando) -----
      make('item_zara_jacket', 'user_zara', 'Vintage Leather Jacket',
          'Classic black biker jacket. Timeless.',
          ItemCategory.clothing, ItemCondition.good, 'leather,jacket', 2, 130,
          age: const Duration(hours: 9)),
      make('item_zara_heels', 'user_zara', 'Designer Heels',
          'Red block heels, worn twice. Size 39.',
          ItemCategory.shoes, ItemCondition.likeNew, 'high,heels', 2, 95,
          age: const Duration(days: 2)),

      // ----- Tobi (Miami) -----
      make('item_tobi_lamp', 'user_tobi', 'Modern Floor Lamp',
          'Minimalist standing lamp, warm light.',
          ItemCategory.home, ItemCondition.likeNew, 'floor,lamp', 2, 70,
          age: const Duration(days: 3)),
      make('item_tobi_backpack', 'user_tobi', 'Travel Backpack',
          '40L water-resistant backpack. Barely used.',
          ItemCategory.bags, ItemCondition.likeNew, 'backpack', 2, 85,
          age: const Duration(hours: 30)),

      // ----- Lola (Atlanta) -----
      make('item_lola_dress', 'user_lola', 'Floral Summer Dress',
          'Flowy floral midi dress, size M. Worn once.',
          ItemCategory.clothing, ItemCondition.likeNew, 'floral,dress', 2, 55,
          age: const Duration(hours: 14)),
      make('item_lola_camera', 'user_lola', 'Instant Film Camera',
          'Retro instant camera + a pack of film.',
          ItemCategory.electronics, ItemCondition.good, 'instant,camera', 2,
          110,
          age: const Duration(days: 2)),

      // ----- Diego (Miami) -----
      make('item_diego_basketball', 'user_diego', 'Official Basketball',
          'Indoor/outdoor leather basketball, great grip.',
          ItemCategory.other, ItemCondition.good, 'basketball', 2, 35,
          age: const Duration(hours: 6)),
      make('item_diego_speaker', 'user_diego', 'Bluetooth Speaker',
          'Portable waterproof speaker. Punchy bass.',
          ItemCategory.electronics, ItemCondition.likeNew, 'bluetooth,speaker',
          2, 90,
          age: const Duration(days: 1)),
      make('item_diego_sunglasses', 'user_diego', 'Polarized Sunglasses',
          'Matte black frames, polarized lenses.',
          ItemCategory.accessories, ItemCondition.good, 'sunglasses', 2, 50,
          age: const Duration(days: 5)),

      // ----- Mei (Tampa) -----
      make('item_mei_cookbook', 'user_mei', 'Illustrated Cookbook',
          'Hardcover cookbook, 200+ recipes. Like new.',
          ItemCategory.books, ItemCondition.likeNew, 'cookbook', 2, 30,
          age: const Duration(hours: 40)),
      make('item_mei_vase', 'user_mei', 'Ceramic Vase',
          'Handmade ceramic vase, soft matte glaze.',
          ItemCategory.home, ItemCondition.likeNew, 'ceramic,vase', 2, 40,
          age: const Duration(days: 3)),
      make('item_mei_scarf', 'user_mei', 'Silk Scarf',
          'Patterned silk scarf, barely used.',
          ItemCategory.accessories, ItemCondition.good, 'silk,scarf', 2, 28,
          age: const Duration(days: 6)),

      // ----- Sam (Austin) -----
      make('item_sam_boots', 'user_sam', 'Hiking Boots',
          'Waterproof hiking boots, size 44. Solid tread.',
          ItemCategory.shoes, ItemCondition.good, 'hiking,boots', 2, 120,
          age: const Duration(hours: 18)),
      make('item_sam_duffel', 'user_sam', 'Canvas Duffel Bag',
          'Rugged canvas weekender duffel. Tons of room.',
          ItemCategory.bags, ItemCondition.good, 'duffel,bag', 2, 65,
          age: const Duration(days: 2)),
      make('item_sam_guitar', 'user_sam', 'Acoustic Guitar',
          'Full-size acoustic, warm tone. Small ding on back.',
          ItemCategory.other, ItemCondition.good, 'acoustic,guitar', 2, 160,
          age: const Duration(days: 4)),

      // ----- Priya (Miami) -----
      make('item_priya_earrings', 'user_priya', 'Gold Hoop Earrings',
          '14k-plated hoops, never worn. Comes boxed.',
          ItemCategory.accessories, ItemCondition.likeNew, 'gold,earrings', 2,
          45,
          age: const Duration(hours: 7)),
      make('item_priya_blazer', 'user_priya', 'Linen Blazer',
          'Beige linen blazer, tailored fit. Size S.',
          ItemCategory.clothing, ItemCondition.good, 'linen,blazer', 2, 70,
          age: const Duration(days: 1)),

      // ----- Marcus (Jacksonville) -----
      make('item_marcus_keyboard', 'user_marcus', 'Mechanical Keyboard',
          'Hot-swappable mechanical keyboard, tactile switches.',
          ItemCategory.electronics, ItemCondition.likeNew, 'mechanical,keyboard',
          2, 100,
          age: const Duration(hours: 12)),
      make('item_marcus_shoes', 'user_marcus', 'Running Shoes',
          'Lightweight running shoes, size 43. ~50 miles.',
          ItemCategory.shoes, ItemCondition.good, 'running,shoes', 2, 75,
          age: const Duration(days: 2)),

      // ----- Nina (Atlanta) -----
      make('item_nina_pillows', 'user_nina', 'Throw Pillow Set',
          'Set of 2 boucle throw pillows, neutral tone.',
          ItemCategory.home, ItemCondition.likeNew, 'throw,pillow', 2, 40,
          age: const Duration(hours: 22)),
      make('item_nina_tote', 'user_nina', 'Woven Tote Bag',
          'Roomy woven tote, great for markets.',
          ItemCategory.bags, ItemCondition.good, 'tote,bag', 2, 38,
          age: const Duration(days: 3)),

      // ----- Omar (Houston) -----
      make('item_omar_novels', 'user_omar', 'Graphic Novel Set',
          'Boxed set of acclaimed graphic novels.',
          ItemCategory.books, ItemCondition.good, 'comic,books', 2, 60,
          age: const Duration(hours: 16)),
      make('item_omar_chess', 'user_omar', 'Wooden Chess Set',
          'Hand-carved wooden chess set with board.',
          ItemCategory.other, ItemCondition.likeNew, 'chess,set', 2, 55,
          age: const Duration(days: 2)),
    ];
  }
}
