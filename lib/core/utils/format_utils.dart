/// Formatting utilities for Vietnamese currency, dates, and relative timestamps
/// per SRS and AGENTS.md guidelines.
class FormatUtils {
  FormatUtils._();

  /// Formats a single numeric amount to Vietnamese Dong string with thousand dot separators.
  /// Example: `15000000` -> `15.000.000 VNĐ`
  static String formatVND(num amount) {
    final intAmount = amount.round();
    final buffer = StringBuffer();
    final str = intAmount.abs().toString();
    final length = str.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }

    final prefix = intAmount < 0 ? '-' : '';
    return '$prefix$buffer VNĐ';
  }

  /// Formats salary range into user-friendly Vietnamese text.
  /// Examples:
  /// - `min = 15_000_000, max = 25_000_000` -> `15.000.000 - 25.000.000 VNĐ`
  /// - `min = 20_000_000, max = null` -> `Từ 20.000.000 VNĐ`
  /// - `min = null, max = 30_000_000` -> `Tới 30.000.000 VNĐ`
  /// - `isNegotiable = true` or both null -> `Thỏa thuận`
  static String formatSalaryRange({
    num? min,
    num? max,
    bool isNegotiable = false,
  }) {
    if (isNegotiable || (min == null && max == null)) {
      return 'Thỏa thuận';
    }

    if (min != null && max != null) {
      if (min == max) {
        return formatVND(min);
      }
      return '${formatNumber(min)} - ${formatVND(max)}';
    }

    if (min != null) {
      return 'Từ ${formatVND(min)}';
    }

    return 'Tới ${formatVND(max!)}';
  }

  /// Formats a number with dot thousand separators (without currency symbol)
  static String formatNumber(num number) {
    final intNumber = number.round();
    final buffer = StringBuffer();
    final str = intNumber.abs().toString();
    final length = str.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }

    final prefix = intNumber < 0 ? '-' : '';
    return '$prefix$buffer';
  }

  /// Formats relative time in Vietnamese.
  /// Examples:
  /// - Under 1 minute: `Vừa xong`
  /// - Under 1 hour: `15 phút trước`
  /// - Under 24 hours: `3 giờ trước`
  /// - Under 30 days: `2 ngày trước`
  /// - Older: `dd/MM/yyyy`
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'Vừa xong';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    }

    if (difference.inDays < 30) {
      return '${difference.inDays} ngày trước';
    }

    return formatDate(dateTime);
  }

  /// Formats a [DateTime] into standard Vietnamese `dd/MM/yyyy` format.
  static String formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    return '$day/$month/$year';
  }
}
