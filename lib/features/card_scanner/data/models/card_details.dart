/// Parsed card data extracted from OCR output.
class CardDetails {
  const CardDetails({
    this.cardNumber,
    this.maskedCardNumber,
    this.expiryDate,
    this.cardHolderName,
    this.cardNetwork,
    this.bankName,
    this.isValid = false,
  });

  /// Raw digits-only card number (13–19 digits).
  final String? cardNumber;

  /// Masked display string e.g. "**** **** **** 3995"
  final String? maskedCardNumber;

  /// Expiry in normalised "MM/YY" format.
  final String? expiryDate;

  /// Cardholder name as printed on card.
  final String? cardHolderName;

  /// Card network: Visa / Mastercard / RuPay / Amex / Discover / Diners.
  final String? cardNetwork;

  /// Issuing bank if detected in OCR text.
  final String? bankName;

  /// True if cardNumber passes Luhn validation.
  final bool isValid;

  bool get hasCardNumber => cardNumber != null && cardNumber!.isNotEmpty;
  bool get hasExpiry => expiryDate != null && expiryDate!.isNotEmpty;
  bool get hasName => cardHolderName != null && cardHolderName!.isNotEmpty;

  bool get hasAnyData => hasCardNumber || hasExpiry || hasName;

  CardDetails copyWith({
    String? cardNumber,
    String? maskedCardNumber,
    String? expiryDate,
    String? cardHolderName,
    String? cardNetwork,
    String? bankName,
    bool? isValid,
  }) {
    return CardDetails(
      cardNumber: cardNumber ?? this.cardNumber,
      maskedCardNumber: maskedCardNumber ?? this.maskedCardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      cardNetwork: cardNetwork ?? this.cardNetwork,
      bankName: bankName ?? this.bankName,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  String toString() => 'CardDetails('
      'cardNumber: $cardNumber, '
      'expiry: $expiryDate, '
      'name: $cardHolderName, '
      'network: $cardNetwork, '
      'bank: $bankName, '
      'isValid: $isValid)';
}