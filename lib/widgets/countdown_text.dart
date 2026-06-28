import 'dart:async';
import 'package:flutter/material.dart';

/// A live, ticking countdown to [deadline]. Updates every second and calls
/// [onExpired] once when it reaches zero. Use [builder] for custom rendering
/// (e.g. a pill), or pass a [style] for plain text.
class CountdownText extends StatefulWidget {
  const CountdownText({
    super.key,
    required this.deadline,
    this.style,
    this.prefix = '',
    this.expiredText = 'Expired',
    this.onExpired,
    this.builder,
  });

  final DateTime deadline;
  final TextStyle? style;
  final String prefix;
  final String expiredText;
  final VoidCallback? onExpired;
  final Widget Function(BuildContext context, String label, bool expired)?
      builder;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _firedExpired = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _firedExpired = false;
    _tick();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final r = widget.deadline.difference(DateTime.now());
    if (mounted) setState(() => _remaining = r);
    if (r <= Duration.zero) {
      _timer?.cancel();
      if (!_firedExpired) {
        _firedExpired = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onExpired?.call();
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    if (d.inHours >= 1) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining <= Duration.zero;
    final label =
        expired ? widget.expiredText : '${widget.prefix}${_format(_remaining)}';
    if (widget.builder != null) return widget.builder!(context, label, expired);
    return Text(label, style: widget.style);
  }
}
