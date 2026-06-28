import 'package:flutter/material.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/enums.dart';
import '../../../models/item_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/common_widgets.dart';

/// Dark, Bumble-style swipe card: full-bleed image with a tap-to-browse photo
/// carousel and an overlapping info panel (JUST LISTED / title / meta row).
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.item,
    this.owner,
    this.distanceLabel,
    this.onExpand,
  });

  final ItemModel item;
  final UserModel? owner;
  final String? distanceLabel;
  final VoidCallback? onExpand;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  int _photo = 0;

  List<String> get _images =>
      widget.item.images.isEmpty ? [''] : widget.item.images;

  bool get _justListed {
    final hours = DateTime.now().difference(widget.item.createdAt).inHours;
    return hours <= AppConfig.justListedHours;
  }

  void _tapZone(bool next) {
    setState(() {
      if (next) {
        _photo = (_photo + 1) % _images.length;
      } else {
        _photo = (_photo - 1 + _images.length) % _images.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ItemImage(source: _images[_photo], fit: BoxFit.cover),

          // Tap zones for photo browsing (don't interfere with pan-to-swipe).
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _tapZone(false),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _tapZone(true),
                ),
              ),
            ],
          ),

          // Scrim for legibility.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.cardScrim),
            ),
          ),

          // Photo indicator dots.
          if (_images.length > 1)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _photo ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _photo
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

          // Info panel.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (_justListed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'JUST LISTED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onExpand,
                        child: Icon(
                          widget.onExpand != null
                              ? Icons.keyboard_arrow_up_rounded
                              : null,
                          color: Colors.white70,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (item.estimatedValue != null) ...[
                        _meta('≈ \$${item.estimatedValue!.toStringAsFixed(0)}'),
                        _dot(),
                      ],
                      _meta(
                        widget.distanceLabel ?? 'Nearby',
                        icon: Icons.location_on_outlined,
                      ),
                      _dot(),
                      _meta(item.condition.label, icon: Icons.graphic_eq),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(String text, {IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
      );
}
