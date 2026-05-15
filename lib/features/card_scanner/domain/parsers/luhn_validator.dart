/// Luhn algorithm validator — implemented manually as required.
///
/// The Luhn algorithm (also known as the "modulus 10" or "mod 10" algorithm)
/// is a checksum formula used to validate credit card numbers.
///
/// Algorithm steps:
///   1. Starting from the rightmost digit (check digit), move left.
///   2. Double every second digit (i.e. digits at even positions from right).
///   3. If doubling produces a number > 9, subtract 9.
///   4. Sum all digits.
///   5. If total mod 10 == 0, the number is valid.
class LuhnValidator {
  LuhnValidator._();

  /// Assignment-spec signature: `bool isValidCard(String cardNumber)`.
  static bool isValidCard(String cardNumber) => isValid(cardNumber);

  /// Returns true if [cardNumber] passes the Luhn check.
  static bool isValid(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) return false;

    int sum = 0;
    bool shouldDouble = false;

    for (int i = digits.length - 1; i >= 0; i--) {
      int digit = int.parse(digits[i]);

      if (shouldDouble) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }

      sum += digit;
      shouldDouble = !shouldDouble;
    }

    return sum % 10 == 0;
  }

  /// Returns the Luhn check digit for a partial number (no check digit appended).
  static int calculateCheckDigit(String partialNumber) {
    final digits = partialNumber.replaceAll(RegExp(r'\D'), '');
    final withZero = '${digits}0';

    int sum = 0;
    bool shouldDouble = false;

    for (int i = withZero.length - 1; i >= 0; i--) {
      int digit = int.parse(withZero[i]);
      if (shouldDouble) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      shouldDouble = !shouldDouble;
    }

    return (10 - (sum % 10)) % 10;
  }
}