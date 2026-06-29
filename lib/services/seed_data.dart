import '../core/constants/app_config.dart';
import '../models/enums.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';

/// Seeds a realistic community of Nigerian swappers + their items on first
/// launch, so a freshly signed-in user has people and goods to discover and
/// match with. Values are in Naira.
///
/// The signed-in user is NOT seeded here — they get a unique account tied to
/// their auth identity (plus a few starter listings, see AuthProvider). Every
/// seeded record is unique (unique ids + unique, product-relevant images).
class SeedData {
  static const double _baseLat = 6.5244; // Lagos anchor
  static const double _baseLng = 3.3792;

  // Picsum is a reliable, deterministic image CDN: the same seed always
  // returns the same photo, and it doesn't rate-limit / 404 the way LoremFlickr
  // did (which is what caused the broken images). The keyword is kept only so
  // the call sites read meaningfully; the unique lock drives the seed.
  static String _photo(String keywords, int lock) =>
      'https://picsum.photos/seed/ts$lock/800/1000';

  // randomuser.me serves a fixed, reliable set of real-face portraits (0–99 per
  // gender) as static files — far more dependable than pravatar.
  static String _avatar(String gender, int n) =>
      'https://randomuser.me/api/portraits/'
      '${gender == 'Female' ? 'women' : 'men'}/${n % 100}.jpg';

  static List<UserModel> users() {
    final now = DateTime.now();
    UserModel u(String id, String name, String city, String state, String bio,
        String gender, int age, int avatar) {
      return UserModel(
        id: id,
        name: name,
        location: '$city, $state',
        city: city,
        state: state,
        bio: bio,
        gender: gender,
        dob: DateTime(now.year - age, 4, 12),
        avatarUrl: _avatar(gender, avatar),
        verificationStatus: VerificationStatus.verified,
        createdAt: now,
      );
    }

    return [
      u('user_amara', 'Amara Okafor', 'Lagos', 'Lagos',
          'Sneakerhead. Swap me something fresh.', 'Female', 27, 5),
      u('user_kunle', 'Kunle Adeyemi', 'Lagos', 'Lagos',
          'Books, gadgets and good vibes.', 'Male', 31, 12),
      u('user_zainab', 'Zainab Bello', 'Abuja', 'FCT (Abuja)',
          'Thrift lover — vintage everything.', 'Female', 24, 9),
      u('user_tobi', 'Tobi Williams', 'Lagos', 'Lagos',
          'Minimalist swapping up my home stuff.', 'Male', 29, 14),
      u('user_ngozi', 'Ngozi Eze', 'Enugu', 'Enugu',
          'Closet refresh in progress.', 'Female', 26, 16),
      u('user_emeka', 'Emeka Nwosu', 'Lagos', 'Lagos',
          'Sports gear and tech. Let\'s deal.', 'Male', 33, 33),
      u('user_aisha', 'Aisha Mohammed', 'Kano', 'Kano',
          'Books, home & little treasures.', 'Female', 28, 20),
      u('user_chidi', 'Chidi Obi', 'Port Harcourt', 'Rivers',
          'Outdoors and everyday carry swaps.', 'Male', 30, 52),
      u('user_funke', 'Funke Alabi', 'Ibadan', 'Oyo',
          'Accessories & smart-casual pieces.', 'Female', 25, 25),
      u('user_musa', 'Musa Danjuma', 'Kaduna', 'Kaduna',
          'Tech tinkerer and runner.', 'Male', 34, 60),
      u('user_blessing', 'Blessing Edet', 'Benin City', 'Edo',
          'Cozy home goods and totes.', 'Female', 27, 45),
      u('user_yusuf', 'Yusuf Sani', 'Abuja', 'FCT (Abuja)',
          'Books, board games, good trades.', 'Male', 32, 13),
      u('user_chioma', 'Chioma Okeke', 'Lagos', 'Lagos',
          'Beauty finds & accessories.', 'Female', 23, 31),
      u('user_ibrahim', 'Ibrahim Lawal', 'Lagos', 'Lagos',
          'Gadgets and audio gear.', 'Male', 35, 56),
      u('user_folake', 'Folake Ogun', 'Lagos', 'Lagos',
          'Shoes, dresses, and bags.', 'Female', 28, 47),
      u('user_tunde', 'Tunde Bakare', 'Port Harcourt', 'Rivers',
          'Fitness and electronics swaps.', 'Male', 31, 68),
    ];
  }

