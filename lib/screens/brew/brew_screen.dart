import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/brew.dart';
import '../../providers/app_state.dart';

/// Brew hub: history, quick methods, stats, and entry to the brew log.
class BrewScreen extends StatefulWidget {
  const BrewScreen({super.key});

  @override
  State<BrewScreen> createState() => _BrewScreenState();
}

class _BrewScreenState extends State<BrewScreen> {
  String? _methodFilter;

  static const List<String> _fallbackPopularMethods = [
    'Pour Over (V60)',
    'AeroPress',
    'Espresso',
    'French Press',
  ];

  IconData _methodIcon(String method) {
    final m = method.toLowerCase();
    if (m.contains('espresso')) return Icons.coffee_maker_outlined;
    if (m.contains('french') || m.contains('press')) return Icons.local_cafe_outlined;
    if (m.contains('aero')) return Icons.air_outlined;
    if (m.contains('chemex')) return Icons.water_drop_outlined;
    if (m.contains('cold')) return Icons.ac_unit;
    if (m.contains('moka')) return Icons.kitchen_outlined;
    if (m.contains('turkish')) return Icons.emoji_food_beverage_outlined;
    if (m.contains('siphon')) return Icons.science_outlined;
    if (m.contains('drip') || m.contains('filter')) return Icons.filter_alt_outlined;
    return Icons.water_outlined;
  }

  List<String> _quickMethods(List<Brew> brews) {
    final used = brews.map((b) => b.method).toSet().toList();
    if (used.isNotEmpty) {
      used.sort((a, b) {
        final ca = brews.where((x) => x.method == a).length;
        final cb = brews.where((x) => x.method == b).length;
        return cb.compareTo(ca);
      });
      return used.take(6).toList();
    }
    return _fallbackPopularMethods
        .where((m) => AppConstants.brewMethods.contains(m))
        .take(4)
        .toList();
  }

  List<Brew> _filteredRecent(AppState app) {
    final list = List<Brew>.from(app.recentBrews);
    if (_methodFilter != null) {
      return list.where((b) => b.method == _methodFilter).toList();
    }
    return list;
  }

  String? _favoriteMethod(List<Brew> brews) {
    if (brews.isEmpty) return null;
    final grouped = groupBy(brews, (Brew b) => b.method);
    return grouped.entries
        .map((e) => MapEntry(e.key, e.value.length))
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  Brew? _bestRatedBrew(List<Brew> brews) {
    final rated = brews.where((b) => b.rating > 0).toList();
    if (rated.isEmpty) return null;
    return rated.reduce((a, b) => a.rating >= b.rating ? a : b);
  }

  double _avgRatingThisWeek(List<Brew> brews) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recent = brews.where((b) => b.brewDate.isAfter(weekAgo) && b.rating > 0).toList();
    if (recent.isEmpty) return 0;
    return recent.map((b) => b.rating).reduce((a, b) => a + b) / recent.length;
  }

  Future<void> _onRefresh(AppState app) => app.loadData();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? BeanTheme.caramel : BeanTheme.espresso;
    final brews = app.brews;
    final recent = _filteredRecent(app);
    final quick = _quickMethods(brews);
    final favorite = _favoriteMethod(brews);
    final best = _bestRatedBrew(brews);
    final weekAvg = _avgRatingThisWeek(brews);
    final methodsInUse = brews.map((b) => b.method).toSet().toList()..sort();
    final filterMethods = methodsInUse.isNotEmpty
        ? methodsInUse
        : AppConstants.brewMethods.take(8).toList();

