import 'package:flutter_test/flutter_test.dart';
import 'package:finscan/features/card_scanner/domain/parsers/luhn_validator.dart';

void main() {
  group('LuhnValidator', () {
    group('isValid — known valid numbers', () {
      test('Visa test number 4111111111111111', () {
        expect(LuhnValidator.isValid('4111111111111111'), isTrue);
      });

      test('Mastercard test number 5500000000000004', () {
        expect(LuhnValidator.isValid('5500000000000004'), isTrue);
      });

      test('Amex test number 371449635398431 (15-digit)', () {
        expect(LuhnValidator.isValid('371449635398431'), isTrue);
      });

      test('Visa test number with spaces stripped 4111 1111 1111 1111', () {
        expect(LuhnValidator.isValid('4111 1111 1111 1111'), isTrue);
      });

      // Real card from scan — IndusInd
      test('IndusInd real card 4147524980423995', () {
        expect(LuhnValidator.isValid('4147524980423995'), isTrue);
      });
    });

    group('isValid — invalid numbers', () {
      test('Random 16-digit fails Luhn', () {
        expect(LuhnValidator.isValid('1234567890123456'), isFalse);
      });

      test('All zeros fails Luhn', () {
        expect(LuhnValidator.isValid('0000000000000000'), isFalse);
      });

      test('Empty string returns false', () {
        expect(LuhnValidator.isValid(''), isFalse);
      });

      test('Single digit 0 returns false', () {
        expect(LuhnValidator.isValid('0'), isFalse);
      });

      test('Non-numeric string returns false', () {
        expect(LuhnValidator.isValid('abcdefghijklmnop'), isFalse);
      });

      test('Card number off by 1 digit fails', () {
        // 4111111111111112 — last digit changed from 1 to 2
        expect(LuhnValidator.isValid('4111111111111112'), isFalse);
      });
    });

    group('calculateCheckDigit', () {
      test('Check digit for 411111111111111 (15 digits) = 1', () {
        expect(LuhnValidator.calculateCheckDigit('411111111111111'), equals(1));
      });
    });
  });
}