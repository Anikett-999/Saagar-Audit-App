import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:saagar_audit_app/utils/app_date_format.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  group('AppDateFormat Unit Tests (Item 25 - Client Ref F07)', () {
    test('1. Null and empty inputs return fallback cleanly', () {
      expect(AppDateFormat.toLocalDateTime(null), isNull);
      expect(AppDateFormat.toLocalDateTime(''), isNull);
      expect(AppDateFormat.toLocalDateTime('   '), isNull);
      expect(AppDateFormat.formatDateTime(null), equals('—'));
      expect(AppDateFormat.formatDateTime('', fallback: 'N/A'), equals('N/A'));
      expect(AppDateFormat.formatTime(null), equals('—'));
      expect(AppDateFormat.formatDate(null), equals('—'));
      expect(AppDateFormat.formatDateIso(null), equals('—'));
    });

    test('2. Converts UTC ISO string to local time (not UTC)', () {
      const utcString = '2026-10-29T15:34:00Z';
      final localDt = AppDateFormat.toLocalDateTime(utcString);
      expect(localDt, isNotNull);
      expect(localDt!.isUtc, isFalse);

      final expectedLocal = DateTime.parse(utcString).toLocal();
      expect(localDt, equals(expectedLocal));
    });

    test('3. Midnight boundary test (Sagar UAT: after midnight verification was on previous day)', () {
      // 19:00 UTC on 24 Oct is 00:30 AM on 25 Oct in IST (+05:30)
      const lateNightUtc = '2026-10-24T19:00:00Z';
      final localDt = AppDateFormat.toLocalDateTime(lateNightUtc);
      final expectedLocal = DateTime.parse(lateNightUtc).toLocal();

      expect(localDt!.day, equals(expectedLocal.day));
      expect(localDt.hour, equals(expectedLocal.hour));

      final formattedDate = AppDateFormat.formatDate(lateNightUtc);
      expect(formattedDate, isNotEmpty);
      expect(formattedDate, isNot(equals('—')));
    });

    test('4. formatDateTime and formatTime produce 12-hour AM/PM format', () {
      final now = DateTime.now();
      final timeStr = AppDateFormat.formatTime(now);
      // Must contain AM or PM
      expect(timeStr.contains('AM') || timeStr.contains('PM'), isTrue);

      final fullStr = AppDateFormat.formatDateTime(now);
      expect(fullStr.contains('AM') || fullStr.contains('PM'), isTrue);
    });

    test('5. formatSyncDateTime formats with dd/MM/yyyy and time', () {
      final dt = DateTime(2026, 10, 29, 21, 4);
      final syncStr = AppDateFormat.formatSyncDateTime(dt);
      expect(syncStr, equals('29/10/2026 09:04 PM'));
    });

    test('6. DateTime object inputs handled directly', () {
      final dt = DateTime.utc(2026, 10, 29, 15, 34);
      final local = AppDateFormat.toLocalDateTime(dt);
      expect(local!.isUtc, isFalse);
      expect(local, equals(dt.toLocal()));
    });
  });
}
