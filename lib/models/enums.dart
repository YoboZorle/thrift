/// Shared enums used across models. String-backed for easy persistence /
/// Firestore serialisation.

enum ItemCategory {
  clothing,
  shoes,
  bags,
  accessories,
  electronics,
  books,
  home,
  other,
}

extension ItemCategoryX on ItemCategory {
  String get label {
    switch (this) {
      case ItemCategory.clothing:
        return 'Clothing';
      case ItemCategory.shoes:
        return 'Shoes';
      case ItemCategory.bags:
        return 'Bags';
      case ItemCategory.accessories:
        return 'Accessories';
      case ItemCategory.electronics:
        return 'Electronics';
      case ItemCategory.books:
        return 'Books';
      case ItemCategory.home:
        return 'Home';
      case ItemCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ItemCategory.clothing:
        return '👕';
      case ItemCategory.shoes:
        return '👟';
      case ItemCategory.bags:
        return '👜';
      case ItemCategory.accessories:
        return '⌚';
      case ItemCategory.electronics:
        return '🎧';
      case ItemCategory.books:
        return '📚';
      case ItemCategory.home:
        return '🛋️';
      case ItemCategory.other:
        return '📦';
    }
  }

  static ItemCategory fromName(String? name) => ItemCategory.values.firstWhere(
        (c) => c.name == name,
        orElse: () => ItemCategory.other,
      );
}

enum ItemCondition { brandNew, likeNew, good, fair, faulty }

extension ItemConditionX on ItemCondition {
  String get label {
    switch (this) {
      case ItemCondition.brandNew:
        return 'Brand new';
      case ItemCondition.likeNew:
        return 'Like new';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.faulty:
        return 'Faulty';
    }
  }

  static ItemCondition fromName(String? name) =>
      ItemCondition.values.firstWhere(
        (c) => c.name == name,
        orElse: () => ItemCondition.good,
      );
}

enum SwipeDirection { like, pass }

extension SwipeDirectionX on SwipeDirection {
  static SwipeDirection fromName(String? name) =>
      SwipeDirection.values.firstWhere(
        (d) => d.name == name,
        orElse: () => SwipeDirection.pass,
      );
}

/// Manual identity-verification state for a user.
enum VerificationStatus { unverified, verified, rejected }

extension VerificationStatusX on VerificationStatus {
  bool get isVerified => this == VerificationStatus.verified;

  static VerificationStatus fromName(String? name) =>
      VerificationStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => VerificationStatus.unverified,
      );
}
