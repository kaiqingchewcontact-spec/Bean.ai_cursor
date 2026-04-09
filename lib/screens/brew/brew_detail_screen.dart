import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/brew.dart';
import '../../providers/app_state.dart';

/// Single brew detail: parameters, AI content, and actions.
class BrewDetailScreen extends StatefulWidget {
  const BrewDetailScreen({super.key, required this.brewId});

  final String brewId;

  @override
  State<BrewDetailScreen> createState() => _BrewDetailScreenState();
}

class _BrewDetailScreenState extends State<BrewDetailScreen> {
  bool _loadingFeedback = false;
  Map<String, dynamic>? _displayFeedback;

  @override
  void didUpdateWidget(covariant BrewDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brewId != widget.brewId) {
      _displayFeedback = null;
      _loadingFeedback = false;
    }
  }

  Brew? _brew(AppState app) {
    try {
      return app.brews.firstWhere((b) => b.id == widget.brewId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _getAiFeedback(AppState app, Brew brew) async {
    if (brew.rating <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a star rating first so AI can respond.')),
      );
      return;
    }
    setState(() => _loadingFeedback = true);
    try {
      final fb = await app.getBrewFeedback(brew, brew.rating);
      if (!mounted) return;
      setState(() {
        _displayFeedback = fb;
        _loadingFeedback = false;
      });
      await app.updateBrew(brew.copyWith(aiFeedback: fb));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingFeedback = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback failed: $e')),
      );
    }
  }

  Future<void> _confirmDelete(AppState app, Brew brew) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete brew?'),
        content: const Text('This brew log will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BeanTheme.cherry),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await app.deleteBrew(brew.id);
    if (!mounted) return;
    context.go('/brew');
  }

  Future<void> _openEdit(Brew brew, String beanName) async {
    final doseCtrl = TextEditingController(text: brew.doseGrams.toString());
    final waterCtrl = TextEditingController(text: brew.waterMl.toString());
    final tempCtrl = TextEditingController(text: brew.waterTempCelsius.toString());
    final grindCtrl = TextEditingController(text: brew.grindSetting.toString());
    final notesCtrl = TextEditingController(text: brew.notes ?? '');
    double rating = brew.rating;

    final result = await showDialog<_BrewEditResult?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text('Edit brew · $beanName'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: doseCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Dose (g)'),
                    ),
                    TextField(
                      controller: waterCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Water (ml)'),
                    ),
                    TextField(
                      controller: tempCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Temp (°C)'),
                    ),
                    TextField(
                      controller: grindCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Grind setting'),
                    ),
                    const SizedBox(height: 8),
                    Text('Rating', style: Theme.of(context).textTheme.labelLarge),
                    RatingBar.builder(
                      initialRating: rating,
                      minRating: 0,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 28,
                      itemBuilder: (context, _) => Icon(
                        Icons.star_rounded,
                        color: BeanTheme.honey,
                      ),
                      onRatingUpdate: (r) => setLocal(() => rating = r),
                    ),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      ctx,
                      _BrewEditResult(
                        doseText: doseCtrl.text,
                        waterText: waterCtrl.text,
                        tempText: tempCtrl.text,
                        grindText: grindCtrl.text,
                        notesText: notesCtrl.text,
                        rating: rating,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    doseCtrl.dispose();
    waterCtrl.dispose();
    tempCtrl.dispose();
    grindCtrl.dispose();
    notesCtrl.dispose();

    if (result == null || !mounted) return;

    final dose = double.tryParse(result.doseText);
    final water = double.tryParse(result.waterText);
    final temp = double.tryParse(result.tempText);
    final grind = int.tryParse(result.grindText);

    if (dose == null || water == null || dose <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid dose or water.')),
      );
      return;
    }

    await context.read<AppState>().updateBrew(
          brew.copyWith(
            doseGrams: dose,
            waterMl: water,
            waterTempCelsius: temp ?? brew.waterTempCelsius,
            grindSetting: grind ?? brew.grindSetting,
            rating: result.rating,
            notes: result.notesText.trim().isEmpty ? null : result.notesText.trim(),
          ),
        );
  }

  IconData _methodIcon(String method) {
    final m = method.toLowerCase();
    if (m.contains('espresso')) return Icons.coffee_maker_outlined;
    if (m.contains('french')) return Icons.local_cafe_outlined;
    if (m.contains('aero')) return Icons.air_outlined;
    return Icons.water_outlined;
  }

  Map<String, dynamic>? _idealFromRecipe(Map<String, dynamic>? recipe) {
    if (recipe == null) return null;
    return {
      if (recipe['dose_grams'] is num) 'doseGrams': (recipe['dose_grams'] as num).toDouble(),
      if (recipe['water_ml'] is num) 'waterMl': (recipe['water_ml'] as num).toDouble(),
      if (recipe['water_temp_celsius'] is num)
        'waterTempCelsius': (recipe['water_temp_celsius'] as num).toDouble(),
      if (recipe['grind_setting'] is num) 'grindSetting': (recipe['grind_setting'] as num).round(),
      if (recipe['brew_time_seconds'] is num)
        'brewTimeSeconds': (recipe['brew_time_seconds'] as num).round(),
    };
  }

  Widget _paramTile({
    required IconData icon,
    required String label,
    required String value,
    String? comparison,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: BeanTheme.latte.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: BeanTheme.espresso),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.titleMedium),
                if (comparison != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    comparison,
                    style: theme.textTheme.bodySmall?.copyWith(color: BeanTheme.mint),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _compareLine(String label, double actual, double? ideal, String unit, {int decimals = 1}) {
    if (ideal == null) return null;
    final diff = actual - ideal;
    if (diff.abs() < 0.05) return 'Matches AI target ($label)';
    final dir = diff > 0 ? 'above' : 'below';
    return '${diff.abs().toStringAsFixed(decimals)}$unit $dir recipe $label';
  }

  String? _compareIntLine(String label, int actual, int? ideal) {
    if (ideal == null) return null;
    final diff = actual - ideal;
    if (diff == 0) return 'Matches AI target ($label)';
    final dir = diff > 0 ? 'coarser' : 'finer';
    return '${diff.abs()} steps $dir than recipe $label';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final brew = _brew(app);
    final theme = Theme.of(context);

    if (brew == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Brew')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Brew not found', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/brew'),
                child: const Text('Back to Brew Lab'),
              ),
            ],
          ),
        ),
      );
    }

    final bean = app.getBeanById(brew.beanId);
    final beanName = bean?.name ?? 'Unknown bean';
    final ideal = _idealFromRecipe(brew.aiRecipe);
    final feedbackMap = _displayFeedback ?? brew.aiFeedback;

    final dateStr = DateFormat.yMMMMEEEEd().add_jm().format(brew.brewDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brew detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: bean != null ? () => _openEdit(brew, beanName) : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(app, brew),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Material(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: bean != null ? () => context.push('/library/${bean.id}') : null,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: BeanTheme.caramel.withOpacity(0.35),
                          child: Icon(_methodIcon(brew.method), color: BeanTheme.espresso),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(beanName, style: theme.textTheme.titleLarge),
                              if (bean != null) ...[
                                Text(bean.roaster, style: theme.textTheme.bodyLarge),
                                Text(bean.origin, style: theme.textTheme.bodyMedium),
                              ],
                            ],
                          ),
                        ),
                        if (bean != null)
                          Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Parameters', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _paramTile(
                    icon: Icons.local_drink_outlined,
                    label: 'Method',
                    value: brew.method,
                  ),
                  const Divider(),
                  _paramTile(
                    icon: Icons.scale_outlined,
                    label: 'Dose',
                    value: '${brew.doseGrams.toStringAsFixed(1)} g',
                    comparison: _compareLine(
                      'dose',
                      brew.doseGrams,
                      ideal?['doseGrams'] as double?,
                      ' g',
                    ),
                  ),
                  const Divider(),
                  _paramTile(
                    icon: Icons.water_drop_outlined,
                    label: 'Water',
                    value: '${brew.waterMl.toStringAsFixed(0)} ml',
                    comparison: _compareLine(
                      'water',
                      brew.waterMl,
                      ideal?['waterMl'] as double?,
                      ' ml',
                      decimals: 0,
                    ),
                  ),
                  const Divider(),
                  _paramTile(
                    icon: Icons.percent_outlined,
                    label: 'Ratio',
                    value: brew.ratioLabel,
                  ),
                  const Divider(),
                  _paramTile(
                    icon: Icons.thermostat_outlined,
                    label: 'Temperature',
                    value: '${brew.waterTempCelsius.toStringAsFixed(0)} °C',
                    comparison: _compareLine(
                      'temp',
                      brew.waterTempCelsius,
                      ideal?['waterTempCelsius'] as double?,
                      '°C',
                      decimals: 0,
                    ),
                  ),
                  const Divider(),
                  _paramTile(
                    icon: Icons.tune,
                    label: 'Grind',
                    value: brew.grinder != null && brew.grinder!.isNotEmpty
                        ? 'Setting ${brew.grindSetting} · ${brew.grinder}'
                        : 'Setting ${brew.grindSetting}',
                    comparison: _compareIntLine(
                      'grind',
                      brew.grindSetting,
                      ideal?['grindSetting'] as int?,
                    ),
                  ),
                  const Divider(),
                  _paramTile(
                    icon: Icons.timer_outlined,
                    label: 'Brew time',
                    value: brew.brewTimeLabel,
                    comparison: () {
                      final target = ideal?['brewTimeSeconds'] as int?;
                      if (target == null) return null;
                      final actual = brew.brewTime.inSeconds;
                      final diff = actual - target;
                      if (diff.abs() < 2) return 'Matches AI target brew time';
                      return '${diff.abs()}s ${diff > 0 ? 'longer' : 'shorter'} than recipe';
                    }(),
                  ),
                  if (brew.bloomTime != null) ...[
                    const Divider(),
                    _paramTile(
                      icon: Icons.spa_outlined,
                      label: 'Bloom',
                      value: _formatShortDuration(brew.bloomTime!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Rating', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  RatingBarIndicator(
                    rating: brew.rating,
                    itemBuilder: (context, _) => Icon(
                      Icons.star_rounded,
                      color: BeanTheme.honey,
                    ),
                    itemCount: 5,
                    itemSize: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    brew.rating > 0 ? brew.rating.toStringAsFixed(1) : 'Not rated',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          if (brew.tastingNotes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Tasting notes', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: brew.tastingNotes
                  .map(
                    (n) => Chip(
                      label: Text(n),
                      backgroundColor: BeanTheme.latte,
                    ),
                  )
                  .toList(),
            ),
          ],
          if (brew.notes != null && brew.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Notes', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(brew.notes!, style: theme.textTheme.bodyLarge),
              ),
            ),
          ],
          if (brew.aiRecipe != null) ...[
            const SizedBox(height: 20),
            Text('AI recipe used', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            _AiRecipeDetailCard(recipe: brew.aiRecipe!),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loadingFeedback ? null : () => _getAiFeedback(app, brew),
            icon: _loadingFeedback
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology_outlined),
            label: Text(_loadingFeedback ? 'Analyzing…' : 'Get AI Feedback'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          if (feedbackMap != null) ...[
            const SizedBox(height: 16),
            _AiFeedbackCard(data: feedbackMap),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.push('/brew/log?beanId=${brew.beanId}'),
            icon: const Icon(Icons.replay),
            label: const Text('Brew Again'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class _AiRecipeDetailCard extends StatelessWidget {
  const _AiRecipeDetailCard({required this.recipe});

  final Map<String, dynamic> recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instructions = recipe['instructions'];
    final tips = recipe['tips'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe['ratio'] != null)
              Text(
                'Target: ${recipe['ratio']}',
                style: theme.textTheme.titleMedium?.copyWith(color: BeanTheme.espresso),
              ),
            if (instructions is List && instructions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Instructions', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ...instructions.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.key + 1}. ', style: theme.textTheme.bodyMedium),
                      Expanded(child: Text('${e.value}', style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                );
              }),
            ],
            if (tips is List && tips.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Tips', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ...tips.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 18, color: BeanTheme.honey),
                      const SizedBox(width: 8),
                      Expanded(child: Text('$t', style: theme.textTheme.bodySmall)),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _BrewEditResult {
  const _BrewEditResult({
    required this.doseText,
    required this.waterText,
    required this.tempText,
    required this.grindText,
    required this.notesText,
    required this.rating,
  });

  final String doseText;
  final String waterText;
  final String tempText;
  final String grindText;
  final String notesText;
  final double rating;
}

class _AiFeedbackCard extends StatelessWidget {
  const _AiFeedbackCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overall = data['overall'];
    final adjustments = data['adjustments'];
    final pattern = data['pattern_note'];
    return Card(
      color: BeanTheme.milk,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: BeanTheme.mint, size: 22),
                const SizedBox(width: 8),
                Text('AI feedback', style: theme.textTheme.titleMedium),
              ],
            ),
            if (overall != null) ...[
              const SizedBox(height: 10),
              Text('$overall', style: theme.textTheme.bodyLarge),
            ],
            if (adjustments is List && adjustments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Adjustments', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ...adjustments.map((dynamic item) {
                if (item is! Map) return const SizedBox.shrink();
                final m = Map<String, dynamic>.from(item);
                final param = m['parameter'];
                final sug = m['suggestion'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.trending_flat, size: 20, color: BeanTheme.cherry),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (param != null)
                              Text(
                                '$param'.toUpperCase(),
                                style: theme.textTheme.labelSmall,
                              ),
                            Text('$sug', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (pattern != null) ...[
              const SizedBox(height: 8),
              Text('$pattern', style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
