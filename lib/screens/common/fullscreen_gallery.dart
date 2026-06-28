import 'package:flutter/material.dart';

import '../../widgets/common_widgets.dart';

/// Fullscreen, swipeable image viewer with pinch-to-zoom (and double-tap zoom).
/// Opened by tapping an item photo.
class FullscreenGallery extends StatefulWidget {
  const FullscreenGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  final List<String> images;
  final int initialIndex;

  static Future<void> open(
    BuildContext context, {
    required List<String> images,
    int initialIndex = 0,
  }) {
    if (images.isEmpty) return Future.value();
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) =>
            FullscreenGallery(images: images, initialIndex: initialIndex),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<FullscreenGallery> {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late int _page = widget.initialIndex;

  // Per-page zoom controllers so double-tap can reset/toggle zoom.
  final Map<int, TransformationController> _controllers = {};

  TransformationController _controllerFor(int i) =>
      _controllers.putIfAbsent(i, () => TransformationController());

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleZoom(int i, TapDownDetails details) {
    final controller = _controllerFor(i);
    if (controller.value != Matrix4.identity()) {
      controller.value = Matrix4.identity();
    } else {
      final pos = details.localPosition;
      controller.value = Matrix4.identity()
        ..translate(-pos.dx, -pos.dy)
        ..scale(2.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              TapDownDetails? lastTap;
              return GestureDetector(
                onDoubleTapDown: (d) => lastTap = d,
                onDoubleTap: () {
                  if (lastTap != null) _toggleZoom(i, lastTap!);
                },
                child: InteractiveViewer(
                  transformationController: _controllerFor(i),
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: ItemImage(
                      source: widget.images[i],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.close_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_page + 1} / ${widget.images.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
