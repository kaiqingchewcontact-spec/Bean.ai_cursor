import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/user_profile.dart';
import '../../providers/app_state.dart';

/// Edit display name, email, origins, processes, flavors, roast, and brew method.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  final _picker = ImagePicker();

  bool _emailReadOnly = false;
  String? _avatarUrl;
  List<String> _origins = [];
  List<String> _processes = [];
  List<String> _flavors = [];
  String _roast = AppConstants.roastLevels[2];
  String _brewMethod = AppConstants.brewMethods[0];
  String? _lastSyncedProfileId;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _syncFromProfile(UserProfile? profile) {
    final authEmail = FirebaseAuth.instance.currentUser?.email;
    _emailReadOnly = authEmail != null && authEmail.isNotEmpty;

    if (profile != null) {
      _nameController.text = profile.displayName ?? '';
      _emailController.text = _emailReadOnly
          ? authEmail!
          : (profile.email ?? '');
      _avatarUrl = profile.avatarUrl;
      final p = profile.preferences;
      _origins = List.of(p.favoriteOrigins);
      _processes = List.of(p.favoriteProcesses);
      _flavors = List.of(p.flavorPreferences);
      _roast = AppConstants.roastLevels.contains(p.preferredRoastLevel)
          ? p.preferredRoastLevel
          : AppConstants.roastLevels[2];
      _brewMethod = AppConstants.brewMethods.contains(p.preferredBrewMethod)
          ? p.preferredBrewMethod
          : AppConstants.brewMethods[0];
    } else {
      _nameController.clear();
      _emailController.text = authEmail ?? '';
      _avatarUrl = null;
      _origins = [];
      _processes = [];
      _flavors = [];
      _roast = AppConstants.roastLevels[2];
      _brewMethod = AppConstants.brewMethods[0];
    }
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      _avatarUrl = file.path;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final app = context.read<AppState>();
    final existing = app.userProfile;
    const uuid = Uuid();
    final id = existing?.id ?? uuid.v4();
    final createdAt = existing?.createdAt ?? DateTime.now();

    final authEmail = FirebaseAuth.instance.currentUser?.email;
    final email = (_emailReadOnly && authEmail != null && authEmail.isNotEmpty)
        ? authEmail
        : _emailController.text.trim();

    final newPrefs = UserPreferences(
      favoriteOrigins: _origins,
      favoriteProcesses: _processes,
      flavorPreferences: _flavors,
      preferredRoastLevel: _roast,
      preferredBrewMethod: _brewMethod,
      darkMode: existing?.preferences.darkMode ?? false,
      notificationsEnabled: existing?.preferences.notificationsEnabled ?? true,
      communityOptIn: existing?.preferences.communityOptIn ?? true,
    );

    final profile = UserProfile(
      id: id,
      displayName: _nameController.text.trim(),
      email: email.isEmpty ? null : email,
      avatarUrl: _avatarUrl,
      createdAt: createdAt,
      tier: existing?.tier ?? SubscriptionTier.free,
      subscriptionExpiresAt: existing?.subscriptionExpiresAt,
      equipment: existing?.equipment ?? const UserEquipment(),
      preferences: newPrefs,
      stats: existing?.stats ?? const UserStats(),
    );

    await app.updateProfile(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
    context.pop();
  }

  ImageProvider? _avatarImageProvider() {
    final url = _avatarUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return NetworkImage(url);
    final file = File(url);
    if (file.existsSync()) return FileImage(file);
    return null;
  }

  void _toggleList(List<String> list, String value, void Function(List<String>) setFn) {
    setState(() {
      final next = List<String>.of(list);
      if (next.contains(value)) {
        next.remove(value);
      } else {
        next.add(value);
      }
      setFn(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final profile = app.userProfile;
    final syncKey = profile?.id ?? '__guest__';
    if (_lastSyncedProfileId != syncKey) {
      _lastSyncedProfileId = syncKey;
      _syncFromProfile(profile);
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: BeanTheme.latte,
                    foregroundImage: _avatarImageProvider(),
                    child: _avatarUrl == null || _avatarUrl!.isEmpty
                        ? Icon(
                            Icons.person_rounded,
                            size: 56,
                            color: BeanTheme.espresso.withOpacity(0.65),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Change Photo'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Photos are stored as a local path until cloud upload is wired.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Display name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter a display name';
                }
                if (v.trim().length < 2) {
                  return 'Name should be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              readOnly: _emailReadOnly,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.mail_outline_rounded),
                helperText: _emailReadOnly
                    ? 'Managed by your sign-in provider'
                    : null,
              ),
              validator: (v) {
                if (_emailReadOnly) return null;
                if (v == null || v.trim().isEmpty) return null;
                final email = v.trim();
                final ok = RegExp(r'^[\w.+-]+@[\w.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
                if (!ok) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Favorite origins',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.origins.map((o) {
                final selected = _origins.contains(o);
                return FilterChip(
                  label: Text(o),
                  selected: selected,
                  onSelected: (_) => _toggleList(_origins, o, (n) => _origins = n),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Favorite processes',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.processes.map((p) {
                final selected = _processes.contains(p);
                return FilterChip(
                  label: Text(p),
                  selected: selected,
                  onSelected: (_) =>
                      _toggleList(_processes, p, (n) => _processes = n),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Flavor preferences',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.flavorCategories.map((f) {
                final selected = _flavors.contains(f);
                return FilterChip(
                  label: Text(f),
                  selected: selected,
                  onSelected: (_) => _toggleList(_flavors, f, (n) => _flavors = n),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _roast,
              decoration: const InputDecoration(
                labelText: 'Preferred roast level',
                prefixIcon: Icon(Icons.grain_rounded),
              ),
              items: AppConstants.roastLevels
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _roast = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _brewMethod,
              decoration: const InputDecoration(
                labelText: 'Preferred brew method',
                prefixIcon: Icon(Icons.local_cafe_rounded),
              ),
              isExpanded: true,
              items: AppConstants.brewMethods
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(m, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _brewMethod = v);
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
