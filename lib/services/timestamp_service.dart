class TimestampService {
  TimestampService();

  static DateTime? fromMap(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  static String formatLastUpdated(String pretext, DateTime? dateTime) =>
      dateTime != null
          ? '$pretext ${formatTimeAgo(
              dateTime,
              useShortFormat: true,
              usePlural: false,
            )}'
          : 'Never edited';

  /// Formats a DateTime as a "time ago" string (e.g., "5 minutes ago", "2 hours ago")
  ///
  /// [dateTime] The past DateTime to compare with now
  /// [useShortFormat] If true, uses abbreviated format (e.g., "5m ago" instead of "5 minutes ago")
  /// [usePlural] If true, uses plural forms (e.g., "minutes" vs "minute")
  /// [daysOnly] If true, rounds to days only - shows "Today" for < 1 day, "X days ago" otherwise
  static String formatTimeAgo(
    DateTime? dateTime, {
    bool useShortFormat = false,
    bool usePlural = true,
    bool daysOnly = false,
  }) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Handle daysOnly mode
    if (daysOnly) {
      if (difference.inDays < 1) {
        return 'Today';
      } else {
        final days = difference.inDays;
        return '$days ${days == 1 ? 'day' : 'days'} ago';
      }
    }

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      if (useShortFormat) {
        return '${minutes}m ago';
      } else if (usePlural) {
        return '$minutes min ago';
      } else {
        return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
      }
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      if (useShortFormat) {
        return '${hours}h ago';
      } else if (usePlural) {
        return '$hours hours ago';
      } else {
        return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
      }
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      if (useShortFormat) {
        return '${days}d ago';
      } else if (usePlural) {
        return '$days days ago';
      } else {
        return '$days ${days == 1 ? 'day' : 'days'} ago';
      }
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      if (useShortFormat) {
        return '${weeks}w ago';
      } else if (usePlural) {
        return '$weeks weeks ago';
      } else {
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      }
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      if (useShortFormat) {
        return '${months}mo ago';
      } else {
        return '$months months ago';
      }
    } else {
      final years = (difference.inDays / 365).floor();
      if (useShortFormat) {
        return '${years}y ago';
      } else {
        return '$years years ago';
      }
    }
  }
}
