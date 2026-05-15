import 'package:flutter_test/flutter_test.dart';
import 'package:finscan/features/card_scanner/domain/parsers/card_parser.dart';

void main() {
  group('CardParser', () {

    // ── Happy path ──────────────────────────────────────────────

    group('Standard Visa card', () {
      const rawOcr = '''
VISA PLATINUM
4111 1111 1111 1111
VALID THRU 12/27
RAHUL SHARMA
CONTACTLESS
''';

      late final result = CardParser.parseCard(rawOcr);

      test('extracts card number', () {
        expect(result.cardNumber, equals('4111111111111111'));
      });

      test('validates card via Luhn', () {
        expect(result.isValid, isTrue);
      });

      test('extracts expiry', () {
        expect(result.expiryDate, equals('12/27'));
      });

      test('extracts name', () {
        expect(result.cardHolderName, equals('RAHUL SHARMA'));
      });

      test('masks card number correctly', () {
        expect(result.maskedCardNumber, equals('**** **** **** 1111'));
      });
    });

    // ── Real IndusInd card (from actual scan IMG_6550) ──────────

    group('IndusInd card — VALID FROM + VALID THRU both present', () {
      const rawOcr = '''
AUTHORISED SIGNATURE  NOT VALID UNLESS SIGNED
24 Hour Customer Service: 1860 267 7777 / 022 4220 7777
4147 5249 8042 3995
VALID FROM 03/22  VALID THRU 03/27
SBF000920122
618
''';

      late final result = CardParser.parseCard(rawOcr);

      test('extracts correct card number', () {
        expect(result.cardNumber, equals('4147524980423995'));
      });

      test('picks VALID THRU (03/27) not VALID FROM (03/22)', () {
        expect(result.expiryDate, equals('03/27'));
      });

      test('does not confuse CVV 618 as card number', () {
        expect(result.cardNumber, isNot(equals('618')));
      });

      test('does not confuse toll-free 1860 as card number', () {
        expect(result.cardNumber, isNot(contains('1860')));
      });
    });

    // ── IndusInd card face noise ────────────────────────────────

    group('IndusInd card — MY ACCOUNT MY NUMBER noise', () {
      const rawOcr = '''
Debit Card  IndusInd Bank
4213 2425 0238 0598
VALID FROM 01/21  VALID THRU 06/26
MY ACCOUNT MY NUMBER
VISA
''';

      late final result = CardParser.parseCard(rawOcr);

      test('extracts card number', () {
        expect(result.cardNumber, equals('4213242502380598'));
      });

      test('does NOT extract MY ACCOUNT MY NUMBER as name', () {
        expect(result.cardHolderName, isNot(equals('MY ACCOUNT MY NUMBER')));
        expect(result.cardHolderName, isNull);
      });

      test('picks VALID THRU 06/26, not VALID FROM 01/21', () {
        expect(result.expiryDate, equals('06/26'));
      });
    });

    // ── IndusInd Legend — name only on front ───────────────────

    group('IndusInd Legend — name GURPREET SINGH, no number on front', () {
      const rawOcr = '''
LEGEND
IndusInd Bank
GURPREET SINGH
VISA Signature
''';

      late final result = CardParser.parseCard(rawOcr);

      test('extracts name correctly', () {
        expect(result.cardHolderName, equals('GURPREET SINGH'));
      });

      test('hasAnyData is true (name was found)', () {
        expect(result.hasAnyData, isTrue);
      });
    });

    // ── Amex 15-digit ──────────────────────────────────────────

    group('Amex 15-digit card', () {
      const rawOcr = '''
AMERICAN EXPRESS
3714 496353 98431
EXP 11/28
MR ANKIT VERMA
''';

      late final result = CardParser.parseCard(rawOcr);

      test('extracts 15-digit Amex number', () {
        expect(result.cardNumber, equals('371449635398431'));
      });

      test('validates Amex via Luhn', () {
        expect(result.isValid, isTrue);
      });

      test('extracts expiry with EXP label', () {
        expect(result.expiryDate, equals('11/28'));
      });
    });

    // ── OCR noise correction ────────────────────────────────────

    group('OCR misread correction', () {
      test('corrects O→0 in card number', () {
        const rawOcr = 'VISA\n411l 1111 1111 1111\n12/27\nRAHUL SHARMA';
        final result = CardParser.parseCard(rawOcr);
        expect(result.cardNumber, equals('4111111111111111'));
      });
    });

    // ── Expiry format variants ──────────────────────────────────

    group('Expiry format variants', () {
      test('handles MM-YY format', () {
        final r = CardParser.parseCard('4111111111111111\n12-27\nRAHUL');
        expect(r.expiryDate, equals('12/27'));
      });

      test('handles MMYY no separator', () {
        final r = CardParser.parseCard('4111111111111111\n1227\nRAHUL');
        expect(r.expiryDate, equals('12/27'));
      });

      test('handles MM/YYYY 4-digit year', () {
        final r = CardParser.parseCard('4111111111111111\n12/2027\nRAHUL');
        expect(r.expiryDate, equals('12/27'));
      });
    });

    // ── Edge cases ─────────────────────────────────────────────

    group('Edge cases', () {
      test('empty string returns empty CardDetails', () {
        final r = CardParser.parseCard('');
        expect(r.hasAnyData, isFalse);
      });

      test('whitespace only returns empty CardDetails', () {
        final r = CardParser.parseCard('   \n  \t  ');
        expect(r.hasAnyData, isFalse);
      });

      test('no card number found — hasCardNumber is false', () {
        final r = CardParser.parseCard('VISA\n12/27\nRAHUL SHARMA');
        expect(r.hasCardNumber, isFalse);
      });

      test('invalid card number — isValid is false', () {
        final r = CardParser.parseCard('1234567890123456\n12/27\nRAHUL');
        expect(r.isValid, isFalse);
      });
    });
  });
}