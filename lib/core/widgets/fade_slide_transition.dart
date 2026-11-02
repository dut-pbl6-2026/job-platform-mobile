import 'dart:async';
import 'package:flutter/material.dart';

/// Reusable wrapper widget providing staggered entry animations for list items.
///
/// Slides the [child] upwards from [offsetY] (default 0.08) to 0 alongside a
/// [FadeTransition] from 0 to 1. Applies a staggered delay increasing by 50ms per [index].
class FadeSlideTransition extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final double offsetY;
  final Curve curve;

  const FadeSlideTransition({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 320),
    this.offsetY = 0.08,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.offsetY),
      end: Offset.zero,
    ).animate(curved);

    _startAnimation();
  }

  void _startAnimation() {
    _delayTimer?.cancel();
    final delayMs = widget.index * 50;
    if (delayMs <= 0) {
      _controller.forward();
    } else {
      _delayTimer = Timer(Duration(milliseconds: delayMs), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant FadeSlideTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _controller.reset();
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
