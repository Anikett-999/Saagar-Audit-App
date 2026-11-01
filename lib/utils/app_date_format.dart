import 'package:intl/intl.dart';

/// Centralized Date and Time formatting utility for Saagar Audit App.
/// Guarantees that any timestamp (whether UTC ISO string, local ISO string, or DateTime)
/// is always parsed and converted to device Local / Indian Standard Time (IST).
class AppDateFormat {
  AppDateFormat._();

  /// Converts any ISO-8601 string or [DateTime] to a local [DateTime].
  /// Returns null if [input] is null or unparseable.
  static DateTime? toLocalDateTime(dynamic input) {
    if (input == null) return null;
    if (input is DateTime) return input.toLocal();
    if (input is String) {
      final trimmed = input.trim();
      if (trimmed.isEmpty) return null;
      final parsed = DateTime.tryParse(trimmed);
      return parsed?.toLocal();
    }
    return null;
  }

  /// Formats date and time: e.g. "29 Oct 2026, 09:14 PM"
  static String formatDateTime(dynamic input, {String fallback = '—'}) {
    final dt = toLocalDateTime(input);
    if (dt == null) return fallback;
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  /// Formats time only with 12-hour AM/PM: e.g. "09:14 PM"
  static String formatTime(dynamic input, {String fallback = '—'}) {
    final dt = toLocalDateTime(input);
    if (dt == null) return fallback;
    return DateFormat('hh:mm a').format(dt);
  }

  /// Formats date only: e.g. "29 Oct 2026"
  static String formatDate(dynamic input, {String fallback = '—'}) {
    final dt = toLocalDateTime(input);
    if (dt == null) return fallback;
    return DateFormat('dd MMM yyyy').format(dt);
  }

  /// Formats numeric date in local time: e.g. "2026-10-29"
  static String formatDateIso(dynamic input, {String fallback = '—'}) {
    final dt = toLocalDateTime(input);
    if (dt == null) return fallback;
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  /// Formats day/month/year with time for sync & backup: e.g. "29/10/2026 09:14 PM"
  static String formatSyncDateTime(dynamic input, {String fallback = '—'}) {
    final dt = toLocalDateTime(input);
    if (dt == null) return fallback;
    return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
  }
}
