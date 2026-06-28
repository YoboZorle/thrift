import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/enums.dart';
import '../../../models/item_model.dart';

/// External controller so action buttons can trigger swipes programmatically.
class SwipeCardController {
  _SwipeCardStackState? _state;

  void _attach(_SwipeCardStackState state) => _state = state;

  /// Only clear if the disposing state is the one we currently point at. When
  /// the deck key changes, the new stack attaches before the old one disposes;
  /// a naive detach would null out the freshly-attached state and silently
  /// break every action button.
  void _detach(_SwipeCardStackState state) {
    if (identical(_state, state)) _state = null;
  }

  void swipeRight() => _state?.programmaticSwipe(SwipeDirection.like);
  void swipeLeft() => _state?.programmaticSwipe(SwipeDirection.pass);

  /// Steps back to the previous card. Returns true if it moved.
  bool undo() => _state?.programmaticUndo() ?? false;

  /// The card currently on top (for "save"/bookmark), or null if exhausted.
  ItemModel? get currentItem => _state?.currentItem;

  bool get hasCards => (_state?._currentIndex ?? 0) < (_state?._cardCount ?? 0);
}

typedef SwipeCardBuilder = Widget Function(BuildContext context, ItemModel item);

class SwipeCardStack extends StatefulWidget {
  const SwipeCardStack({
    super.key,
    required this.items,
    required this.onSwipe,
    required this.cardBuilder,
    this.controller,
    this.onEmpty,
  });

  final List<ItemModel> items;
  final void Function(ItemModel item, SwipeDirection direction) onSwipe;
  final SwipeCardBuilder cardBuilder;
  final SwipeCardController? controller;
  final VoidCallback? onEmpty;

  @override
  State<SwipeCardStack> createState() => _SwipeCardStackState();
}

class _SwipeCardStackState extends State<SwipeCardStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<Offset>? _animation;

  Offset _drag = Offset.zero;
  int _currentIndex = 0;
  bool _isAnimating = false;

  int get _cardCount => widget.items.length;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        if (_animation != null) {
          setState(() => _drag = _animation!.value);
        }
      });
  }

  @override
  void didUpdateWidget(covariant SwipeCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset when a fresh deck is supplied.
    if (oldWidget.items != widget.items) {
      _currentIndex = 0;
      _drag = Offset.zero;
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _animController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() => _drag += details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating) return;
    if (_drag.dx.abs() > AppConstants.swipeThreshold) {
      final dir = _drag.dx > 0 ? SwipeDirection.like : SwipeDirection.pass;
      _flyOut(dir);
    } else {
      _springBack();
    }
  }

  void programmaticSwipe(SwipeDirection direction) {
    if (_isAnimating || _currentIndex >= _cardCount) return;
    setState(() => _drag = Offset(direction == SwipeDirection.like ? 40 : -40, 0));
    _flyOut(direction);
  }

  /// The card currently on top, or null if the deck is exhausted.
  ItemModel? get currentItem =>
      (_currentIndex < _cardCount) ? widget.items[_currentIndex] : null;

  /// Steps back to re-show the previously swiped card.
  bool programmaticUndo() {
    if (_isAnimating || _currentIndex <= 0) return false;
    setState(() {
      _currentIndex--;
      _drag = Offset.zero;
    });
    return true;
  }

  void _springBack() {
    _animation = Tween<Offset>(begin: _drag, end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward(from: 0);
  }

  void _flyOut(SwipeDirection direction) {
    final size = MediaQuery.of(context).size;
    final endX = direction == SwipeDirection.like
        ? size.width * 1.5
        : -size.width * 1.5;
    final item = widget.items[_currentIndex];

    _isAnimating = true;
    _animation = Tween<Offset>(
      begin: _drag,
      end: Offset(endX, _drag.dy),
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward(from: 0).whenComplete(() {
      widget.onSwipe(item, direction);
      setState(() {
        _currentIndex++;
        _drag = Offset.zero;
        _isAnimating = false;
      });
      if (_currentIndex >= _cardCount) widget.onEmpty?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _cardCount) {
      return const SizedBox.shrink();
    }

    final cards = <Widget>[];
    // Render up to 3 cards (current + 2 behind) for depth.
    for (int i = _currentIndex; i < _currentIndex + 3 && i < _cardCount; i++) {
      final isTop = i == _currentIndex;
      final depth = i - _currentIndex;
      cards.add(_buildCard(widget.items[i], isTop, depth));
    }

    return Stack(
      alignment: Alignment.center,
      children: cards.reversed.toList(),
    );
  }

  Widget _buildCard(ItemModel item, bool isTop, int depth) {
    final scale = 1 - (depth * 0.04);
    final translateY = depth * 14.0;

    if (!isTop) {
      return Transform.translate(
        offset: Offset(0, translateY),
        child: Transform.scale(
          scale: scale,
          child: widget.cardBuilder(context, item),
        ),
      );
    }

    final rotation =
        (_drag.dx / 360).clamp(-AppConstants.maxRotation, AppConstants.maxRotation);
    final likeOpacity =
        (_drag.dx / AppConstants.swipeThreshold).clamp(0.0, 1.0);
    final nopeOpacity =
        (-_drag.dx / AppConstants.swipeThreshold).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _drag,
        child: Transform.rotate(
          angle: rotation,
          child: Stack(
            children: [
              widget.cardBuilder(context, item),
              Positioned(
                top: 28,
                left: 22,
                child: _StampLabel(
                  text: 'SWAP',
                  color: const Color(0xFF22C55E),
                  opacity: likeOpacity,
                  angle: -0.3,
                ),
              ),
              Positioned(
                top: 28,
                right: 22,
                child: _StampLabel(
                  text: 'PASS',
                  color: const Color(0xFFF43F5E),
                  opacity: nopeOpacity,
                  angle: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StampLabel extends StatelessWidget {
  const _StampLabel({
    required this.text,
    required this.color,
    required this.opacity,
    required this.angle,
  });

  final String text;
  final Color color;
  final double opacity;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
