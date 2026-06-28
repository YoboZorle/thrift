import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/message_model.dart';
import '../services/data_repository.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider(this._repo);

  final DataRepository _repo;
  static const _uuid = Uuid();

  String? _activeMatchId;
  List<MessageModel> _messages = [];
  bool _loading = false;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _loading;

  Future<void> open(String matchId) async {
    _activeMatchId = matchId;
    _loading = true;
    notifyListeners();
    _messages = await _repo.getMessages(matchId);
    _loading = false;
    notifyListeners();
  }

  Future<void> send({
    required String matchId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final msg = MessageModel(
      id: _uuid.v4(),
      matchId: matchId,
      senderId: senderId,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    await _repo.sendMessage(msg);
    if (_activeMatchId == matchId) {
      _messages = [..._messages, msg];
      notifyListeners();
    }
  }
}
