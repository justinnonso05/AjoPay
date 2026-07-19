import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pin_entry_sheet.dart';
import '../../data/group_models.dart';
import '../../data/group_repository.dart';

/// Lets the current user delegate their own upcoming payout turn to another
/// member, or request to swap cycle positions with one. Initiate-only —
/// the backend has no endpoint yet to list pending requests, so there's no
/// way to build a respond/approve screen (see [GroupRepository.delegateCycle]).
class CycleActionSheet extends ConsumerStatefulWidget {
  final String groupId;
  final GroupRotationEntry myEntry;
  final List<GroupRotationEntry> otherEntries;
  final bool isDelegate;

  const CycleActionSheet({
    super.key,
    required this.groupId,
    required this.myEntry,
    required this.otherEntries,
    required this.isDelegate,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String groupId,
    required GroupRotationEntry myEntry,
    required List<GroupRotationEntry> otherEntries,
    required bool isDelegate,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => CycleActionSheet(groupId: groupId, myEntry: myEntry, otherEntries: otherEntries, isDelegate: isDelegate),
    );
  }

  @override
  ConsumerState<CycleActionSheet> createState() => _CycleActionSheetState();
}

class _CycleActionSheetState extends ConsumerState<CycleActionSheet> {
  GroupRotationEntry? _selected;
  bool _isSubmitting = false;
  String? _error;

  Future<void> _submit() async {
    final target = _selected;
    if (target == null) {
      setState(() => _error = 'Choose who to ${widget.isDelegate ? 'delegate to' : 'swap with'}.');
      return;
    }

    final pin = await PinEntrySheet.show(
      context,
      title: widget.isDelegate ? 'Confirm Delegation' : 'Confirm Swap Request',
      subtitle: widget.isDelegate
          ? "Confirm with your PIN to give cycle ${widget.myEntry.cycleNumber}'s payout to ${target.fullName}."
          : "Confirm with your PIN to request swapping your cycle ${widget.myEntry.cycleNumber} with ${target.fullName}'s cycle ${target.cycleNumber}.",
    );
    if (pin == null || !mounted) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      if (widget.isDelegate) {
        await ref.read(groupRepositoryProvider).delegateCycle(
              widget.groupId,
              widget.myEntry.cycleNumber,
              toMemberId: target.userId,
              pin: pin,
            );
      } else {
        await ref.read(groupRepositoryProvider).requestCycleSwap(
              widget.groupId,
              targetMemberId: target.userId,
              targetCycleNumber: target.cycleNumber,
              pin: pin,
            );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isDelegate ? 'Delegate My Payout' : 'Request a Swap';
    final subtitle = widget.isDelegate
        ? "Give your cycle ${widget.myEntry.cycleNumber} payout turn to someone else in the group."
        : "Ask to trade payout positions — your cycle ${widget.myEntry.cycleNumber} for theirs.";

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 20),
          if (widget.otherEntries.isEmpty)
            Text(
              'No other members with an upcoming cycle to ${widget.isDelegate ? 'delegate to' : 'swap with'} yet.',
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: AppColors.textMuted),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.otherEntries.length,
                separatorBuilder: (context, index) => Divider(color: Colors.grey[100]),
                itemBuilder: (context, index) {
                  final entry = widget.otherEntries[index];
                  final isSelected = _selected?.userId == entry.userId;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => setState(() {
                      _selected = entry;
                      _error = null;
                    }),
                    leading: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.paleGreen, shape: BoxShape.circle),
                      child: Text('${entry.cycleNumber}', style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
                    ),
                    title: Text(
                      entry.fullName.isNotEmpty ? entry.fullName : '@${entry.username}',
                      style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    trailing: Icon(
                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: isSelected ? AppColors.accentGreen : AppColors.textMuted,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_isSubmitting || widget.otherEntries.isEmpty) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: AppColors.darkGreen,
                disabledBackgroundColor: AppColors.divider,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.darkGreen))
                  : Text(widget.isDelegate ? 'Delegate' : 'Request Swap', style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
