enum CycleFrequency {
  weekly,
  monthly,
  yearly;

  String get apiValue => name;

  String get label {
    switch (this) {
      case CycleFrequency.weekly:
        return 'Weekly';
      case CycleFrequency.monthly:
        return 'Monthly';
      case CycleFrequency.yearly:
        return 'Yearly';
    }
  }

  static CycleFrequency? fromApiValue(String? value) {
    for (final freq in CycleFrequency.values) {
      if (freq.apiValue == value) return freq;
    }
    return null;
  }
}

enum ShortfallPolicy {
  hold,
  partial,
  adminDecides;

  String get apiValue {
    switch (this) {
      case ShortfallPolicy.hold:
        return 'hold';
      case ShortfallPolicy.partial:
        return 'partial';
      case ShortfallPolicy.adminDecides:
        return 'admin_decides';
    }
  }

  String get label {
    switch (this) {
      case ShortfallPolicy.hold:
        return 'Hold payout';
      case ShortfallPolicy.partial:
        return 'Pay out partially';
      case ShortfallPolicy.adminDecides:
        return 'Admin decides';
    }
  }

  String get description {
    switch (this) {
      case ShortfallPolicy.hold:
        return "Pause the payout until everyone's contribution is in.";
      case ShortfallPolicy.partial:
        return 'Pay out whatever has been contributed so far.';
      case ShortfallPolicy.adminDecides:
        return "You'll choose what happens each time it comes up.";
    }
  }
}

/// Payload for `POST /api/v1/groups/`.
/// Only the fields the backend actually requires are non-nullable;
/// payout-day fields are optional and only make sense for their
/// matching [cycleFrequency].
class GroupCreateRequest {
  final String name;
  final double contributionAmount;
  final CycleFrequency cycleFrequency;
  final int quorumPercent;
  final ShortfallPolicy shortfallPolicy;
  final int? payoutDayOfWeek;
  final int? payoutDayOfMonth;
  final int? payoutMonth;
  final int? memberCap;

  const GroupCreateRequest({
    required this.name,
    required this.contributionAmount,
    required this.cycleFrequency,
    required this.quorumPercent,
    required this.shortfallPolicy,
    this.payoutDayOfWeek,
    this.payoutDayOfMonth,
    this.payoutMonth,
    this.memberCap,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'contribution_amount': contributionAmount,
        'cycle_frequency': cycleFrequency.apiValue,
        'quorum_percent': quorumPercent,
        'shortfall_policy': shortfallPolicy.apiValue,
        if (payoutDayOfWeek != null) 'payout_day_of_week': payoutDayOfWeek,
        if (payoutDayOfMonth != null) 'payout_day_of_month': payoutDayOfMonth,
        if (payoutMonth != null) 'payout_month': payoutMonth,
        if (memberCap != null) 'member_cap': memberCap,
      };
}

class GroupResponse {
  final String id;
  final String name;
  final double contributionAmount;
  final CycleFrequency? cycleFrequency;
  final int quorumPercent;
  final ShortfallPolicy? shortfallPolicy;
  final String status;
  final String? inviteCode;
  final bool inviteCodeActive;
  final double poolBalance;
  final int? memberCap;
  final DateTime? createdAt;

  const GroupResponse({
    required this.id,
    required this.name,
    required this.contributionAmount,
    required this.cycleFrequency,
    required this.quorumPercent,
    required this.shortfallPolicy,
    required this.status,
    required this.inviteCode,
    required this.inviteCodeActive,
    required this.poolBalance,
    required this.memberCap,
    required this.createdAt,
  });

  factory GroupResponse.fromJson(Map<String, dynamic> json) {
    return GroupResponse(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      contributionAmount: (json['contribution_amount'] as num?)?.toDouble() ?? 0,
      cycleFrequency: CycleFrequency.fromApiValue(json['cycle_frequency']?.toString()),
      quorumPercent: (json['quorum_percent'] as num?)?.toInt() ?? 0,
      shortfallPolicy: _shortfallFromApiValue(json['shortfall_policy']?.toString()),
      status: json['status']?.toString() ?? '',
      inviteCode: json['invite_code']?.toString(),
      inviteCodeActive: json['invite_code_active'] == true,
      poolBalance: (json['pool_balance'] as num?)?.toDouble() ?? 0,
      memberCap: (json['member_cap'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  static ShortfallPolicy? _shortfallFromApiValue(String? value) {
    for (final policy in ShortfallPolicy.values) {
      if (policy.apiValue == value) return policy;
    }
    return null;
  }
}
