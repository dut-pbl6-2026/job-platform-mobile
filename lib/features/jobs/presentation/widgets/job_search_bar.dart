import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Search input bar with debounce and filter action button (MOB-01-02, SEARCH-01)
class JobSearchBar extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onFilterTap;
  final int activeFilterCount;
  final String hintText;
  final int debounceMs;

  const JobSearchBar({
    super.key,
    this.initialValue = '',
    required this.onChanged,
    this.onSubmitted,
    required this.onFilterTap,
    this.activeFilterCount = 0,
    this.hintText = 'Tìm kiếm công việc, kỹ năng, công ty...',
    this.debounceMs = 350,
  });

  @override
  State<JobSearchBar> createState() => _JobSearchBarState();
}

class _JobSearchBarState extends State<JobSearchBar> {
  late final TextEditingController _textController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant JobSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _textController.text) {
      _textController.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _handleTextChange(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      widget.onChanged(value);
    });
    setState(() {});
  }

  void _clearSearch() {
    _textController.clear();
    _debounceTimer?.cancel();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.isNotEmpty;

    return Row(
      children: [
        // Search text field
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _textController,
              onChanged: _handleTextChange,
              onSubmitted: (val) {
                _debounceTimer?.cancel();
                widget.onSubmitted?.call(val);
                widget.onChanged(val);
              },
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: hasText
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Filter button with badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: widget.onFilterTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.activeFilterCount > 0
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.activeFilterCount > 0
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.activeFilterCount > 0
                          ? AppColors.primary.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.tune_rounded,
                  color: widget.activeFilterCount > 0
                      ? Colors.white
                      : AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
            // Active filter count badge
            if (widget.activeFilterCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.activeFilterCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