  static List<ItemModel> items() {
    final now = DateTime.now();

    // Owner -> (city, state, dLat, dLng) — rough offsets from the Lagos anchor.
    const place = <String, List<dynamic>>{
      'user_amara': ['Lagos', 'Lagos', 0.012, 0.006],
      'user_kunle': ['Lagos', 'Lagos', -0.018, 0.004],
      'user_zainab': ['Abuja', 'FCT (Abuja)', 2.55, 4.11],
      'user_tobi': ['Lagos', 'Lagos', 0.03, 0.025],
      'user_ngozi': ['Enugu', 'Enugu', -0.07, 4.13],
      'user_emeka': ['Lagos', 'Lagos', -0.01, 0.02],
      'user_aisha': ['Kano', 'Kano', 5.48, 5.21],
      'user_chidi': ['Port Harcourt', 'Rivers', -1.71, 3.67],
      'user_funke': ['Ibadan', 'Oyo', 0.86, 0.57],
      'user_musa': ['Kaduna', 'Kaduna', 4.0, 4.06],
      'user_blessing': ['Benin City', 'Edo', -0.18, 2.24],
      'user_yusuf': ['Abuja', 'FCT (Abuja)', 2.55, 4.11],
      'user_chioma': ['Lagos', 'Lagos', 0.02, -0.01],
      'user_ibrahim': ['Lagos', 'Lagos', -0.02, 0.012],
      'user_folake': ['Lagos', 'Lagos', 0.008, 0.03],
      'user_tunde': ['Port Harcourt', 'Rivers', -1.7, 3.66],
    };

    var lockSeed = 100;

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
      String defect = '',
    }) {
      final p = place[owner]!;
      final images =
          List.generate(photoCount, (_) => _photo(keywords, lockSeed++));
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
        defectNote: defect,
        // Give every listing a realistic, DISTINCT amount of time left by
        // mapping its age onto the live window proportionally (older listing →
        // less time remaining), plus a small deterministic per-item offset so
        // even items posted "around the same time" differ. Scales to both the
        // 5-minute test window and the 48-hour production window, and stays live
        // at seed time (portion capped below 1.0).
        createdAt: now.subtract(AppConfig.listingWindow *
            ((age.inMinutes / const Duration(days: 6).inMinutes) +
                    (id.hashCode.abs() % 70) / 1000.0)
                .clamp(0.03, 0.92)),
      );
    }

    return [
      // Amara (Lagos)
      make('item_amara_af1', 'user_amara', 'Nike Air Force 1',
          'Crisp white AF1, lightly worn. A grail swap.', ItemCategory.shoes,
          ItemCondition.good, 'sneakers', 3, 55000,
          age: const Duration(hours: 2)),
      make('item_amara_shirt', 'user_amara', 'Vintage Denim Shirt',
          'Oversized 90s denim shirt. A vibe.', ItemCategory.clothing,
          ItemCondition.good, 'denim,shirt', 2, 12000,
          age: const Duration(days: 1)),
      make('item_amara_watch', 'user_amara', 'Classic Wristwatch',
          'Silver analog watch, new battery.', ItemCategory.accessories,
          ItemCondition.likeNew, 'wristwatch', 2, 25000,
          age: const Duration(days: 3)),

      // Kunle (Lagos)
      make('item_kunle_headphones', 'user_kunle', 'Wireless Headphones',
          'Over-ear, noise cancelling.', ItemCategory.electronics,
          ItemCondition.likeNew, 'headphones', 2, 45000,
          age: const Duration(hours: 20)),
      make('item_kunle_books', 'user_kunle', 'Box of Novels',
          '15 paperback novels, mixed genres.', ItemCategory.books,
          ItemCondition.good, 'books', 2, 8000, age: const Duration(days: 4)),

      // Zainab (Abuja)
      make('item_zainab_jacket', 'user_zainab', 'Leather Jacket',
          'Classic black biker jacket.', ItemCategory.clothing,
          ItemCondition.good, 'leather,jacket', 2, 38000,
          age: const Duration(hours: 9)),
      make('item_zainab_heels', 'user_zainab', 'Designer Heels',
          'Red block heels, worn twice. Size 39.', ItemCategory.shoes,
          ItemCondition.likeNew, 'high,heels', 2, 20000,
          age: const Duration(days: 2)),

      // Tobi (Lagos)
      make('item_tobi_lamp', 'user_tobi', 'Modern Floor Lamp',
          'Minimalist standing lamp, warm light.', ItemCategory.home,
          ItemCondition.likeNew, 'floor,lamp', 2, 18000,
          age: const Duration(days: 3)),
      make('item_tobi_backpack', 'user_tobi', 'Travel Backpack',
          '40L water-resistant backpack.', ItemCategory.bags,
          ItemCondition.likeNew, 'backpack', 2, 22000,
          age: const Duration(hours: 30)),

      // Ngozi (Enugu)
      make('item_ngozi_dress', 'user_ngozi', 'Floral Summer Dress',
          'Flowy floral midi dress, size M.', ItemCategory.clothing,
          ItemCondition.likeNew, 'floral,dress', 2, 15000,
          age: const Duration(hours: 14)),
      make('item_ngozi_camera', 'user_ngozi', 'Instant Film Camera',
          'Retro instant camera + a pack of film.', ItemCategory.electronics,
          ItemCondition.good, 'instant,camera', 2, 60000,
          age: const Duration(days: 2)),

      // Emeka (Lagos)
      make('item_emeka_ball', 'user_emeka', 'Official Basketball',
          'Indoor/outdoor leather basketball.', ItemCategory.other,
          ItemCondition.good, 'basketball', 2, 9000,
          age: const Duration(hours: 6)),
      make('item_emeka_speaker', 'user_emeka', 'Bluetooth Speaker',
          'Portable waterproof speaker.', ItemCategory.electronics,
          ItemCondition.likeNew, 'bluetooth,speaker', 2, 28000,
          age: const Duration(days: 1)),
      make('item_emeka_sunglasses', 'user_emeka', 'Polarized Sunglasses',
          'Matte black frames, polarized lenses.', ItemCategory.accessories,
          ItemCondition.good, 'sunglasses', 2, 14000,
          age: const Duration(days: 5)),

      // Aisha (Kano)
      make('item_aisha_cookbook', 'user_aisha', 'Illustrated Cookbook',
          'Hardcover cookbook, 200+ recipes.', ItemCategory.books,
          ItemCondition.likeNew, 'cookbook', 2, 6000,
          age: const Duration(hours: 40)),
      make('item_aisha_vase', 'user_aisha', 'Ceramic Vase',
          'Handmade ceramic vase, matte glaze.', ItemCategory.home,
          ItemCondition.likeNew, 'ceramic,vase', 2, 10000,
          age: const Duration(days: 3)),

      // Chidi (Port Harcourt)
      make('item_chidi_boots', 'user_chidi', 'Hiking Boots',
          'Waterproof hiking boots, size 44.', ItemCategory.shoes,
          ItemCondition.good, 'hiking,boots', 2, 35000,
          age: const Duration(hours: 18)),
      make('item_chidi_duffel', 'user_chidi', 'Canvas Duffel Bag',
          'Rugged canvas weekender duffel.', ItemCategory.bags,
          ItemCondition.good, 'duffel,bag', 2, 16000,
          age: const Duration(days: 2)),
      make('item_chidi_guitar', 'user_chidi', 'Acoustic Guitar',
          'Full-size acoustic, warm tone.', ItemCategory.other,
          ItemCondition.good, 'acoustic,guitar', 2, 70000,
          age: const Duration(days: 4)),

      // Funke (Ibadan)
      make('item_funke_earrings', 'user_funke', 'Gold Hoop Earrings',
          '14k-plated hoops, never worn.', ItemCategory.accessories,
          ItemCondition.likeNew, 'gold,earrings', 2, 13000,
          age: const Duration(hours: 7)),
      make('item_funke_blazer', 'user_funke', 'Linen Blazer',
          'Beige linen blazer, tailored. Size S.', ItemCategory.clothing,
          ItemCondition.good, 'linen,blazer', 2, 19000,
          age: const Duration(days: 1)),

      // Musa (Kaduna)
      make('item_musa_keyboard', 'user_musa', 'Mechanical Keyboard',
          'Hot-swappable, tactile switches.', ItemCategory.electronics,
          ItemCondition.likeNew, 'mechanical,keyboard', 2, 32000,
          age: const Duration(hours: 12)),
      make('item_musa_shoes', 'user_musa', 'Running Shoes',
          'Lightweight running shoes, size 43.', ItemCategory.shoes,
          ItemCondition.good, 'running,shoes', 2, 24000,
          age: const Duration(days: 2)),

      // Blessing (Benin City)
      make('item_blessing_pillows', 'user_blessing', 'Throw Pillow Set',
          'Set of 2 boucle throw pillows.', ItemCategory.home,
          ItemCondition.likeNew, 'throw,pillow', 2, 11000,
          age: const Duration(hours: 22)),
      make('item_blessing_tote', 'user_blessing', 'Woven Tote Bag',
          'Roomy woven tote, great for markets.', ItemCategory.bags,
          ItemCondition.good, 'tote,bag', 2, 9000, age: const Duration(days: 3)),

      // Yusuf (Abuja)
      make('item_yusuf_novels', 'user_yusuf', 'Graphic Novel Set',
          'Boxed set of acclaimed graphic novels.', ItemCategory.books,
          ItemCondition.good, 'comic,books', 2, 17000,
          age: const Duration(hours: 16)),
      make('item_yusuf_chess', 'user_yusuf', 'Wooden Chess Set',
          'Hand-carved wooden chess set + board.', ItemCategory.other,
          ItemCondition.likeNew, 'chess,set', 2, 15000,
          age: const Duration(days: 2)),

      // Chioma (Lagos)
      make('item_chioma_perfume', 'user_chioma', 'Designer Perfume',
          'Eau de parfum, 80% full. Long lasting.', ItemCategory.accessories,
          ItemCondition.good, 'perfume,bottle', 2, 22000,
          age: const Duration(hours: 5)),
      make('item_chioma_handbag', 'user_chioma', 'Leather Handbag',
          'Structured leather handbag, tan.', ItemCategory.bags,
          ItemCondition.good, 'leather,handbag', 2, 30000,
          age: const Duration(days: 1)),

      // Ibrahim (Lagos)
      make('item_ibrahim_earbuds', 'user_ibrahim', 'Wireless Earbuds',
          'True wireless earbuds with case.', ItemCategory.electronics,
          ItemCondition.likeNew, 'earbuds', 2, 27000,
          age: const Duration(hours: 8)),
      make('item_ibrahim_tablet', 'user_ibrahim', 'Android Tablet',
          '10-inch tablet, 64GB. Works great otherwise.',
          ItemCategory.electronics, ItemCondition.faulty, 'tablet', 2, 40000,
          age: const Duration(days: 1),
          defect: 'Small crack at the top-left corner of the screen; '
              'touch and display work fully.'),

      // Folake (Lagos)
      make('item_folake_sneakers', 'user_folake', 'White Sneakers',
          'Minimal white leather sneakers, size 40.', ItemCategory.shoes,
          ItemCondition.good, 'white,sneakers', 2, 26000,
          age: const Duration(hours: 10)),
      make('item_folake_gown', 'user_folake', 'Evening Gown',
          'Elegant floor-length gown, worn once.', ItemCategory.clothing,
          ItemCondition.likeNew, 'evening,gown', 2, 33000,
          age: const Duration(days: 2)),
      make('item_folake_clutch', 'user_folake', 'Beaded Clutch',
          'Hand-beaded evening clutch.', ItemCategory.bags,
          ItemCondition.likeNew, 'clutch,bag', 2, 12000,
          age: const Duration(days: 3)),

      // Tunde (Port Harcourt)
      make('item_tunde_dumbbells', 'user_tunde', 'Dumbbell Set',
          'Adjustable dumbbell set, 20kg total.', ItemCategory.other,
          ItemCondition.faulty, 'dumbbell', 2, 20000,
          age: const Duration(hours: 14),
          defect: 'One handle is slightly bent but fully usable.'),
      make('item_tunde_monitor', 'user_tunde', 'Computer Monitor',
          '24-inch 1080p monitor, HDMI + VGA.', ItemCategory.electronics,
          ItemCondition.good, 'computer,monitor', 2, 48000,
          age: const Duration(days: 2)),
    ];
  }
}
