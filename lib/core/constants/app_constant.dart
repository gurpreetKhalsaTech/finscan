class AppConstants {
  AppConstants._();

  // ── Card ─────────────────────────────────────────────────────
  static const int minCardNumberLength = 13;
  static const int maxCardNumberLength = 19;

  // ── Passbook ─────────────────────────────────────────────────
  static const int micrLength = 9;

  // ── Card noise phrases ────────────────────────────────────────
  /// Phrases that appear on card faces but are NOT cardholder names.
  /// e.g. IndusInd prints "MY ACCOUNT MY NUMBER" on the card face.
  static const List<String> cardNoisePhrases = [
    'MY ACCOUNT MY NUMBER',
    'VISA SIGNATURE',
    'VISA PLATINUM',
    'VISA CLASSIC',
    'MASTERCARD',
    'MASTER CARD',
    'RUPAY',
    'DEBIT CARD',
    'CREDIT CARD',
    'PLATINUM',
    'LEGEND',
    'SIGNATURE',
    'CONTACTLESS',
    'ELECTRONIC USE ONLY',
    'NON TRANSFERABLE',
    'AUTHORISED SIGNATURE',
    'NOT VALID UNLESS SIGNED',
    'VALID FROM',
    'VALID THRU',
    'VALID THROUGH',
    'MEMBER SINCE',
    'GOOD THRU',
  ];
}