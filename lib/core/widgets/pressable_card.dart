import 'package:flutter/material.dart';

/// Interactive card wrapper providing smooth touch feedback micro-interactions.
///
/// When the user presses the card ([onTapDown] / pointer down), the card smoothly
/// shrinks to [scale] (default 0.98) in [duration] (default 100ms).
/// It restores to 1.0 when released ([onTapUp] / pointer up) or canceled ([onTapCancel]).
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  final Curve curve;

  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.98,
    this.duration = const Duration(milliseconds: 100),
    this.curve = Curves.easeInOut,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _isPressed = false;

  void _onPointerDown(PointerDownEvent event) {
    if (mounted) {
      setState(() => _isPressed = true);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isPressed && mounted) {
      setState(() => _isPressed = false);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_isPressed && mounted) {
      setState(() => _isPressed = false);
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (mounted) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_isPressed && mounted) {
      setState(() => _isPressed = false);
    }
  }

  void _onTapCancel() {
    if (_isPressed && mounted) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? widget.scale : 1.0,
          duration: widget.duration,
          curve: widget.curve,
          child: widget.child,
        ),
      ),
    );
  }
}
