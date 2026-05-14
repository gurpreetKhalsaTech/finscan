class BankDetails {
  final String accountNumber;
  final String ifscCode;
  final String? accountHolderName;
  final String? bankName;
  final String? branchName;
  final String? micrCode;

  const BankDetails({
    required this.accountNumber,
    required this.ifscCode,
    this.accountHolderName,
    this.bankName,
    this.branchName,
    this.micrCode,
  });

  bool get isValid => accountNumber.isNotEmpty && ifscCode.isNotEmpty;

  BankDetails copyWith({
    String? accountNumber,
    String? ifscCode,
    String? accountHolderName,
    String? bankName,
    String? branchName,
    String? micrCode,
  }) {
    return BankDetails(
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      bankName: bankName ?? this.bankName,
      branchName: branchName ?? this.branchName,
      micrCode: micrCode ?? this.micrCode,
    );
  }
}