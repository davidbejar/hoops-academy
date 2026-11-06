import 'package:flutter/material.dart';

/// Subtle entrance motion: fades [child] in and lifts it by a few pixels the
/// first time it scrolls into view. With reduced motion (the platform's
/// "disable animations") the child is shown as is, at once.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;

  /// Stagger within a group (the hero's lines enter one after another).
  final Duration delay;

  static const _motion = Duration(milliseconds: 650);
  static const _lift = 24.0;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + Reveal._motion,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMicroseconds / _controller.duration!.inMicroseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );
  ScrollPosition? _position;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _controller.value = 1;
      return;
    }
    _position?.removeListener(_check);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  /// Starts once the top of the child is inside the viewport.
  void _check() {
    if (_started || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < MediaQuery.sizeOf(context).height) {
      _started = true;
      _position?.removeListener(_check);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    builder: (context, child) => Opacity(
      opacity: _progress.value,
      child: Transform.translate(
        offset: Offset(0, Reveal._lift * (1 - _progress.value)),
        child: child,
      ),
    ),
    child: widget.child,
  );
}
