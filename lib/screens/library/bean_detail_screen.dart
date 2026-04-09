import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../config/theme.dart';
import '../../models/bean.dart';
import '../../models/brew.dart';
import '../../providers/app_state.dart';

/// Full bean profile with freshness timeline, brew history, and AI insights.
class BeanDetailScreen extends StatefulWidget {
  const BeanDetailScreen({super.key, required this.beanId});

  final String beanId;

  @override
  State<BeanDetailScreen> createState() => _BeanDetailScreenState();
}

class _BeanDetailScreenState extends State<BeanDetailScreen> {
  static const List<FreshnessLevel> _timelineOrder = [
    FreshnessLevel.resting,
    FreshnessLevel.peak,
    FreshnessLevel.fresh,
    FreshnessLevel.aging,
    FreshnessLevel.stale,
  ];

  Color _levelColor(FreshnessLevel l) => switch (l) {
        FreshnessLevel.resting => BeanTheme.blueberry,
        FreshnessLevel.peak => BeanTheme.mint,
        FreshnessLevel.fresh => BeanTheme.honey,
        FreshnessLevel.aging => BeanTheme.caramel,
        FreshnessLevel.stale => BeanTheme.cherry,
        FreshnessLevel.unknown => BeanTheme.lightRoast,
      };

  String _levelShort(FreshnessLevel l) => switch (l) {
        FreshnessLevel.resting => 'Rest',
        FreshnessLevel.peak => 'Peak',
        FreshnessLevel.fresh => 'Fresh',
        FreshnessLevel.aging => 'Aging',
        FreshnessLevel.stale => 'Stale',
        FreshnessLevel.unknown => '?',
      };

