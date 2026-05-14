class CardDetails {
  final String cardNumber;
  final String cardHolderName;
  final String expiryDate;
  final String? bankName;
  final String? cardNetwork; // Visa, Mastercard, Rupay, etc.

  const CardDetails({
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryDate,
    this.bankName,
    this.cardNetwork,
  });

  bool get isValid => cardNumber.isNotEmpty && expiryDate.isNotEmpty;

  CardDetails copyWith({
    String? cardNumber,
    String? cardHolderName,
    String? expiryDate,
    String? bankName,
    String? cardNetwork,
  }) {
    return CardDetails(
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      expiryDate: expiryDate ?? this.expiryDate,
      bankName: bankName ?? this.bankName,
      cardNetwork: cardNetwork ?? this.cardNetwork,
    );
  }
}