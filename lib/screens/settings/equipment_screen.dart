import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/user_profile.dart';
import '../../providers/app_state.dart';

/// Grinder, brewers, kettle, scale, and water — feeds AI recipe suggestions.
class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final _kettleBrandController = TextEditingController();
  final _scaleBrandController = TextEditingController();
  final _filterController = TextEditingController();
  final _tdsController = TextEditingController();

  String? _primaryBrewer;
  String? _grinder;
  final Set<String> _additionalBrewers = {};
  bool _gooseneck = false;
  bool _tempControl = false;
  bool _scaleTimer = false;

  String? _lastEquipmentSignature;

  @override
  void dispose() {
    _kettleBrandController.dispose();
    _scaleBrandController.dispose();
    _filterController.dispose();
    _tdsController.dispose();
    super.dispose();
  }

  void _loadFromEquipment(UserEquipment e, Map<String, dynamic>? water) {
    _primaryBrewer = e.primaryBrewer;
    _grinder = e.grinder;
    _additionalBrewers
      ..clear()
      ..addAll(e.allBrewers.where((m) => m != e.primaryBrewer));

    _filterController.text = e.waterFilter ?? '';
    _kettleBrandController.text = (water?['kettleBrand'] as String?) ?? '';
    _gooseneck = water?['gooseneck'] as bool? ?? false;
    _tempControl = water?['temperatureControl'] as bool? ?? false;
    _scaleBrandController.text = (water?['scaleBrand'] as String?) ?? '';
    _scaleTimer = water?['scaleTimerBuiltin'] as bool? ?? false;

    final tds = water?['tds'];
    if (tds is num) {
      _tdsController.text = tds.toString();
    } else if (tds is String) {
      _tdsController.text = tds;
    } else {
      _tdsController.clear();
    }
  }

  String _signature(UserEquipment e) {
    return '${e.primaryBrewer}|${e.grinder}|${e.allBrewers.join(',')}|${e.waterFilter}|${e.waterProfile}';
  }

  IconData _iconForMethod(String method) {
    final m = method.toLowerCase();
    if (m.contains('espresso')) return Icons.coffee_rounded;
    if (m.contains('french')) return Icons.water_drop_rounded;
    if (m.contains('cold')) return Icons.ac_unit_rounded;
    if (m.contains('aeropress')) return Icons.science_rounded;
    if (m.contains('moka')) return Icons.local_fire_department_rounded;
    if (m.contains('turkish')) return Icons.emoji_food_beverage_rounded;
    if (m.contains('siphon')) return Icons.bubble_chart_rounded;
    return Icons.coffee_maker_rounded;
  }

  Map<String, dynamic> _buildWaterProfile() {
    double? tds;
    final raw = _tdsController.text.trim();
    if (raw.isNotEmpty) {
      tds = double.tryParse(raw.replaceAll(',', '.'));
    }
    return {
      'kettleBrand': _kettleBrandController.text.trim(),
      'gooseneck': _gooseneck,
      'temperatureControl': _tempControl,
      'scaleBrand': _scaleBrandController.text.trim(),
      'scaleTimerBuiltin': _scaleTimer,
      if (tds != null) 'tds': tds,
    };
  }

  List<String> _combinedBrewers() {
    final list = <String>{};
    if (_primaryBrewer != null && _primaryBrewer!.isNotEmpty) {
      list.add(_primaryBrewer!);
    }
    list.addAll(_additionalBrewers);
    return list.toList();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final profile = app.userProfile;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a profile in Settings first.'),
        ),
      );
      return;
    }

    if (_primaryBrewer == null || _primaryBrewer!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a primary brewer.')),
      );
      return;
    }

    final water = _buildWaterProfile();
    final equipment = UserEquipment(
      primaryBrewer: _primaryBrewer,
      grinder: _grinder,
      kettle: _kettleBrandController.text.trim().isEmpty
          ? null
          : _kettleBrandController.text.trim(),
      scale: _scaleBrandController.text.trim().isEmpty
          ? null
          : _scaleBrandController.text.trim(),
      waterFilter:
          _filterController.text.trim().isEmpty ? null : _filterController.text.trim(),
      allBrewers: _combinedBrewers(),
      waterProfile: water,
    );

    await app.updateEquipment(equipment);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Equipment saved')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final profile = app.userProfile;
    final e = profile?.equipment ?? const UserEquipment();

    final sig = _signature(e);
    if (_lastEquipmentSignature != sig) {
      _lastEquipmentSignature = sig;
      _loadFromEquipment(e, e.waterProfile);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            color: isDark ? BeanTheme.darkCard : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: BeanTheme.honey),
                      const SizedBox(width: 10),
                      Text(
                        'Your setup',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tell Bean.ai what you brew with. Grind quality, pour control, '
                    'and water all change extraction—so recipes adapt to your gear.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.75),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'PRIMARY BREWER',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 0.7,
              color: cs.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemCount: AppConstants.brewMethods.length,
            itemBuilder: (context, i) {
              final method = AppConstants.brewMethods[i];
              final selected = _primaryBrewer == method;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() {
                    _primaryBrewer = method;
                    _additionalBrewers.remove(method);
                  }),
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        width: selected ? 2 : 1,
                        color: selected
                            ? BeanTheme.caramel
                            : BeanTheme.latte.withOpacity(isDark ? 0.35 : 1),
                      ),
                      color: selected
                          ? BeanTheme.caramel.withOpacity(0.18)
                          : (isDark ? BeanTheme.darkSurface : BeanTheme.milk),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _iconForMethod(method),
                            color: selected ? BeanTheme.espresso : cs.primary,
                          ),
                          const Spacer(),
                          Text(
                            method,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_primaryBrewer != null &&
              _primaryBrewer!.isNotEmpty &&
              !AppConstants.brewMethods.contains(_primaryBrewer))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Saved brewer "$_primaryBrewer" is not in the list above. '
                'Select a method to update.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: BeanTheme.cherry,
                ),
              ),
            ),
          const SizedBox(height: 22),
          _TipCard(
            icon: Icons.tips_and_updates_outlined,
            title: 'Why the primary brewer matters',
            body:
                'AI uses your main method for default ratios, bloom timing, and grind targets. '
                'Switch anytime when you change your daily driver.',
          ),
          const SizedBox(height: 20),
          Text(
            'GRINDER',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 0.7,
              color: cs.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: DropdownButtonFormField<String>(
                value: _grinder != null && AppConstants.grinders.contains(_grinder)
                    ? _grinder
                    : null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Grinder model',
                  prefixIcon: Icon(Icons.tune_rounded),
                ),
                hint: const Text('Select your grinder'),
                isExpanded: true,
                items: AppConstants.grinders
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(g, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _grinder = v),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ADDITIONAL BREWERS',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 0.7,
              color: cs.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select other methods you use regularly (primary is excluded).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.brewMethods.map((m) {
              if (m == _primaryBrewer) return const SizedBox.shrink();
              final on = _additionalBrewers.contains(m);
              return FilterChip(
                label: Text(m),
                selected: on,
                onSelected: (_) {
                  setState(() {
                    if (on) {
                      _additionalBrewers.remove(m);
                    } else {
                      _additionalBrewers.add(m);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          Text(
            'KETTLE',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 0.7,
              color: cs.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _kettleBrandController,
                    decoration: const InputDecoration(
                      labelText: 'Kettle brand / model',
                      prefixIcon: Icon(Icons.water_rounded),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gooseneck spout'),
                    subtitle: const Text('Better pour control for pour-over'),
                    value: _gooseneck,
                    onChanged: (v) => setState(() => _gooseneck = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Temperature control'),
                    subtitle: const Text('Set exact brew temp'),
                    value: _tempControl,
                    onChanged: (v) => setState(() => _tempControl = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SCALE',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 0.7,
              color: cs.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _scaleBrandController,
                    decoration: const InputDecoration(
                      labelText: 'Scale brand / model',
                      prefixIcon: Icon(Icons.scale_rounded),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Built-in timer'),
                    subtitle: const Text('Handy for bloom + total time tracking'),
                    value: _scaleTimer,
                    onChanged: (v) => setState(() => _scaleTimer = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'WATER',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 0.7,
              color: cs.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _filterController,
                    decoration: const InputDecoration(
                      labelText: 'Filter type (e.g. Brita, BWT, RO)',
                      prefixIcon: Icon(Icons.filter_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tdsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'TDS (ppm), if known',
                      prefixIcon: Icon(Icons.analytics_outlined),
                      hintText: 'e.g. 120',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _TipCard(
            icon: Icons.water_drop_outlined,
            title: 'Water shapes flavor',
            body:
                'Soft vs hard water shifts acidity and body. Even a rough TDS helps the AI '
                'suggest temperature and ratio tweaks.',
          ),
          const SizedBox(height: 20),
          if (profile != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected setup',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      icon: Icons.coffee_maker_rounded,
                      label: 'Primary',
                      value: _primaryBrewer ?? '—',
                    ),
                    _SummaryRow(
                      icon: Icons.tune_rounded,
                      label: 'Grinder',
                      value: _grinder ?? '—',
                    ),
                    _SummaryRow(
                      icon: Icons.list_rounded,
                      label: 'All brewers',
                      value: _combinedBrewers().isEmpty
                          ? '—'
                          : _combinedBrewers().join(', '),
                    ),
                    _SummaryRow(
                      icon: Icons.water_rounded,
                      label: 'Kettle',
                      value: _kettleBrandController.text.trim().isEmpty
                          ? '—'
                          : _kettleBrandController.text.trim(),
                    ),
                    _SummaryRow(
                      icon: Icons.scale_rounded,
                      label: 'Scale',
                      value: _scaleBrandController.text.trim().isEmpty
                          ? '—'
                          : _scaleBrandController.text.trim(),
                    ),
                    _SummaryRow(
                      icon: Icons.filter_alt_outlined,
                      label: 'Water filter',
                      value: _filterController.text.trim().isEmpty
                          ? '—'
                          : _filterController.text.trim(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: profile == null ? null : _save,
            child: const Text('Save equipment'),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      color: BeanTheme.mint.withOpacity(isDark ? 0.12 : 0.14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: BeanTheme.mint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: theme.colorScheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