  Future<void> _confirmDelete(Bean bean) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bean?'),
        content: Text('Remove "${bean.name}" from your library? This cannot be undone.'),
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
    await context.read<AppState>().deleteBean(bean.id);
    if (!mounted) return;
    context.go('/library');
  }

  Future<void> _openEdit(Bean bean) async {
    final nameCtrl = TextEditingController(text: bean.name);
    final roasterCtrl = TextEditingController(text: bean.roaster);
    final originCtrl = TextEditingController(text: bean.origin);
    final regionCtrl = TextEditingController(text: bean.region ?? '');
    final varietalCtrl = TextEditingController(text: bean.varietal ?? '');
    final processCtrl = TextEditingController(text: bean.process);
    final roastCtrl = TextEditingController(text: bean.roastLevel);
    final priceCtrl = TextEditingController(text: bean.price?.toString() ?? '');
    final weightCtrl = TextEditingController(text: bean.weightGrams?.toString() ?? '');
    final elevCtrl = TextEditingController(text: bean.elevation?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit bean'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: roasterCtrl, decoration: const InputDecoration(labelText: 'Roaster')),
                TextField(controller: originCtrl, decoration: const InputDecoration(labelText: 'Origin')),
                TextField(controller: regionCtrl, decoration: const InputDecoration(labelText: 'Region')),
                TextField(controller: varietalCtrl, decoration: const InputDecoration(labelText: 'Varietal')),
                TextField(controller: processCtrl, decoration: const InputDecoration(labelText: 'Process')),
                TextField(controller: roastCtrl, decoration: const InputDecoration(labelText: 'Roast level')),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price (optional)'),
                ),
                TextField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Weight g (optional)'),
                ),
                TextField(
                  controller: elevCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Elevation m (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        );
      },
    );

    if (ok != true || !mounted) {
      nameCtrl.dispose();
      roasterCtrl.dispose();
      originCtrl.dispose();
      regionCtrl.dispose();
      varietalCtrl.dispose();
      processCtrl.dispose();
      roastCtrl.dispose();
      priceCtrl.dispose();
      weightCtrl.dispose();
      elevCtrl.dispose();
      return;
    }

    double? parseOpt(String s) {
      final t = s.trim();
      if (t.isEmpty) return null;
      return double.tryParse(t);
    }

    final updated = bean.copyWith(
      name: nameCtrl.text.trim(),
      roaster: roasterCtrl.text.trim(),
      origin: originCtrl.text.trim(),
      region: regionCtrl.text.trim().isEmpty ? null : regionCtrl.text.trim(),
      varietal: varietalCtrl.text.trim().isEmpty ? null : varietalCtrl.text.trim(),
      process: processCtrl.text.trim(),
      roastLevel: roastCtrl.text.trim(),
      price: parseOpt(priceCtrl.text),
      weightGrams: parseOpt(weightCtrl.text),
      elevation: parseOpt(elevCtrl.text),
    );

    nameCtrl.dispose();
    roasterCtrl.dispose();
    originCtrl.dispose();
    regionCtrl.dispose();
    varietalCtrl.dispose();
    processCtrl.dispose();
    roastCtrl.dispose();
    priceCtrl.dispose();
    weightCtrl.dispose();
    elevCtrl.dispose();

    await context.read<AppState>().updateBean(updated);
    if (mounted) setState(() {});
  }

  Widget _heroImage(Bean bean) {
    final url = bean.imageUrl;
    Widget? image;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        image = Image.network(url, fit: BoxFit.cover);
      } else if (!kIsWeb) {
        image = Image.file(File(url), fit: BoxFit.cover);
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: BeanTheme.darkCard,
              child: image ??
                  Center(
                    child: Icon(
                      Icons.coffee_rounded,
                      size: 72,
                      color: BeanTheme.crema.withOpacity(0.35),
                    ),
                  ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String label, required String value}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: BeanTheme.caramel),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _freshnessTimeline(Bean bean) {
    final idx = bean.freshnessLevel == FreshnessLevel.unknown
        ? -1
        : _timelineOrder.indexOf(bean.freshnessLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(_timelineOrder.length, (i) {
            final level = _timelineOrder[i];
            final isCurrent = idx >= 0 && i == idx;
            final passed = idx >= 0 && i < idx;
            final color = _levelColor(level).withOpacity(isCurrent ? 1 : (passed ? 0.55 : 0.22));
            return Expanded(
              child: Column(
                children: [
                  Container(
                    height: 8,
                    margin: EdgeInsets.only(right: i < _timelineOrder.length - 1 ? 4 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: color,
                      border: isCurrent ? Border.all(color: BeanTheme.crema, width: 1.5) : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _levelShort(level),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                      color: isCurrent
                          ? BeanTheme.caramel
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          bean.freshnessLevel == FreshnessLevel.unknown
              ? 'Add a roast date to track freshness.'
              : 'Now: ${bean.freshnessLabel} · ${bean.daysFromRoast < 0 ? 'roast date unknown' : '${bean.daysFromRoast} days from roast'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _brewTile(Brew brew) {
    final date = DateFormat.MMMd().format(brew.brewDate);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: BeanTheme.latte.withOpacity(0.35),
        child: Icon(Icons.coffee_maker_outlined, color: BeanTheme.espresso.withOpacity(0.85)),
      ),
      title: Text(brew.method, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '$date · ${brew.ratioLabel} · ${brew.brewTimeLabel}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: brew.rating > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 18, color: BeanTheme.honey),
                Text(brew.rating.toStringAsFixed(1)),
              ],
            )
          : null,
    );
  }

  Widget _aiSection(Map<String, dynamic>? analysis) {
    if (analysis == null || analysis.isEmpty) {
      return Text(
        'No AI analysis saved for this bean yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
            ),
      );
    }
    final desc = analysis['description'] as String?;
    final confidence = (analysis['confidence'] as num?)?.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (confidence != null)
          Text(
            'Scan confidence: ${(confidence * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: BeanTheme.mint),
          ),
        if (desc != null && desc.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(desc, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 8),
        Text(
          'Raw fields',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        ...analysis.entries.where((e) => e.key != 'description').map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${e.key}: ${e.value}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                ),
              ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final bean = app.getBeanById(widget.beanId);

    if (bean == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bean')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bean not found.'),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => context.go('/library'), child: const Text('Back to library')),
            ],
          ),
        ),
      );
    }

    final brews = app.getBrewsForBean(bean.id)
      ..sort((a, b) => b.brewDate.compareTo(a.brewDate));
    final cost = bean.costPerCup;
    final costText = cost == null
        ? 'Add price and weight to estimate cost per cup.'
        : 'About \$${cost.toStringAsFixed(2)} per cup (18g dose)';

    return Scaffold(
      appBar: AppBar(
        title: Text(bean.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: bean.isFavorite ? 'Unfavorite' : 'Favorite',
            onPressed: () => app.toggleFavorite(bean.id),
            icon: Icon(
              bean.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: bean.isFavorite ? BeanTheme.cherry : null,
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => _openEdit(bean),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(bean),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Hero(
            tag: 'bean-hero-${bean.id}',
            child: _heroImage(bean),
          ),
          const SizedBox(height: 16),
          Text(
            bean.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Roaster: ${bean.roaster}')),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.storefront_outlined, size: 20, color: BeanTheme.caramel),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bean.roaster,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: TextDecoration.underline,
                            decorationColor: BeanTheme.caramel.withOpacity(0.5),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _infoRow(icon: Icons.public, label: 'Origin', value: bean.origin),
                  _infoRow(icon: Icons.map_outlined, label: 'Region', value: bean.region ?? ''),
                  _infoRow(icon: Icons.grass_outlined, label: 'Varietal', value: bean.varietal ?? ''),
                  _infoRow(icon: Icons.water_drop_outlined, label: 'Process', value: bean.process),
                  _infoRow(
                    icon: Icons.terrain_outlined,
                    label: 'Elevation',
                    value: bean.elevation != null ? '${bean.elevation!.toStringAsFixed(0)} m' : '',
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department_outlined, color: BeanTheme.cherry, size: 22),
                      const SizedBox(width: 8),
                      Text('Roast level', style: Theme.of(context).textTheme.labelLarge),
                      const Spacer(),
                      Chip(
                        label: Text(bean.roastLevel),
                        backgroundColor: BeanTheme.latte.withOpacity(0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Freshness', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _freshnessTimeline(bean),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tasting notes', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  if (bean.tastingNotes.isEmpty)
                    Text(
                      'No tasting notes yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                          ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: bean.tastingNotes
                          .map(
                            (n) => Chip(
                              label: Text(n),
                              side: BorderSide(color: BeanTheme.caramel.withOpacity(0.35)),
                              backgroundColor: BeanTheme.milk.withOpacity(0.4),
                            ),
                          )
                          .toList(),
                    ),
                  const Divider(height: 28),
                  Text('Your rating', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  RatingBar.builder(
                    key: ValueKey<double>(bean.rating),
                    initialRating: bean.rating,
                    minRating: 0,
                    allowHalfRating: true,
                    itemSize: 32,
                    unratedColor: BeanTheme.latte,
                    itemBuilder: (context, _) => Icon(
                      Icons.star_rounded,
                      color: BeanTheme.honey,
                    ),
                    onRatingUpdate: (rating) async {
                      await app.updateBean(bean.copyWith(rating: rating));
                      if (mounted) setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(costText, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Brew history', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text('${brews.length}', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (brews.isEmpty)
                    Text(
                      'No brews logged with this bean yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                          ),
                    )
                  else
                    Column(children: brews.take(8).map(_brewTile).toList()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI analysis', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _aiSection(bean.aiAnalysis),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => context.push('/brew/log?beanId=${Uri.encodeComponent(bean.id)}'),
            icon: const Icon(Icons.coffee_maker_rounded),
            label: const Text('Brew this'),
          ),
        ],
      ),
    );
  }
}
