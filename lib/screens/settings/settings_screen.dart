import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/user_profile.dart';
import '../../providers/app_state.dart';

/// Main settings hub: profile summary, subscription, preferences, data, and about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final _dateFmt = DateFormat.yMMMd();

  String _tierLabel(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.monthly:
        return 'Monthly';
      case SubscriptionTier.yearly:
        return 'Yearly';
      case SubscriptionTier.lifetime:
        return 'Lifetime';
    }
  }

  Color _tierColor(SubscriptionTier tier, bool isDark) {
    switch (tier) {
      case SubscriptionTier.free:
        return isDark ? BeanTheme.lightRoast : BeanTheme.mediumRoast;
      case SubscriptionTier.monthly:
      case SubscriptionTier.yearly:
        return BeanTheme.caramel;
      case SubscriptionTier.lifetime:
        return BeanTheme.honey;
    }
  }

  Future<void> _exportData(AppState app) async {
    final map = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'app': AppConstants.appName,
      'version': AppConstants.appVersion,
      if (app.userProfile != null) 'profile': app.userProfile!.toJson(),
      'beans': app.beans.map((b) => b.toJson()).toList(),
      'brews': app.brews.map((b) => b.toJson()).toList(),
      'tastingNotes': app.tastingNotes.map((n) => n.toJson()).toList(),
      'subscriptions': app.subscriptions.map((s) => s.toJson()).toList(),
    };
    final json = const JsonEncoder.withIndent('  ').convert(map);
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data copied to clipboard as JSON. Paste into a file to save.'),
      ),
    );
  }

  Future<void> _confirmClearData(AppState app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This removes your beans, brew logs, tasting notes, and subscriptions from this device. '
          'Your account profile will be reset to defaults. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: BeanTheme.cherry),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    for (final b in List.of(app.beans)) {
      await app.deleteBean(b.id);
    }
    for (final br in List.of(app.brews)) {
      await app.deleteBrew(br.id);
    }
    for (final n in List.of(app.tastingNotes)) {
      await app.deleteTastingNote(n.id);
    }
    for (final s in List.of(app.subscriptions)) {
      await app.deleteSubscription(s.id);
    }

    final existing = app.userProfile;
    if (existing != null) {
      await app.updateProfile(
        UserProfile(
          id: existing.id,
          displayName: existing.displayName,
          email: existing.email,
          avatarUrl: existing.avatarUrl,
          createdAt: existing.createdAt,
          tier: SubscriptionTier.free,
          subscriptionExpiresAt: null,
          equipment: const UserEquipment(),
          preferences: const UserPreferences(),
          stats: const UserStats(),
        ),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local data cleared.')),
    );
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will return to onboarding. Local data stays on this device unless you clear it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final app = context.read<AppState>();
    await app.resetOnboardingForSignOut();
    if (!mounted) return;
    context.go('/onboarding');
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final profile = app.userProfile;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    final prefs = profile?.preferences ?? const UserPreferences();
    final tier = profile?.tier ?? SubscriptionTier.free;
    final expiry = profile?.subscriptionExpiresAt;
    final expiryLabel = tier == SubscriptionTier.lifetime
        ? 'No expiry'
        : expiry != null
            ? _dateFmt.format(expiry)
            : '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (profile == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No profile loaded yet. Complete onboarding or pull to refresh from the home tab.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else ...[
            _SectionHeader(title: 'Profile'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: BeanTheme.latte,
                          foregroundImage: profile.avatarUrl != null &&
                                  profile.avatarUrl!.isNotEmpty
                              ? NetworkImage(profile.avatarUrl!)
                              : null,
                          child: profile.avatarUrl == null ||
                                  profile.avatarUrl!.isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: BeanTheme.espresso.withOpacity(0.7),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.displayName?.trim().isNotEmpty == true
                                    ? profile.displayName!.trim()
                                    : 'Coffee lover',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.email ?? 'No email on file',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurface.withOpacity(0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.edit_rounded, color: cs.primary),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/settings/profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: 'Subscription'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.workspace_premium_rounded,
                      color: _tierColor(tier, isDark),
                    ),
                    title: Text(_tierLabel(tier)),
                    subtitle: Text('Renews / expires: $expiryLabel'),
                    trailing: Chip(
                      label: Text(
                        app.isPremium ? 'Premium' : 'Free',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: app.isPremium
                          ? BeanTheme.mint.withOpacity(0.25)
                          : BeanTheme.latte,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.payment_rounded, color: cs.primary),
                    title: const Text('Manage Subscription'),
                    subtitle: const Text('Upgrade or change your plan'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/paywall'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: 'Account'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.person_outline_rounded, color: cs.primary),
                    title: const Text('Profile'),
                    subtitle: const Text('Name, palate, brew preferences'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/settings/profile'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.coffee_maker_outlined, color: cs.primary),
                    title: const Text('Equipment setup'),
                    subtitle: const Text('Grinder, brewers, kettle & water'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/settings/equipment'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: 'Preferences'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(Icons.dark_mode_rounded, color: cs.primary),
                    title: const Text('Dark mode'),
                    subtitle: const Text('Comfortable low-light reading'),
                    value: prefs.darkMode,
                    onChanged: (v) {
                      context.read<AppState>().updatePreferences(
                            prefs.copyWith(darkMode: v),
                          );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Icon(Icons.notifications_rounded, color: cs.primary),
                    title: const Text('Notifications'),
                    subtitle: const Text('Brew reminders and tips'),
                    value: prefs.notificationsEnabled,
                    onChanged: (v) {
                      context.read<AppState>().updatePreferences(
                            prefs.copyWith(notificationsEnabled: v),
                          );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Icon(Icons.groups_rounded, color: cs.primary),
                    title: const Text('Community features'),
                    subtitle: const Text('Opt in to social and discovery extras'),
                    value: prefs.communityOptIn,
                    onChanged: (v) {
                      context.read<AppState>().updatePreferences(
                            prefs.copyWith(communityOptIn: v),
                          );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: 'Coffee preferences'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.local_cafe_rounded, color: cs.primary),
                    title: const Text('Preferred brew method'),
                    subtitle: Text(prefs.preferredBrewMethod),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/settings/profile'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.grain_rounded, color: cs.primary),
                    title: const Text('Preferred roast level'),
                    subtitle: Text(prefs.preferredRoastLevel),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/settings/profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: 'Data'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.ios_share_rounded, color: cs.primary),
                    title: const Text('Export data'),
                    subtitle: const Text('Copy JSON to clipboard'),
                    onTap: () => _exportData(app),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.delete_forever_rounded, color: BeanTheme.cherry),
                    title: const Text('Clear data'),
                    subtitle: const Text('Remove local beans, brews, and notes'),
                    onTap: () => _confirmClearData(app),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: 'About'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: cs.primary),
                    title: const Text('App version'),
                    subtitle: Text('${AppConstants.appName} ${AppConstants.appVersion}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.star_rounded, color: cs.primary),
                    title: const Text('Rate the app'),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                    onTap: () => _openUrl(
                      'https://apps.apple.com/app/id0000000000',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.share_rounded, color: cs.primary),
                    title: const Text('Share Bean.ai'),
                    subtitle: const Text('Copies a short message to paste anywhere'),
                    onTap: () async {
                      final text =
                          'I’m tracking beans and brews with ${AppConstants.appName}. https://bean.ai';
                      await Clipboard.setData(ClipboardData(text: text));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share message copied to clipboard.'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.privacy_tip_outlined, color: cs.primary),
                    title: const Text('Privacy policy'),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                    onTap: () => _openUrl('https://bean.ai/privacy'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.description_outlined, color: cs.primary),
                    title: const Text('Terms of service'),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                    onTap: () => _openUrl('https://bean.ai/terms'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BeanTheme.cherry,
                  side: BorderSide(color: BeanTheme.cherry.withOpacity(0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          letterSpacing: 0.8,
          color: theme.colorScheme.onSurface.withOpacity(0.55),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
