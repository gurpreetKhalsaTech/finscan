import 'package:flutter_test/flutter_test.dart';
import 'package:finscan/features/card_scanner/domain/parsers/luhn_validator.dart';

void main() {
  group('LuhnValidator.isValid', () {
    test('returns true for a known valid number', () {
      expect(LuhnValidator.isValid('4532015112830366'), isTrue);
      expect(LuhnValidator.isValid('5500005555555559'), isTrue);
    });

    test('returns false for an invalid number', () {
      expect(LuhnValidator.isValid('1234567890123456'), isFalse);
    });

    test('returns false for empty string', () {
      expect(LuhnValidator.isValid(''), isFalse);
    });

    test('handles spaces and dashes gracefully', () {
      expect(LuhnValidator.isValid('4532-0151-1283-0366'), isTrue);
      expect(LuhnValidator.isValid('4532 0151 1283 0366'), isTrue);
    });
  });
}