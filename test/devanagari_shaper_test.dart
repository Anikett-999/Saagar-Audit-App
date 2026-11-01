import 'package:flutter_test/flutter_test.dart';
import 'package:saagar_audit_app/utils/devanagari_shaper.dart';

void main() {
  group('DevanagariShaper Tests', () {
    test('Correctly reorders pre-base matra i for single consonants', () {
      expect(DevanagariShaper.shape('विभाग'), equals('िवभाग'));
      expect(DevanagariShaper.shape('साप्ताहिक'), equals('साप्तािहक'));
      expect(DevanagariShaper.shape('मासिक'), equals('मािसक'));
      expect(DevanagariShaper.shape('दैनिक'), equals('दैिनक'));
      expect(DevanagariShaper.shape('ऑडिट'), equals('ऑिडट'));
      expect(DevanagariShaper.shape('ऑडिटर'), equals('ऑिडटर'));
      expect(DevanagariShaper.shape('आणि'), equals('आिण'));
      expect(DevanagariShaper.shape('दिवस'), equals('िदवस'));
      expect(DevanagariShaper.shape('शनि'), equals('शिन'));
      expect(DevanagariShaper.shape('रवि'), equals('रिव'));
    });

    test('Correctly reorders pre-base matra i across conjuncts', () {
      // स्थिति -> ि + स + ् + थ + त + ी
      expect(DevanagariShaper.shape('स्थिती'), equals('िस्थती'));
      // निरीक्षणे -> ि + न + र + ी + क + ् + ष + ण + े
      expect(DevanagariShaper.shape('निरीक्षणे'), equals('िनरीक्षणे'));
      // समाविष्ट -> समा + ि + व + ष + ् + ट
      expect(DevanagariShaper.shape('समाविष्ट'), equals('समािवष्ट'));
    });

    test('Leaves plain English, numbers, and post-base matras unchanged', () {
      expect(DevanagariShaper.shape('Titan World'), equals('Titan World'));
      expect(DevanagariShaper.shape('124 pts - 95.0%'), equals('124 pts - 95.0%'));
      expect(DevanagariShaper.shape('तारीख'), equals('तारीख'));
      expect(DevanagariShaper.shape('नोंदी'), equals('नोंदी'));
      expect(DevanagariShaper.shape(''), equals(''));
      expect(DevanagariShaper.shape(null), equals(''));
    });
  });
}
