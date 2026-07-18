class Bank {
  final String name;
  final String code;

  const Bank({required this.name, required this.code});

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}

/// Result of a bank "name enquiry" — note the backend passes this through
/// from the payment provider as-is, so unlike the rest of the API it's
/// camelCase rather than snake_case.
class BankValidationResult {
  final String accountNumber;
  final String accountName;
  final String bankCode;

  const BankValidationResult({
    required this.accountNumber,
    required this.accountName,
    required this.bankCode,
  });

  factory BankValidationResult.fromJson(Map<String, dynamic> json) {
    return BankValidationResult(
      accountNumber: json['accountNumber']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
      bankCode: json['bankCode']?.toString() ?? '',
    );
  }
}
