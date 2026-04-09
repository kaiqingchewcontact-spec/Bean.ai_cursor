import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/tasting_note.dart';
import '../../providers/app_state.dart';

/// Flavor journal: timeline of tasting notes, stats, filters, and insights link.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  DateTimeRange? _dateRange;
  String? _beanIdFilter;
  double? _minScore;
  double? _maxScore;

  static String? _descriptorCategory(String descriptor) {
    for (final cat in AppConstants.flavorCategories) {
      final wheel = AppConstants.flavorWheel[cat];
      if (wheel != null && wheel.contains(descriptor)) return cat;
    }
    return null;
  }

  static String? _mostCommonFlavor(Iterable<TastingNote> notes) {
    final counts = <String, int>{};
    for (final n in notes) {
      for (final d in n.descriptors) {
        final cat = _descriptorCategory(d) ?? d;
        counts[cat] = (counts[cat] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    var bestKey = counts.keys.first;
    var bestCount = counts[bestKey]!;
    for (final e in counts.entries) {
      if (e.value > bestCount) {
        bestCount = e.value;
        bestKey = e.key;
      }
    }
    return bestKey;
  }

  List<TastingNote> _filtered(AppState app) {
    var list = List<TastingNote>.from(app.tastingNotes)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (_dateRange != null) {
      list = list
          .where((n) =>
              !n.createdAt.isBefore(_dateRange!.start) &&
              !n.createdAt.isAfter(_dateRange!.end.add(const Duration(days: 1))))
          .toList();
    }
    if (_beanIdFilter != null) {
      list = list.where((n) => n.beanId == _beanIdFilter).toList();
    }
    if (_minScore != null) {
      list = list.where((n) => n.overallScore >= _minScore!).toList();
    }
    if (_maxScore != null) {
      list = list.where((n) => n.overallScore <= _maxScore!).toList();
    }
    return list;
  }

  Future<void> _onRefresh() async {
    await context.read<AppState>().loadData();
    if (mounted) setState(() {});
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial = _dateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: BeanTheme.caramel,
                  onPrimary: BeanTheme.espresso,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  void _showFilterSheet(AppState app) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _JournalFilterSheet(
          app: app,
          initialBeanId: _beanIdFilter,
          initialMin: _minScore,
          initialMax: _maxScore,
          onApply: (beanId, minS, maxS) {
            setState(() {
              _beanIdFilter = beanId;
              _minScore = minS;
              _maxScore = maxS;
            });
            Navigator.pop(ctx);
          },
          onClearAll: () {
            setState(() {
              _beanIdFilter = null;
              _minScore = null;
              _maxScore = null;
              _dateRange = null;
            });
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final filtered = _filtered(app);
    final all = app.tastingNotes;
    final avgScore = all.isEmpty
        ? 0.0
        : all.map((n) => n.overallScore).reduce((a, b) => a + b) / all.length;
    final topFlavor = _mostCommonFlavor(all);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtle = isDark ? BeanTheme.crema.withOpacity(0.55) : BeanTheme.lightRoast;

    return Scaffold(
      body: RefreshIndicator(
        color: BeanTheme.caramel,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              floating: true,
              title: const Text('Flavor Journal'),
              actions: [
                IconButton(
                  tooltip: 'Date range',
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range_rounded),
                ),
                IconButton(
                  tooltip: 'More filters',
                  onPressed: () => _showFilterSheet(app),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Material(
                  color: isDark ? BeanTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push('/journal/insights'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: BeanTheme.blueberry.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: BeanTheme.blueberry,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Palate insights',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  'Charts, trends & AI summary',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: subtle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: subtle),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_dateRange != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          '${DateFormat.MMMd().format(_dateRange!.start)} – ${DateFormat.MMMd().format(_dateRange!.end)}',
                        ),
                        onDeleted: () => setState(() => _dateRange = null),
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Notes',
                        value: '${all.length}',
                        icon: Icons.note_alt_rounded,
                        accent: BeanTheme.honey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        label: 'Avg score',
                        value: all.isEmpty ? '—' : avgScore.toStringAsFixed(1),
                        icon: Icons.star_rounded,
                        accent: BeanTheme.caramel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        label: 'Top flavor',
                        value: topFlavor ?? '—',
                        icon: Icons.local_florist_rounded,
                        accent: BeanTheme.mint,
                        smallValue: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyJournal(
                  onAdd: () => context.push('/journal/note'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final note = filtered[i];
                    final bean = note.beanId != null ? app.getBeanById(note.beanId!) : null;
                    final topDesc = note.descriptors.take(4).join(' · ');
                    return _NoteCard(
                      note: note,
                      beanName: bean?.name ?? 'Unknown bean',
                      descriptorPreview: topDesc.isEmpty ? 'No descriptors yet' : topDesc,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/journal/note'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Tasting Note'),
        backgroundColor: BeanTheme.cherry,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.smallValue = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool smallValue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? BeanTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? BeanTheme.mediumRoast.withOpacity(0.35) : BeanTheme.latte,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? BeanTheme.crema.withOpacity(0.6) : BeanTheme.lightRoast,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: (smallValue
                    ? Theme.of(context).textTheme.titleSmall
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.beanName,
    required this.descriptorPreview,
  });

  final TastingNote note;
  final String beanName;
  final String descriptorPreview;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? BeanTheme.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {/* detail route optional */},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      beanName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: BeanTheme.caramel.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: BeanTheme.honey),
                        const SizedBox(width: 4),
                        Text(
                          note.overallScore.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat.yMMMd().add_jm().format(note.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? BeanTheme.crema.withOpacity(0.55) : BeanTheme.lightRoast,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                descriptorPreview,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalFilterSheet extends StatefulWidget {
  const _JournalFilterSheet({
    required this.app,
    required this.initialBeanId,
    required this.initialMin,
    required this.initialMax,
    required this.onApply,
    required this.onClearAll,
  });

  final AppState app;
  final String? initialBeanId;
  final double? initialMin;
  final double? initialMax;
  final void Function(String? beanId, double? minS, double? maxS) onApply;
  final VoidCallback onClearAll;

  @override
  State<_JournalFilterSheet> createState() => _JournalFilterSheetState();
}

class _JournalFilterSheetState extends State<_JournalFilterSheet> {
  late String? _beanId = widget.initialBeanId;
  late final TextEditingController _minCtrl = TextEditingController(
    text: widget.initialMin != null ? '${widget.initialMin!}' : '',
  );
  late final TextEditingController _maxCtrl = TextEditingController(
    text: widget.initialMax != null ? '${widget.initialMax!}' : '',
  );

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            value: _beanId,
            decoration: const InputDecoration(labelText: 'Bean'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All beans')),
              ...widget.app.activeBeans.map(
                (b) => DropdownMenuItem(
                  value: b.id,
                  child: Text(
                    b.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _beanId = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Min score (0–10)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _maxCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Max score (0–10)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final minS = double.tryParse(_minCtrl.text.trim());
              final maxS = double.tryParse(_maxCtrl.text.trim());
              widget.onApply(_beanId, minS, maxS);
            },
            child: const Text('Apply'),
          ),
          TextButton(
            onPressed: widget.onClearAll,
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    BeanTheme.caramel.withOpacity(0.35),
                    BeanTheme.honey.withOpacity(0.25),
                  ],
                ),
              ),
              child: const Icon(
                Icons.coffee_outlined,
                size: 56,
                color: BeanTheme.espresso,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start your flavor journal',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Log aromas, acidity, sweetness, and the notes that make each cup memorable.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? BeanTheme.crema.withOpacity(0.7)
                        : BeanTheme.mediumRoast,
                  ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add your first note'),
            ),
          ],
        ),
      ),
    );
  }
}
