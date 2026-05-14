import 'package:flutter_test/flutter_test.dart';
import 'package:finscan/features/passbook_scanner/domain/parsers/passbook_parser.dart';

void main() {
  group('PassbookParser.parsePassbook', () {
    test('returns null when no banking info is present', () {
      final result = PassbookParser.parsePassbook('some random text');
      expect(result, isNull);
    });

    test('parses a valid IFSC code', () {
      const raw = '''
        STATE BANK
        Account No: 123456789012
        IFSC: SBIN0001234
        Branch: Mumbai Main
      ''';
      final result = PassbookParser.parsePassbook(raw);
      expect(result, isNotNull);
      expect(result!.ifscCode, 'SBIN0001234');
      expect(result.accountNumber, '123456789012');
      expect(result.bankName, 'STATE BANK');
    });

    test('extracts account holder name when present', () {
      const raw = '''
        A/C Name: GURPREET SINGH
        Account No: 987654321098
        IFSC: HDFC0002345
      ''';
      final result = PassbookParser.parsePassbook(raw);
      expect(result, isNotNull);
      expect(result!.accountHolderName, 'GURPREET SINGH');
    });

    test('returns details with empty account when only IFSC found', () {
      const raw = 'IFSC: AXIS0001234';
      final result = PassbookParser.parsePassbook(raw);
      expect(result, isNotNull);
      expect(result!.ifscCode, 'AXIS0001234');
    });
  });
}