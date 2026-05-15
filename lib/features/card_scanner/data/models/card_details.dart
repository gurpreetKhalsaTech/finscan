/// Parsed card data extracted from OCR output.
class CardDetails {
  const CardDetails({
    this.cardNumber,
    this.maskedCardNumber,
    this.expiryDate,
    this.cardHolderName,
    this.bankName,
    this.cardNetwork,
    this.isValid = false,
  });

  /// Raw 16-digit (or 15-digit for Amex) card number string.
  final String? cardNumber;

  /// Masked display string e.g. "**** **** **** 3995"
  final String? maskedCardNumber;

  /// Expiry in normalised "MM/YY" format.
  final String? expiryDate;

  /// Cardholder name as printed on card.
  final String? cardHolderName;

  /// Issuing bank name if detectable.
  final String? bankName;

  /// Card network e.g. "Visa", "Mastercard", "RuPay".
  final String? cardNetwork;

  /// True if cardNumber passes Luhn validation.
  final bool isValid;

  bool get hasCardNumber => cardNumber != null && cardNumber!.isNotEmpty;
  bool get hasExpiry => expiryDate != null && expiryDate!.isNotEmpty;
  bool get hasName => cardHolderName != null && cardHolderName!.isNotEmpty;

  /// Returns true if at least one field was successfully extracted.
  bool get hasAnyData => hasCardNumber || hasExpiry || hasName;

  CardDetails copyWith({
    String? cardNumber,
    String? maskedCardNumber,
    String? expiryDate,
    String? cardHolderName,
    String? bankName,
    String? cardNetwork,
    bool? isValid,
  }) {
    return CardDetails(
      cardNumber: cardNumber ?? this.cardNumber,
      maskedCardNumber: maskedCardNumber ?? this.maskedCardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      bankName: bankName ?? this.bankName,
      cardNetwork: cardNetwork ?? this.cardNetwork,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  String toString() => 'CardDetails('
      'cardNumber: $cardNumber, '
      'expiry: $expiryDate, '
      'name: $cardHolderName, '
      'isValid: $isValid)';
}