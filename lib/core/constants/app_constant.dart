class AppConstants {
  AppConstants._();

  // ── App ───────────────────────────────────────────────────────
  static const String appName = 'FinScan';

  // ── Card ─────────────────────────────────────────────────────
  static const int minCardNumberLength = 13;
  static const int maxCardNumberLength = 19;

  // ── Passbook ─────────────────────────────────────────────────
  // Indian bank account numbers range from 9 to 18 digits.
  // Reference lengths:
  //   SBI=11, HDFC=14, ICICI=12, Axis=15, Kotak=14, PNB=16, BoB=14
  static const int minAccountNumberLength = 9;
  static const int maxAccountNumberLength = 18;

  static const int micrLength = 9;

  // ── Card noise phrases ────────────────────────────────────────
  /// Phrases that appear on card faces but are NOT cardholder names.
  static const List<String> cardNoisePhrases = [
    'MY ACCOUNT MY NUMBER',
    'VISA SIGNATURE',
    'VISA PLATINUM',
    'VISA CLASSIC',
    'VISA INFINITE',
    'MASTERCARD WORLD',
    'MASTERCARD',
    'MASTER CARD',
    'RUPAY',
    'RUPAY SELECT',
    'RUPAY PLATINUM',
    'DEBIT CARD',
    'CREDIT CARD',
    'PREPAID CARD',
    'PLATINUM',
    'LEGEND',
    'SIGNATURE',
    'INFINITE',
    'WORLD',
    'TITANIUM',
    'CONTACTLESS',
    'ELECTRONIC USE ONLY',
    'NON TRANSFERABLE',
    'AUTHORISED SIGNATURE',
    'AUTHORIZED SIGNATURE',
    'NOT VALID UNLESS SIGNED',
    'VALID FROM',
    'VALID THRU',
    'VALID THROUGH',
    'MEMBER SINCE',
    'GOOD THRU',
    'CARD MEMBER SINCE',
    'CUSTOMER SERVICE',
  ];

  // ── Known Indian banks ────────────────────────────────────────
  static const List<String> knownBanks = [
    // Public sector
    'STATE BANK OF INDIA',
    'PUNJAB NATIONAL BANK',
    'BANK OF BARODA',
    'CANARA BANK',
    'UNION BANK OF INDIA',
    'BANK OF INDIA',
    'INDIAN BANK',
    'CENTRAL BANK OF INDIA',
    'UCO BANK',
    'BANK OF MAHARASHTRA',
    'INDIAN OVERSEAS BANK',
    'PUNJAB AND SIND BANK',
    // Private sector
    'HDFC BANK',
    'ICICI BANK',
    'AXIS BANK',
    'KOTAK MAHINDRA BANK',
    'INDUSIND BANK',
    'YES BANK',
    'IDFC FIRST BANK',
    'IDFC BANK',
    'FEDERAL BANK',
    'SOUTH INDIAN BANK',
    'KARNATAKA BANK',
    'KARUR VYSYA BANK',
    'CITY UNION BANK',
    'RBL BANK',
    'BANDHAN BANK',
    'AU SMALL FINANCE BANK',
    'EQUITAS SMALL FINANCE BANK',
    // Foreign
    'CITIBANK',
    'HSBC',
    'STANDARD CHARTERED',
    'DEUTSCHE BANK',
  ];
}