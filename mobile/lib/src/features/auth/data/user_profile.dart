class UserProfile {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String walletBalance;
  final String? personalReservedAccountNumber;
  final String? personalReservedAccountBank;
  final String? personalReservedAccountName;
  final bool kycStatus;
  final bool hasWallet;
  final bool hasPin;
  final String? payoutBankAccountNumber;
  final String? payoutBankCode;
  final String? payoutAccountName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.walletBalance,
    this.personalReservedAccountNumber,
    this.personalReservedAccountBank,
    this.personalReservedAccountName,
    required this.kycStatus,
    required this.hasWallet,
    required this.hasPin,
    this.payoutBankAccountNumber,
    this.payoutBankCode,
    this.payoutAccountName,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      walletBalance: json['wallet_balance']?.toString() ?? '0',
      personalReservedAccountNumber: json['personal_reserved_account_number']?.toString(),
      personalReservedAccountBank: json['personal_reserved_account_bank']?.toString(),
      personalReservedAccountName: json['personal_reserved_account_name']?.toString(),
      kycStatus: json['kyc_status'] == true,
      hasWallet: json['has_wallet'] == true,
      hasPin: json['has_pin'] == true,
      payoutBankAccountNumber: json['payout_bank_account_number']?.toString(),
      payoutBankCode: json['payout_bank_code']?.toString(),
      payoutAccountName: json['payout_account_name']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}
