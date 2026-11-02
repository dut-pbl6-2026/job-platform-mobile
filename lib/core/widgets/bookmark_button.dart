import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable animated bookmark button with an elastic bounce micro-interaction.
///
/// When the user taps to save, smoothly switches the icon to a filled blue style
/// with a bounce effect powered by [AnimatedScale] with [Curves.elasticOut].
class BookmarkButton extends StatefulWidget {
  final bool isSaved;
  final VoidCallback? onToggle;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const BookmarkButton({
    super.key,
    required this.isSaved,
    this.onToggle,
    this.size = 22,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton> {
  late bool _isSaved;
  double _scale = 1.0;
  Timer? _bounceTimer;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isSaved;
  }

  @override
  void didUpdateWidget(covariant BookmarkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSaved != oldWidget.isSaved) {
      final wasSaved = _isSaved;
      _isSaved = widget.isSaved;
      if (!wasSaved && _isSaved) {
        _triggerBounce();
      }
    }
  }

  @override
  void dispose() {
    _bounceTimer?.cancel();
    super.dispose();
  }

  void _triggerBounce() {
    _bounceTimer?.cancel();
    setState(() => _scale = 1.35);
    _bounceTimer = Timer(const Duration(milliseconds: 140), () {
      if (mounted) {
        setState(() => _scale = 1.0);
      }
    });
  }

  void _handleTap() {
    setState(() {
      _isSaved = !_isSaved;
      if (_isSaved) {
        _triggerBounce();
      }
    });
    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activeColor ?? AppColors.primary;
    final inactive = widget.inactiveColor ?? AppColors.textHint;

    return IconButton(
      icon: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 320),
        curve: Curves.elasticOut,
        child: Icon(
          _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: _isSaved ? active : inactive,
          size: widget.size,
        ),
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      visualDensity: VisualDensity.compact,
      tooltip: _isSaved ? 'Bỏ lưu tin' : 'Lưu tin tuyển dụng',
      onPressed: widget.onToggle != null ? _handleTap : null,
    );
  }
}
