import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/item_model.dart';
import '../../models/match_model.dart';
import '../../models/swipe_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/swipe_match_provider.dart';
import '../../widgets/common_widgets.dart';
import '../matches/match_detail_screen.dart';

enum _Kind { liked, passed, matched }

class _Event {
  final _Kind kind;
  final DateTime time;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final MatchModel? match;
  const _Event({
    required this.kind,
    required this.time,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.match,
  });
}

/// A chronological log of what happened: every item you liked or passed, and
/// every match you made (with the exact give/get items).
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late Future<List<_Event>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_Event>> _load() async {
    final prov = context.read<SwipeMatchProvider>();
    final userId = context.read<AuthProvider>().currentUser!.id;

    final swipes = await prov.mySwipes(userId);
    final matches = await prov.matchesFor(userId);
    final items = {for (final i in await prov.allItems()) i.id: i};
    final users = {for (final u in await prov.allUsers()) u.id: u};

    String ownerName(ItemModel? it) =>
        it == null ? 'someone' : (users[it.ownerId]?.name ?? 'someone');

    final events = <_Event>[];

    for (final s in swipes) {
      final it = items[s.targetItemId];
      final liked = s.direction == SwipeDirection.like;
      events.add(_Event(
        kind: liked ? _Kind.liked : _Kind.passed,
        time: s.createdAt,
        title: liked
            ? 'You liked ${ownerName(it)}\'s ${it?.title ?? 'item'}'
            : 'You passed on ${ownerName(it)}\'s ${it?.title ?? 'item'}',
        subtitle: liked
            ? 'Swiped right — interest sent'
            : 'Swiped left — not this time',
        imageUrl: it?.primaryImage,
      ));
    }

    for (final m in matches) {
      final other = users[m.otherUserId(userId)];
      final mine = items[m.myItemId(userId)];
      final theirs = items[m.theirItemId(userId)];
      events.add(_Event(
        kind: _Kind.matched,
        time: m.createdAt,
        title: 'Matched with ${other?.name ?? 'someone'}',
        subtitle:
            'You give ${mine?.title ?? 'your item'} ⇄ you get ${theirs?.title ?? 'their item'}',
        imageUrl: theirs?.primaryImage ?? other?.avatarUrl,
        match: m,
      ));
    }

    events.sort((a, b) => b.time.compareTo(a.time));
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Swap & match history')),
      body: FutureBuilder<List<_Event>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snap.data!;
          if (events.isEmpty) {
            return const EmptyState(
              icon: Icons.history_rounded,
              title: 'No activity yet',
              message:
                  'Your swipes and matches will appear here as you start swapping.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _EventTile(event: events[i]),
          );
        },
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final _Event event;

  ({IconData icon, Color color}) get _badge {
    switch (event.kind) {
      case _Kind.liked:
        return (icon: Icons.favorite_rounded, color: AppColors.like);
      case _Kind.passed:
        return (icon: Icons.close_rounded, color: AppColors.nope);
      case _Kind.matched:
        return (icon: Icons.swap_horiz_rounded, color: AppColors.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _badge;
    final tappable = event.match != null;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: tappable
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MatchDetailScreen(match: event.match!),
                  ),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: ItemImage(source: event.imageUrl ?? ''),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: b.color,
                        child: Icon(b.icon, size: 11, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14.5)),
                    const SizedBox(height: 2),
                    Text(event.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(Formatters.timeAgo(event.time),
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }
}
