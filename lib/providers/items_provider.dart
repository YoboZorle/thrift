import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/enums.dart';
import '../models/item_model.dart';
import '../services/data_repository.dart';

class ItemsProvider extends ChangeNotifier {
  ItemsProvider(this._repo);

  final DataRepository _repo;
  static const _uuid = Uuid();

  List<ItemModel> _myItems = [];
  bool _loading = false;

  List<ItemModel> get myItems => _myItems;
  bool get isLoading => _loading;
  int get myItemCount => _myItems.length;

  Future<ItemModel?> getItem(String id) => _repo.getItem(id);

  Future<void> loadMyItems(String userId) async {
    _loading = true;
    notifyListeners();
    _myItems = await _repo.getItemsByOwner(userId);
    _loading = false;
    notifyListeners();
  }

  Future<ItemModel> addItem({
    required String ownerId,
    required String title,
    required String description,
    required ItemCategory category,
    required ItemCondition condition,
    required List<String> images,
    double? estimatedValue,
  }) async {
    final item = ItemModel(
      id: _uuid.v4(),
      ownerId: ownerId,
      title: title.trim(),
      description: description.trim(),
      category: category,
      condition: condition,
      images: images,
      estimatedValue: estimatedValue,
      createdAt: DateTime.now(),
    );
    await _repo.addItem(item);
    _myItems = await _repo.getItemsByOwner(ownerId);
    notifyListeners();
    return item;
  }

  Future<void> toggleActive(ItemModel item) async {
    await _repo.updateItem(item.copyWith(isActive: !item.isActive));
    _myItems = await _repo.getItemsByOwner(item.ownerId);
    notifyListeners();
  }

  Future<void> deleteItem(ItemModel item) async {
    await _repo.deleteItem(item.id);
    _myItems = await _repo.getItemsByOwner(item.ownerId);
    notifyListeners();
  }
}
