import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/data/repositories/reference_repository.dart';
import 'package:saagar_audit_app/domain/score_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReferenceRepository repo;

  setUp(() {
    repo = ReferenceRepository.instance;
    repo.clearCache();
  });

  group('ReferenceRepository — Rating Scale Asset (S23 / Appendix A.4)', () {
    test('loads and parses rating_scale.json correctly with 5 bands and 3 targets',
        () async {
      final scale = await repo.loadRatingScale();

      expect(scale.bands.length, equals(5));
      expect(scale.tierTargets.length, equals(3));
      expect(scale.reminder.textEn, contains('89.9 is FAIR, not Good'));
      expect(scale.reminder.textMr, contains('८९.९ बरे आहे'));
    });

    test('compliance bands strictly mirror the domain score engine cutoffs',
        () async {
      final scale = await repo.loadRatingScale();
      final bandIds = scale.bands.map((b) => b.id).toList();

      expect(
        bandIds,
        equals(['excellent', 'good', 'fair', 'poor', 'critical']),
      );

      final excellent = scale.bands.firstWhere((b) => b.id == 'excellent');
      final good = scale.bands.firstWhere((b) => b.id == 'good');
      final fair = scale.bands.firstWhere((b) => b.id == 'fair');
      final poor = scale.bands.firstWhere((b) => b.id == 'poor');
      final critical = scale.bands.firstWhere((b) => b.id == 'critical');

      // Canonical cutoffs matching domain/score_engine.dart
      expect(excellent.minPercentage, equals(95.0));
      expect(good.minPercentage, equals(90.0));
      expect(fair.minPercentage, equals(85.0));
      expect(poor.minPercentage, equals(80.0));
      expect(critical.minPercentage, equals(0.0));
      expect(critical.maxPercentage, equals(79.9));

      // Test that score engine classification matches the JSON metadata
      expect(bandFromCompliance(95.0), equals(Band.excellent));
      expect(bandFromCompliance(94.9), equals(Band.good));
      expect(bandFromCompliance(90.0), equals(Band.good));
      expect(bandFromCompliance(89.9), equals(Band.fair));
      expect(bandFromCompliance(85.0), equals(Band.fair));
      expect(bandFromCompliance(84.9), equals(Band.poor));
      expect(bandFromCompliance(80.0), equals(Band.poor));
      expect(bandFromCompliance(79.9), equals(Band.critical));
    });

    test('tier targets reflect Tier 1 daily (90%+, 81/90 pts) preserving canonical invariant',
        () async {
      final scale = await repo.loadRatingScale();
      final tier1 = scale.tierTargets.firstWhere(
        (t) => t.tierEn.contains('Tier 1'),
      );

      expect(tier1.targetPctEn, equals('90%+'));
      expect(tier1.totalPointsEn, equals('90 weighted'));
      expect(tier1.passPointsEn, equals('81+ weighted'));
      expect(tier1.auditorEn, equals('Store Manager'));
      expect(tier1.auditor('mr'), equals('स्टोअर मॅनेजर'));
    });

    test('compliance band localized helpers return correct language string',
        () async {
      final scale = await repo.loadRatingScale();
      final good = scale.bands.firstWhere((b) => b.id == 'good');

      expect(good.name('en'), equals('GOOD'));
      expect(good.name('mr'), equals('चांगले'));
      expect(good.action('en'), contains('Note minor fixes'));
      expect(good.action('mr'), contains('किरकोळ सुधारणा'));
      expect(good.whoActs('en'), contains('SM verbal'));
      expect(good.whoActs('mr'), contains('SM तोंडी चर्चा'));
    });
  });

  group('ReferenceRepository — Escalation Triggers Asset (S24 / Appendix A.5)', () {
    test('loads and parses escalation_triggers.json with 7 triggers', () async {
      final triggers = await repo.loadEscalationTriggers();

      expect(triggers.triggers.length, equals(7));
      expect(
        triggers.triggers.map((t) => t.number).toList(),
        equals([1, 2, 3, 4, 5, 6, 7]),
      );

      final t1 = triggers.triggers[0];
      expect(t1.nameEn, equals('Daily audit Critical band'));
      expect(t1.thresholdEn, equals('< 80%'));
      expect(t1.escalateToEn, equals('GM (Owner if Cash/Inv)'));
      expect(t1.whenEn, equals('Same night'));

      final t3 = triggers.triggers[2];
      expect(t3.nameEn, equals('Single-day cash variance'));
      expect(t3.thresholdEn, equals('> ₹500'));
      expect(t3.when('mr'), equals('त्याच दिवशी'));
    });

    test('contains 4-part message format and never-escalates guidelines',
        () async {
      final data = await repo.loadEscalationTriggers();

      expect(data.messageFormat.parts.length, equals(4));
      expect(data.messageFormat.parts[0].titleEn, equals('What happened'));
      expect(data.messageFormat.parts[1].titleEn, equals('Evidence'));
      expect(data.messageFormat.parts[2].titleEn, equals('Operational impact'));
      expect(data.messageFormat.parts[3].titleEn, equals('Requested action'));

      expect(data.neverEscalates.items.length, equals(3));
      expect(data.neverEscalates.items[0].en, contains('Single-checkpoint Fails'));
    });

    test('contains 3 worked example messages for triggers 1, 3, and 5', () async {
      final data = await repo.loadEscalationTriggers();

      expect(data.examples.length, equals(3));
      expect(data.examples.map((e) => e.triggerNumber).toList(), equals([1, 3, 5]));

      final ex1 = data.examples.firstWhere((e) => e.triggerNumber == 1);
      expect(ex1.titleEn, contains('Trigger 1'));
      expect(ex1.whatHappened('en'), contains('78.2%'));
      expect(ex1.whatHappened('mr'), contains('७८.२%'));

      final ex3 = data.examples.firstWhere((e) => e.triggerNumber == 3);
      expect(ex3.titleEn, contains('Trigger 3'));
      expect(ex3.whatHappened('en'), contains('₹850'));

      final ex5 = data.examples.firstWhere((e) => e.triggerNumber == 5);
      expect(ex5.titleEn, contains('Trigger 5'));
      expect(ex5.impact('en'), contains('₹32,000'));
    });
  });

  group('ReferenceRepository — Evidence Guide Asset (S25 / Appendix A.6)', () {
    test('loads and parses evidence.json with exactly 8 strong/weak pairs',
        () async {
      final guide = await repo.loadEvidenceGuide();

      expect(guide.pairs.length, equals(8));
      expect(guide.pairs[0].strongEn, contains('Photographs with timestamp'));
      expect(guide.pairs[0].weakEn, contains('Photographs without timestamp'));

      expect(guide.warningBanner.textEn, contains('Every finding must rest on the left column'));
      expect(guide.warningBanner.textMr, contains('प्रत्येक निष्कर्ष डाव्या स्तंभावर विसावला पाहिजे'));
    });

    test('evidence pairs provide localized accessors for EN and MR', () async {
      final guide = await repo.loadEvidenceGuide();
      final pair1 = guide.pairs.first;

      expect(pair1.strong('en'), contains('Photographs with timestamp'));
      expect(pair1.strong('mr'), contains('वेळ-शिक्क्यासह फोटो'));
      expect(pair1.weak('en'), contains('Photographs without timestamp'));
      expect(pair1.weak('mr'), contains('वेळ-शिक्क्याशिवायचे फोटो'));
    });
  });

  group('ReferenceRepository — Glossary Asset & Search (S26 / Appendix A.7)', () {
    test('loads exactly 65 bilingual glossary entries with non-empty fields',
        () async {
      final glossary = await repo.loadGlossary();

      expect(glossary.length, equals(65));
      for (final entry in glossary) {
        expect(entry.en.trim(), isNotEmpty, reason: 'Entry EN cannot be empty');
        expect(entry.mr.trim(), isNotEmpty, reason: 'Entry MR cannot be empty');
        expect(
          entry.meaningEn.trim(),
          isNotEmpty,
          reason: 'Entry meaningEn cannot be empty for ${entry.en}',
        );
        expect(
          entry.meaningMr.trim(),
          isNotEmpty,
          reason: 'Entry meaningMr cannot be empty for ${entry.en}',
        );
      }

      // Check first and last entries per Workbook Appendix A.7
      expect(glossary.first.en, equals('Audit'));
      expect(glossary.first.mr, equals('ऑडिट'));
      expect(glossary.last.en, equals('Opening time'));
      expect(glossary.last.mr, equals('उघडण्याची वेळ'));
    });

    test('searchGlossary returns all 65 entries for empty or whitespace query',
        () async {
      final allEmpty = await repo.searchGlossary('');
      final allSpaces = await repo.searchGlossary('   ');

      expect(allEmpty.length, equals(65));
      expect(allSpaces.length, equals(65));
    });

    test('searchGlossary filters correctly by English term (case-insensitive)',
        () async {
      final results = await repo.searchGlossary('audit');

      expect(results.isNotEmpty, isTrue);
      // 'Audit' and 'Auditor' should match
      final terms = results.map((e) => e.en).toList();
      expect(terms, contains('Audit'));
      expect(terms, contains('Auditor'));
    });

    test('searchGlossary filters correctly by Marathi term (Devanagari)',
        () async {
      final results = await repo.searchGlossary('तपासणी बिंदू');

      expect(results.isNotEmpty, isTrue);
      expect(results.any((e) => e.en == 'Checkpoint'), isTrue);
    });

    test('searchGlossary filters by English meaning text', () async {
      final results = await repo.searchGlossary('reconciliation');

      expect(results.isNotEmpty, isTrue);
      final terms = results.map((e) => e.en).toList();
      expect(terms, contains('Reconciliation'));
      expect(terms, contains('Cash reconciliation'));
    });

    test('searchGlossary filters by Marathi meaning text', () async {
      final results = await repo.searchGlossary('ताळमेळ');

      expect(results.isNotEmpty, isTrue);
      final terms = results.map((e) => e.en).toList();
      expect(terms, contains('Reconciliation'));
    });

    test('searchGlossary handles special acronyms: CAP, SOP, FIFO, NPS, DPDP',
        () async {
      final capResults = await repo.searchGlossary('cap');
      expect(capResults.any((e) => e.en == 'CAP'), isTrue);

      final fifoResults = await repo.searchGlossary('fifo');
      expect(fifoResults.any((e) => e.en == 'FIFO'), isTrue);

      final npsResults = await repo.searchGlossary('nps');
      expect(npsResults.any((e) => e.en == 'NPS'), isTrue);

      final dpdpResults = await repo.searchGlossary('dpdp');
      expect(dpdpResults.any((e) => e.en == 'DPDP'), isTrue);
    });

    test('searchGlossary returns empty list when query does not match anything',
        () async {
      final results = await repo.searchGlossary('xyznonexistentquery999');
      expect(results, isEmpty);
    });
  });

  group('ReferenceRepository — In-Memory Caching', () {
    test('subsequent calls return cached objects without reload unless forceReload is true',
        () async {
      final firstLoad = await repo.loadRatingScale();
      final secondLoad = await repo.loadRatingScale();

      expect(identical(firstLoad, secondLoad), isTrue);

      final forceReload = await repo.loadRatingScale(forceReload: true);
      expect(identical(firstLoad, forceReload), isFalse);
    });

    test('clearCache invalidates all in-memory references', () async {
      final firstLoad = await repo.loadGlossary();
      repo.clearCache();
      final reload = await repo.loadGlossary();

      expect(identical(firstLoad, reload), isFalse);
      expect(reload.length, equals(65));
    });
  });
}
