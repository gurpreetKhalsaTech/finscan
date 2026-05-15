import 'package:flutter_test/flutter_test.dart';
import 'package:finscan/features/passbook_scanner/domain/parsers/passbook_parser.dart';

void main() {
  group('PassbookParser', () {

    // ── Real SBI passbook (from actual scan IMG_6551) ───────────

    group('Real SBI passbook — CIF vs Account Number', () {
      // This is the EXACT layout from the scanned SBI passbook.
      // CIF = 81154707486 (11 digits), Account No = 11412952622 (11 digits)
      // The bug was: parser returned CIF because it appeared first in text.
      const rawOcr = '''
STATE BANK OF INDIA
Branch: JHOKE MORHE
VILL JHOKE MORHE ; PO JHOKE TE
Email: sbi:05576@sbi.co.in
Phone No SBIN0005576
BUSS Hrs:10:00-16:00:00
MICR: 152002131

Name        : SUBA SINGH, GURPREET SINGH
S/D/H/o     : SOHAN SINGH
CIF Number  : 81154707486
Account No. : 11412952622
A/c Type    : REGULAR SAVINGS BANK ACCOUNT
Address     : S/O SOHAN SINGH VILL BURJ MAKHAN SINGH
                PO CHAK HARAJ FEROZEPORE

MOP: EITHER OR SURVIVOR
A/c Opening Dt: 30/04/2005
Customer's PAN: HINPS5614A
Date of Issue: 21/09/2023
''';

      late final result = PassbookParser.parsePassbook(rawOcr);

      test('extracts account number (NOT CIF)', () {
        // Must be 11412952622, NOT 81154707486 (CIF)
        expect(result.accountNumber, equals('11412952622'));
      });

      test('does NOT return CIF as account number', () {
        expect(result.accountNumber, isNot(equals('81154707486')));
      });

      test('extracts primary name (before comma)', () {
        // "SUBA SINGH, GURPREET SINGH" → primary holder is "SUBA SINGH"
        expect(result.accountHolderName, equals('SUBA SINGH'));
      });

      test('extracts IFSC correctly', () {
        expect(result.ifscCode, equals('SBIN0005576'));
      });

      test('extracts MICR correctly', () {
        expect(result.micrCode, equals('152002131'));
      });

      test('does NOT confuse MICR with account number', () {
        expect(result.accountNumber, isNot(equals('152002131')));
      });

      test('identifies bank as SBI', () {
        expect(result.bankName, equals('STATE BANK OF INDIA'));
      });

      test('hasAnyData is true', () {
        expect(result.hasAnyData, isTrue);
      });
    });

    // ── HDFC passbook ──────────────────────────────────────────

    group('HDFC Bank passbook', () {
      const rawOcr = '''
HDFC BANK LIMITED
ACCOUNT PASSBOOK
Name: PRIYA MEHTA
Account No: 50100123456789
IFSC Code: HDFC0001234
Branch: Connaught Place, Delhi
''';

      late final result = PassbookParser.parsePassbook(rawOcr);

      test('extracts account number', () {
        expect(result.accountNumber, equals('50100123456789'));
      });

      test('extracts name', () {
        expect(result.accountHolderName, equals('PRIYA MEHTA'));
      });

      test('extracts IFSC', () {
        expect(result.ifscCode, equals('HDFC0001234'));
      });
    });

    // ── Multiple numbers in text ───────────────────────────────

    group('Multiple numbers — correctly picks account number', () {
      const rawOcr = '''
STATE BANK OF INDIA
Branch Code  : 001234
Phone        : 011-26100000
Account No   : 1234567890
Page No      : 001
IFSC         : SBIN0001234
Pin Code     : 110001
MICR         : 110002006
CIF          : 12345678901
''';

      late final result = PassbookParser.parsePassbook(rawOcr);

      test('picks correct account number 1234567890', () {
        expect(result.accountNumber, equals('1234567890'));
      });

      test('does not return PIN code 110001', () {
        expect(result.accountNumber, isNot(equals('110001')));
      });

      test('does not return branch code 001234', () {
        expect(result.accountNumber, isNot(equals('001234')));
      });

      test('does not return CIF 12345678901', () {
        expect(result.accountNumber, isNot(equals('12345678901')));
      });

      test('extracts IFSC correctly', () {
        expect(result.ifscCode, equals('SBIN0001234'));
      });
    });

    // ── IFSC on OCR-corrected text ─────────────────────────────

    group('IFSC extraction — must use original text', () {
      test('extracts SBIN IFSC before OCR digit correction', () {
        // If O→0 fix ran first, SBIN0005576 would be unaffected (no O here)
        // But HDFC → HD FC (fine), ICIC → ICIC (fine)
        // Edge case: if OCR misread gives 'SBIN00O5576' — O in wrong place
        const rawOcr = '''
IFSC: SBIN0005576
Account No: 12345678901
''';
        final result = PassbookParser.parsePassbook(rawOcr);
        expect(result.ifscCode, equals('SBIN0005576'));
      });
    });

    // ── Name cleaning ──────────────────────────────────────────

    group('Name extraction edge cases', () {
      test('removes S/O suffix from name', () {
        const rawOcr = '''
Name: GURPREET SINGH S/O SOHAN SINGH
Account No: 12345678901
IFSC: SBIN0001234
''';
        final result = PassbookParser.parsePassbook(rawOcr);
        expect(result.accountHolderName, equals('GURPREET SINGH'));
      });

      test('handles comma-separated joint account names', () {
        const rawOcr = '''
Name: SUBA SINGH, GURPREET SINGH
Account No: 11412952622
IFSC: SBIN0005576
''';
        final result = PassbookParser.parsePassbook(rawOcr);
        // Primary holder is the first name
        expect(result.accountHolderName, equals('SUBA SINGH'));
      });
    });

    // ── Edge cases ─────────────────────────────────────────────

    group('Edge cases', () {
      test('empty string returns empty BankDetails', () {
        final r = PassbookParser.parsePassbook('');
        expect(r.hasAnyData, isFalse);
      });

      test('text with no numbers returns null account number', () {
        final r = PassbookParser.parsePassbook('HELLO WORLD NO NUMBERS HERE');
        expect(r.accountNumber, isNull);
      });

      test('returns null for missing IFSC', () {
        final r = PassbookParser.parsePassbook('Account No: 12345678901');
        expect(r.ifscCode, isNull);
      });
    });
  });
}