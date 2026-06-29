import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/support.dart';
import '../../models/item_model.dart';
import '../../models/match_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common_widgets.dart';
import '../profile/user_profile_screen.dart';

/// Chat scoped to a single match (a single product-for-product swap).
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.match,
    required this.otherUser,
    this.myItem,
    this.theirItem,
  });

  final MatchModel match;
  final UserModel otherUser;
  final ItemModel? myItem;
  final ItemModel? theirItem;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().open(widget.match.id).then((_) => _toBottom());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toBottom() {
    if (!mounted || !_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    final userId = context.read<AuthProvider>().currentUser!.id;
    _controller.clear();
    await context.read<ChatProvider>().send(
          matchId: widget.match.id,
          senderId: userId,
          text: text,
        );
    _toBottom();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().currentUser!.id;
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(user: widget.otherUser),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: widget.otherUser.avatarUrl != null
                    ? NetworkImage(widget.otherUser.avatarUrl!)
                    : null,
                child: widget.otherUser.avatarUrl == null
                    ? Text(
                        widget.otherUser.name.characters.first,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.otherUser.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint, size: 20),
              const SizedBox(width: 6),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'profile') {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => UserProfileScreen(user: widget.otherUser),
                ));
              } else if (v == 'report') {
                final ok = await Support.contactAdmin(
                    message: Support.reportUser(
                        widget.otherUser.name, widget.otherUser.id));
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Couldn\'t open WhatsApp. Please install it or try again.')),
                  );
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('View profile')),
              PopupMenuItem(value: 'report', child: Text('Report user')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _swapBanner(),
          Expanded(
            child: chat.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chat.messages.isEmpty
                    ? _emptyChat()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        itemCount: chat.messages.length,
                        itemBuilder: (context, i) {
                          final msg = chat.messages[i];
                          if (msg.senderId == AppConstants.kSystemSenderId) {
                            return _SystemNote(text: msg.text);
                          }
                          final mine = msg.senderId == userId;
                          return _Bubble(message: msg, isMine: mine);
                        },
                      ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _swapBanner() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          _bannerThumb(widget.theirItem),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.swap_horiz, size: 18, color: AppColors.primary),
          ),
          _bannerThumb(widget.myItem),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.theirItem == null || widget.myItem == null
                  ? 'Arrange your swap'
                  : '${widget.theirItem!.title} for ${widget.myItem!.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerThumb(ItemModel? item) {
    return Container(
      width: 32,
      height: 32,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: item == null ? const SizedBox() : ItemImage(source: item.primaryImage),
    );
  }

  Widget _emptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.waving_hand_outlined,
                size: 40, color: AppColors.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(
              'Say hi to ${widget.otherUser.name}!',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Agree on where and when to meet for the swap.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Message…',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _send,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemNote extends StatelessWidget {
  const _SystemNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMine});
  final MessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMine ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              Formatters.chatTime(message.createdAt),
              style: TextStyle(
                color: isMine ? Colors.white70 : AppColors.textHint,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
