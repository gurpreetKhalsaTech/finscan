/// Parsed bank/passbook data extracted from OCR output.
class BankDetails {
  const BankDetails({
    this.accountHolderName,
    this.accountNumber,
    this.ifscCode,
    this.micrCode,
    this.bankName,
    this.branchName,
  });

  final String? accountHolderName;

  /// Digits-only account number string.
  final String? accountNumber;

  /// IFSC code in uppercase, e.g. "SBIN0005576"
  final String? ifscCode;

  /// 9-digit MICR code.
  final String? micrCode;

  final String? bankName;
  final String? branchName;

  bool get hasAccountNumber =>
      accountNumber != null && accountNumber!.isNotEmpty;
  bool get hasIfsc => ifscCode != null && ifscCode!.isNotEmpty;
  bool get hasName =>
      accountHolderName != null && accountHolderName!.isNotEmpty;

  bool get hasAnyData => hasAccountNumber || hasIfsc || hasName;

  BankDetails copyWith({
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
    String? micrCode,
    String? bankName,
    String? branchName,
  }) {
    return BankDetails(
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      micrCode: micrCode ?? this.micrCode,
      bankName: bankName ?? this.bankName,
      branchName: branchName ?? this.branchName,
    );
  }

  @override
  String toString() => 'BankDetails('
      'name: $accountHolderName, '
      'accountNumber: $accountNumber, '
      'ifsc: $ifscCode, '
      'micr: $micrCode, '
      'bank: $bankName)';
}