    return Scaffold(
      body: RefreshIndicator(
        color: BeanTheme.caramel,
        onRefresh: () => _onRefresh(app),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              floating: true,
              title: const Text('Brew Lab'),
              backgroundColor: theme.scaffoldBackgroundColor,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              sliver: SliverToBoxAdapter(
                child: _WeeklyStatsCard(
                  brewsThisWeek: app.totalBrewsThisWeek,
                  avgRatingWeek: weekAvg,
                  accent: accent,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Quick brew',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 112,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: quick.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final m = quick[i];
                          return _MethodQuickCard(
                            method: m,
                            icon: _methodIcon(m),
                            onTap: () => context.push('/brew/log'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => context.push('/brew/log'),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Start a Brew'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent brews',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        if (_methodFilter != null)
                          TextButton(
                            onPressed: () => setState(() => _methodFilter = null),
                            child: const Text('Clear filter'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('All'),
                              selected: _methodFilter == null,
                              onSelected: (_) => setState(() => _methodFilter = null),
                            ),
                          ),
                          ...filterMethods.map((m) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(m, style: const TextStyle(fontSize: 12)),
                                selected: _methodFilter == m,
                                onSelected: (sel) {
                                  setState(() => _methodFilter = sel ? m : null);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (brews.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyBrewState(onStart: () => context.push('/brew/log')),
              )
            else ...[
              if (recent.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(32),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'No brews for this method yet.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final brew = recent[index];
                        final bean = app.getBeanById(brew.beanId);
                        return _RecentBrewTile(
                          brew: brew,
                          beanName: bean?.name ?? 'Unknown bean',
                          methodIcon: _methodIcon(brew.method),
                          onTap: () => context.push('/brew/${brew.id}'),
                        );
                      },
                      childCount: recent.length,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: _StatsSection(
                    totalBrews: brews.length,
                    favoriteMethod: favorite,
                    bestBrew: best,
                    getBeanName: (id) => app.getBeanById(id)?.name ?? 'Bean',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeeklyStatsCard extends StatelessWidget {
  const _WeeklyStatsCard({
    required this.brewsThisWeek,
    required this.avgRatingWeek,
    required this.accent,
  });

  final int brewsThisWeek;
  final double avgRatingWeek;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BeanTheme.caramel.withOpacity(0.25),
              BeanTheme.honey.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This week',
                    style: theme.textTheme.titleMedium?.copyWith(color: accent),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$brewsThisWeek',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  Text(
                    'brews logged',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 56,
              color: theme.dividerColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avg rating',
                      style: theme.textTheme.titleMedium?.copyWith(color: accent),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      avgRatingWeek > 0 ? avgRatingWeek.toStringAsFixed(1) : '—',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    Text(
                      'out of 5',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodQuickCard extends StatelessWidget {
  const _MethodQuickCard({
    required this.method,
    required this.icon,
    required this.onTap,
  });

  final String method;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 140,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 32, color: BeanTheme.caramel),
                const Spacer(),
                Text(
                  method,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentBrewTile extends StatelessWidget {
  const _RecentBrewTile({
    required this.brew,
    required this.beanName,
    required this.methodIcon,
    required this.onTap,
  });

  final Brew brew;
  final String beanName;
  final IconData methodIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat.MMMd().add_jm().format(brew.brewDate);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: BeanTheme.latte,
          child: Icon(methodIcon, color: BeanTheme.espresso),
        ),
        title: Text(beanName, style: theme.textTheme.titleMedium),
        subtitle: Text(
          '${brew.method} · ${brew.ratioLabel} · ${brew.brewTimeLabel}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (brew.rating > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 18, color: BeanTheme.honey),
                  Text(
                    brew.rating.toStringAsFixed(1),
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              )
            else
              Text('—', style: theme.textTheme.labelLarge),
            Text(
              dateStr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.totalBrews,
    required this.favoriteMethod,
    required this.bestBrew,
    required this.getBeanName,
  });

  final int totalBrews;
  final String? favoriteMethod;
  final Brew? bestBrew;
  final String Function(String beanId) getBeanName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Stats', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _StatRow(label: 'Total brews', value: '$totalBrews'),
                const Divider(height: 24),
                _StatRow(
                  label: 'Favorite method',
                  value: favoriteMethod ?? '—',
                ),
                const Divider(height: 24),
                _StatRow(
                  label: 'Best rated',
                  value: bestBrew != null
                      ? '${getBeanName(bestBrew!.beanId)} · ${bestBrew!.rating.toStringAsFixed(1)}★'
                      : '—',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.bodyLarge),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _EmptyBrewState extends StatelessWidget {
  const _EmptyBrewState({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.coffee_outlined,
            size: 80,
            color: BeanTheme.caramel.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          Text(
            'Your first brew awaits',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Log a brew to track ratios, time, and taste. '
            'The AI Brew Optimizer will help you dial in every cup.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: onStart,
            child: const Text('Log your first brew'),
          ),
        ],
      ),
    );
  }
}
