import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/item_model.dart';
import '../../models/match_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/swipe_match_provider.dart';
import '../../widgets/common_widgets.dart';
import '../chat/chat_screen.dart';

/// Conversations list — every confirmed swap match is a chat thread.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final swipeMatch = context.watch<SwipeMatchProvider>();
    final userId = context.watch<AuthProvider>().currentUser?.id;
    final matches = swipeMatch.matches;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Chats'), automaticallyImplyLeading: false),
      body: SafeArea(
        top: false,
        child: (userId == null || matches.isEmpty)
            ? const EmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'No chats yet',
                message:
                    'When you match with someone, your conversation appears here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: matches.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 84,
                  color: AppColors.border,
                ),
                itemBuilder: (_, i) =>
                    _ChatTile(match: matches[i], userId: userId),
              ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.match, required this.userId});
  final MatchModel match;
  final String userId;

  String _previewText(MessageModel? last, String userId) {
    if (last == null) return 'Tap to start chatting';
    if (last.senderId == AppConstants.kSystemSenderId) return last.text;
    if (last.senderId == userId) return 'You: ${last.text}';
    return last.text;
  }

  @override
  Widget build(BuildContext context) {
    final sm = context.read<SwipeMatchProvider>();
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        sm.user(match.otherUserId(userId)),
        sm.item(match.myItemId(userId)),
        sm.item(match.theirItemId(userId)),
        sm.lastMessage(match.id),
      ]),
      builder: (context, snap) {
        final other = snap.data?[0] as UserModel?;
        final myItem = snap.data?[1] as ItemModel?;
        final theirItem = snap.data?[2] as ItemModel?;
        final last = snap.data?[3] as MessageModel?;

        final unread = !match.seen;
        final preview = _previewText(last, userId);

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Stack(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: ItemImage(source: other?.avatarUrl ?? ''),
                ),
              ),
              if (!match.seen)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            other?.name ?? 'Swapper',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unread ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          trailing: Text(
            Formatters.timeAgo(last?.createdAt ?? match.lastActivity),
            style: const TextStyle(color: AppColors.textHint, fontSize: 11.5),
          ),
          onTap: other == null
              ? null
              : () {
                  final sm = context.read<SwipeMatchProvider>();
                  sm.markSeen(match.id, userId);
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            match: match,
                            otherUser: other,
                            myItem: myItem,
                            theirItem: theirItem,
                          ),
                        ),
                      )
                      // Re-sort so the thread you just messaged in jumps to the
                      // top when you come back.
                      .then((_) => sm.refreshMatches(userId));
                },
        );
      },
    );
  }
}
