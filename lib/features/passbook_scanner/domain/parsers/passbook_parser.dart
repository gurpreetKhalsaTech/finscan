import '../../data/models/bank_details.dart';
import '../../../../core/constants/regex_patterns.dart';
import '../../../../core/utils/string_utils.dart';

class PassbookParser {
  PassbookParser._();

  static BankDetails? parsePassbook(String rawText) {
    // IFSC must be searched in the ORIGINAL text — OCR correction (S→5, B→8, I→1)
    // would destroy the alphabetic prefix (e.g. SBIN → 581N).
    final ifscMatch = RegexPatterns.ifscCode.firstMatch(rawText);

    // Numeric fields benefit from OCR correction (O→0, I→1, etc.)
    final corrected = StringUtils.fixOcrNumericErrors(rawText);
    final account = _extractAccountNumber(corrected);

    if (ifscMatch == null && account.isEmpty) return null;

    final ifsc = ifscMatch?.group(0) ?? '';

    final micrMatch = RegexPatterns.micrCode.firstMatch(corrected);
    // Avoid returning the IFSC's embedded zeros block as MICR
    final micr = (micrMatch?.group(0) != null && micrMatch!.group(0) != account)
        ? micrMatch.group(0)
        : null;

    return BankDetails(
      accountNumber: account,
      ifscCode: ifsc,
      micrCode: micr,
      bankName: _extractBankName(rawText),
      branchName: _extractBranchName(rawText),
      accountHolderName: _extractHolderName(rawText),
    );
  }

  // Prefers explicitly labeled account numbers; falls back to the longest
  // numeric candidate in the 9–18 digit range that isn't a pure MICR code.
  static String _extractAccountNumber(String text) {
    // 1. Labeled match (highest confidence)
    final labeled = RegexPatterns.labeledAccountNumber.firstMatch(text);
    if (labeled != null) return labeled.group(1)!;

    // 2. Collect all candidates in the 9–18 digit range
    final candidates = RegexPatterns.accountNumber
        .allMatches(text)
        .map((m) => m.group(0)!)
        .where((n) => n.length >= 9 && n.length <= 18)
        .toList();

    if (candidates.isEmpty) return '';

    // Prefer longer numbers (account numbers tend to be longer than MICR)
    candidates.sort((a, b) => b.length.compareTo(a.length));
    return candidates.first;
  }

  static String? _extractBankName(String text) {
    const bankKeywords = [
      'STATE BANK OF INDIA',
      'STATE BANK',
      'HDFC BANK',
      'HDFC',
      'ICICI BANK',
      'ICICI',
      'AXIS BANK',
      'AXIS',
      'PUNJAB NATIONAL BANK',
      'PUNJAB NATIONAL',
      'CANARA BANK',
      'CANARA',
      'UNION BANK',
      'KOTAK MAHINDRA',
      'KOTAK',
      'YES BANK',
      'BANK OF BARODA',
      'BANK OF INDIA',
      'INDIAN BANK',
    ];
    final upper = text.toUpperCase();
    for (final keyword in bankKeywords) {
      if (upper.contains(keyword)) return keyword;
    }
    return null;
  }

  static String? _extractBranchName(String text) {
    final match = RegExp(r'BRANCH[:\s]+([A-Za-z ]+)', caseSensitive: false).firstMatch(text);
    return match?.group(1)?.trim();
  }

  static String? _extractHolderName(String text) {
    // Try explicit label first
    final labeled = RegExp(
      r'(?:NAME|A\/C\s*NAME|ACCOUNT\s*NAME|ACCOUNT\s*HOLDER)[:\s]+([A-Za-z ]{2,40})',
      caseSensitive: false,
    ).firstMatch(text);
    if (labeled != null) return labeled.group(1)?.trim();

    // Fallback: look for an ALL-CAPS line that looks like a personal name
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (RegExp(r'^[A-Z][A-Z ]{4,39}$').hasMatch(trimmed) &&
          !_isBankKeyword(trimmed)) {
        return trimmed;
      }
    }
    return null;
  }

  static bool _isBankKeyword(String line) {
    const skipWords = ['BRANCH', 'BANK', 'PASSBOOK', 'SAVINGS', 'CURRENT', 'ACCOUNT', 'IFSC'];
    return skipWords.any((w) => line.contains(w));
  }
}