/// ISO 8601 week number calculation and CAP ID utilities.
///
/// Matches Spec §15.5 and §5 S15 (`CAP-YYYY-Wxx-nn`).
int isoWeek(DateTime date) {
  // Algorithm: Thursday in the same week is in the year that owns the week.
  final dayOfYear = int.parse(_dayOfYearStr(date));
  final dow = date.weekday; // 1=Mon..7=Sun
  final week = ((dayOfYear - dow + 10) ~/ 7);
  if (week < 1) {
    return isoWeek(DateTime(date.year - 1, 12, 31));
  }
  if (week > 52) {
    final jan4 = DateTime(date.year + 1, 1, 4);
    final daysToJan4 = jan4.difference(date).inDays;
    if (daysToJan4 <= 3) return 1;
  }
  return week;
}

String _dayOfYearStr(DateTime d) {
  final firstDay = DateTime(d.year, 1, 1);
  return (d.difference(firstDay).inDays + 1).toString();
}

/// Formats a CAP ID given year, ISO week, and sequence number.
/// Example: `formatCapId(year: 2026, week: 39, sequence: 1)` -> `"CAP-2026-W39-01"`
String formatCapId({
  required int year,
  required int week,
  required int sequence,
}) {
  final weekStr = week.toString().padLeft(2, '0');
  final seqStr = sequence.toString().padLeft(2, '0');
  return 'CAP-$year-W$weekStr-$seqStr';
}
