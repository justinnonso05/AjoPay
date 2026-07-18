class WalletTransaction {
  final String id;
  final String type;
  final double amount;
  final String? relatedGroupId;
  final String? narration;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.relatedGroupId,
    this.narration,
    required this.createdAt,
  });

  /// Whether this entry adds money to the wallet (shown as `+`) vs. removes
  /// it (shown as `-`). The backend doesn't expose a signed amount or an
  /// explicit direction field, so this infers it from `type` — kept broad
  /// on purpose since we don't have a confirmed enum of every value the
  /// backend can send (e.g. "topup", "wallet_topup", "deposit" all plausibly
  /// mean the same thing).
  bool get isCredit {
    final t = type.toLowerCase().replaceAll('_', '').replaceAll('-', '');
    const creditKeywords = ['deposit', 'topup', 'payout', 'refund', 'credit', 'received', 'reversal'];
    const debitKeywords = ['withdraw', 'contribution', 'debit', 'payment'];

    if (debitKeywords.any(t.contains)) return false;
    return creditKeywords.any(t.contains);
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      relatedGroupId: json['related_group_id']?.toString(),
      narration: json['narration']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
