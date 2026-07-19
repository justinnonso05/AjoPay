import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../routing/app_router.dart';
import '../../auth/data/user_profile.dart';
import '../../auth/data/user_repository.dart';
import '../../groups/data/group_invites_controller.dart';
import '../../home/data/home_controller.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../shell/data/shell_tab_provider.dart';
import '../../wallet/data/wallet_controller.dart';
import 'widgets/edit_profile_sheet.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can log back in anytime with your email and password.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(secureStorageServiceProvider).clear();
    ref.read(currentUserProvider.notifier).state = null;
    ref.invalidate(userProfileControllerProvider);
    ref.invalidate(homeControllerProvider);
    ref.invalidate(walletTransactionsControllerProvider);
    ref.invalidate(notificationsControllerProvider);
    ref.invalidate(groupInvitesControllerProvider);
    ref.read(selectedTabIndexProvider.notifier).state = 0;

    if (context.mounted) context.goNamed(AppRoute.login.name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileControllerProvider);
    final profile = profileState.profile;
    final pendingInviteCount = ref.watch(groupInvitesControllerProvider).invites.length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        children: [
          Text('Profile', style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          if (profile == null)
            const SkeletonCard(height: 140)
          else
            _ProfileHeader(profile: profile),
          const SizedBox(height: 28),
          _SettingsGroup(
            title: 'Wallet',
            rows: [
              _SettingsRow(icon: Icons.account_balance_wallet_rounded, label: 'Wallet Balance', onTap: () => _goToWallet(context, ref)),
              _SettingsRow(icon: Icons.qr_code_rounded, label: 'Virtual Account', onTap: () => _goToWallet(context, ref)),
              _SettingsRow(icon: Icons.receipt_long_rounded, label: 'Transaction History', onTap: () => _goToWallet(context, ref)),
              _SettingsRow(icon: Icons.arrow_upward_rounded, label: 'Withdraw Funds', onTap: () => _goToWallet(context, ref)),
              _SettingsRow(
                icon: Icons.account_balance_rounded,
                label: 'Payout Bank',
                trailing: profile?.payoutBankAccountNumber != null ? 'Set' : 'Not set',
                onTap: () => context.pushNamed(AppRoute.payoutBank.name),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Security',
            rows: [
              if (profile?.hasPin == false)
                _SettingsRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Create PIN',
                  onTap: () => context.pushNamed(AppRoute.pinSetup.name),
                )
              else
                _SettingsRow(
                  icon: Icons.lock_reset_rounded,
                  label: 'Reset PIN',
                  onTap: () => context.pushNamed(AppRoute.requestPinReset.name),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Savings',
            rows: [
              _SettingsRow(icon: Icons.groups_rounded, label: 'My Groups', onTap: () => context.pushNamed(AppRoute.myGroups.name)),
              _SettingsRow(
                icon: Icons.mail_outline_rounded,
                label: 'My Invites',
                trailing: pendingInviteCount > 0 ? '$pendingInviteCount new' : null,
                onTap: () => context.pushNamed(AppRoute.myInvites.name),
              ),
              _SettingsRow(
                icon: Icons.add_circle_outline_rounded,
                label: 'Join or Create a Group',
                onTap: () => context.pushNamed(AppRoute.joinOrCreate.name),
              ),
              _SettingsRow(icon: Icons.history_rounded, label: 'Contribution History', onTap: () => _goToWallet(context, ref)),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Account',
            rows: [
              _SettingsRow(
                icon: Icons.verified_user_outlined,
                label: 'KYC Status',
                trailing: (profile?.kycStatus ?? false) ? 'Verified' : 'Not verified',
                onTap: () => _comingSoon(context),
              ),
              _SettingsRow(icon: Icons.notifications_none_rounded, label: 'Notification Settings', onTap: () => _comingSoon(context)),
              _SettingsRow(icon: Icons.language_rounded, label: 'Language', onTap: () => _comingSoon(context)),
              _SettingsRow(icon: Icons.quiz_outlined, label: 'FAQ', onTap: () => context.pushNamed(AppRoute.faq.name)),
              _SettingsRow(icon: Icons.help_center_outlined, label: 'Help Center', onTap: () => _comingSoon(context)),
              _SettingsRow(icon: Icons.support_agent_rounded, label: 'Support', onTap: () => _comingSoon(context)),
              _SettingsRow(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => _comingSoon(context)),
              _SettingsRow(icon: Icons.description_outlined, label: 'Terms', onTap: () => _comingSoon(context)),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Account',
            rows: [
              _SettingsRow(
                icon: Icons.logout_rounded,
                label: 'Logout',
                isDanger: true,
                onTap: () => _handleLogout(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToWallet(BuildContext context, WidgetRef ref) {
    ref.read(selectedTabIndexProvider.notifier).state = 1;
    context.goNamed(AppRoute.home.name);
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.darkGreen),
    );
  }

}

class _ProfileHeader extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _ProfileHeader({required this.profile});

  @override
  ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  bool _isUploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final updated = await ref.read(userRepositoryProvider).uploadAvatar(bytes: bytes, filename: picked.name);
      ref.read(currentUserProvider.notifier).state = updated;
      ref.read(userProfileControllerProvider.notifier).refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message, style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.darkGreen));
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _editProfile() async {
    final updated = await EditProfileSheet.show(context, widget.profile);
    if (updated == null || !mounted) return;
    ref.read(currentUserProvider.notifier).state = updated;
    ref.read(userProfileControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final firstName = profile.firstName;
    final lastName = profile.lastName;
    final initial = firstName.isNotEmpty ? firstName[0] : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: cardShadow()),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.paleGreen,
                    shape: BoxShape.circle,
                    image: profile.avatarUrl != null ? DecorationImage(image: NetworkImage(profile.avatarUrl!), fit: BoxFit.cover) : null,
                  ),
                  child: profile.avatarUrl == null
                      ? Center(
                          child: Text(initial.toUpperCase(), style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.accentGreen)),
                        )
                      : (_isUploadingAvatar
                          ? Container(
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            )
                          : null),
                ),
                if (_isUploadingAvatar && profile.avatarUrl == null)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    ),
                  ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: AppColors.accentGreen, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _editProfile,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$firstName $lastName'.trim(), style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                if (profile.kycStatus == true) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified_rounded, color: AppColors.accentGreen, size: 18),
                ],
                const SizedBox(width: 6),
                const Icon(Icons.edit_outlined, size: 15, color: AppColors.textMuted),
              ],
            ),
          ),
          if (profile.kycStatus == true) ...[
            const SizedBox(height: 2),
            Text('BVN Verified', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: AppColors.accentGreen, fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 14),
          Divider(color: Colors.grey[100]),
          const SizedBox(height: 10),
          _infoRow(Icons.email_outlined, profile.email.isNotEmpty ? profile.email : '—'),
          const SizedBox(height: 8),
          _infoRow(Icons.phone_outlined, profile.phone ?? 'Not set'),
          const SizedBox(height: 8),
          _infoRow(
            Icons.calendar_today_outlined,
            profile.createdAt != null ? 'Member since ${formatShortDate(profile.createdAt!)}' : 'Member since —',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsRow> rows;

  const _SettingsGroup({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        ),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: cardShadow()),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i != rows.length - 1) Divider(height: 1, color: Colors.grey[100]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool isDanger;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDanger ? AppColors.danger : AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13.5, fontWeight: FontWeight.w600, color: color))),
            if (trailing != null)
              Text(trailing!, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(width: 6),
            if (!isDanger) const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
