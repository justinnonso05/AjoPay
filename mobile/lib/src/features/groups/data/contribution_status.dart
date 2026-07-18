import '../../wallet/data/wallet_models.dart';
import 'group_models.dart';

/// The backend doesn't expose a "have I paid this round" flag directly, so
/// this infers it from wallet history: a contribution-type transaction for
/// this group that landed after the group record last changed (which
/// happens whenever the round advances). Not airtight, but the best signal
/// available without a dedicated endpoint.
bool hasPaidCurrentRound(GroupResponse group, List<WalletTransaction> transactions) {
  final roundStartedAt = group.updatedAt ?? group.startedAt;
  return transactions.any((t) {
    if (t.relatedGroupId != group.id) return false;
    if (!t.type.toLowerCase().contains('contribution')) return false;
    if (roundStartedAt == null) return true;
    return !t.createdAt.isBefore(roundStartedAt);
  });
}
