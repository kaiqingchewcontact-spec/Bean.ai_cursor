import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/bean.dart';
import '../../models/brew.dart';
import '../../providers/app_state.dart';

/// Home dashboard: pantry snapshot, brew prompts, and recent activity.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Bean? _pickHeroBean(List<Bean> fresh, List<Bean> active) {
    if (fresh.isEmpty) {
      if (active.isEmpty) return null;
      final sorted = [...active]..sort((a, b) {
          final da = a.daysFromRoast;
          final db = b.daysFromRoast;
          if (da < 0 && db < 0) return 0;
          if (da < 0) return 1;
          if (db < 0) return -1;
          return da.compareTo(db);
        });
      return sorted.first;
    }
    final sorted = [...fresh]..sort((a, b) {
        final da = a.daysFromRoast < 0 ? 9999 : a.daysFromRoast;
        final db = b.daysFromRoast < 0 ? 9999 : b.daysFromRoast;
        return da.compareTo(db);
      });
    return sorted.first;
  }

  String _aiInsightSummary(AppState state) {
    final notes = state.tastingNotes.length;
    final brews = state.brews.length;
    final origins = state.userProfile?.stats.originBreakdown.length ?? 0;
    if (notes == 0 && brews == 0) {
      return 'Start logging brews and notes—Bean.ai will spot patterns in your palate.';
    }
    if (notes >= 5) {
      return 'You have rich tasting data. Open full insights for flavor trends and recipe ideas.';
    }
    if (origins > 2) {
      return 'You explore several origins. See how your preferences cluster across regions.';
    }
    return 'Your last week of brews can guide the next grind tweak—peek inside for specifics.';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final name = state.userProfile?.displayName?.trim();
    final greeting = _greetingForNow();
    final headerSubtitle = (name != null && name.isNotEmpty)
        ? '$greeting, $name'
        : greeting;

    final pantryCount = state.activeBeans.length;
    final brewsWeek = state.totalBrewsThisWeek;
    final avgRating = state.averageRating;
    final avgLabel = avgRating > 0 ? avgRating.toStringAsFixed(1) : '—';

    final fresh = state.freshBeans;
    final aging = state.agingBeans;
    final heroBean = _pickHeroBean(fresh, state.activeBeans);
    final recent = state.recentBrews;

    final surface = isDark ? BeanTheme.darkSurface : BeanTheme.milk;
    final cardColor = isDark ? BeanTheme.darkCard : Colors.white;
    final onSurface = isDark ? BeanTheme.crema : BeanTheme.espresso;
    final muted = isDark ? BeanTheme.crema.withOpacity(0.65) : BeanTheme.lightRoast;

    return Scaffold(
      backgroundColor: surface,
      body: RefreshIndicator(
        color: BeanTheme.caramel,
        onRefresh: () => state.loadData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                headerSubtitle,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your pantry at a glance',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.push('/settings'),
                          style: IconButton.styleFrom(
                            backgroundColor: cardColor,
                            foregroundColor: onSurface,
                          ),
                          icon: const Icon(Icons.tune_rounded),
                          tooltip: 'Settings',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.inventory_2_outlined,
                            label: 'In pantry',
                            value: '$pantryCount',
                            accent: BeanTheme.mint,
                            cardColor: cardColor,
                            onSurface: onSurface,
                            muted: muted,
                            onTap: () => context.go('/library'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.local_cafe_outlined,
                            label: 'Brews (7d)',
                            value: '$brewsWeek',
                            accent: BeanTheme.caramel,
                            cardColor: cardColor,
                            onSurface: onSurface,
                            muted: muted,
                            onTap: () => context.go('/brew'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.star_outline_rounded,
                            label: 'Avg rating',
                            value: avgLabel,
                            accent: BeanTheme.honey,
                            cardColor: cardColor,
                            onSurface: onSurface,
                            muted: muted,
                            onTap: () => context.go('/journal'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: heroBean == null
                    ? _EmptyHeroCard(
                        cardColor: cardColor,
                        onSurface: onSurface,
                        muted: muted,
                        onAddBeans: () => context.go('/library'),
                        onScan: () => context.push('/scan'),
                      )
                    : _BrewNowHeroCard(
                        bean: heroBean,
                        isPeakFresh: fresh.contains(heroBean),
                        onCardTap: () => context.push('/library/${heroBean.id}'),
                        onBrew: () => context.push(
                          '/brew/log?beanId=${Uri.encodeComponent(heroBean.id)}',
                        ),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 0, 8),
                child: Row(
                  children: [
                    Text(
                      'Fresh beans',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/library'),
                      child: const Text('See all'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            if (fresh.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _EmptyFreshBeans(
                    cardColor: cardColor,
                    onSurface: onSurface,
                    muted: muted,
                    onLibrary: () => context.go('/library'),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 132,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: fresh.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final bean = fresh[i];
                      return _FreshBeanCard(
                        bean: bean,
                        cardColor: cardColor,
                        onSurface: onSurface,
                        muted: muted,
                        onTap: () => context.push('/library/${bean.id}'),
                      );
                    },
                  ),
                ),
              ),
            if (aging.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: BeanTheme.honey, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Aging alert',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: aging.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final bean = aging[i];
                    return _AgingBeanTile(
                      bean: bean,
                      onTap: () => context.push('/library/${bean.id}'),
                    );
                  },
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  'Recent brews',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (recent.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _EmptyBrews(
                    cardColor: cardColor,
                    onSurface: onSurface,
                    muted: muted,
                    onBrew: () => context.go('/brew'),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final brew = recent[i];
                    final bean = state.getBeanById(brew.beanId);
                    return _RecentBrewTile(
                      brew: brew,
                      beanName: bean?.name ?? 'Unknown bean',
                      cardColor: cardColor,
                      onSurface: onSurface,
                      muted: muted,
                      onTap: () => context.push('/brew/${brew.id}'),
                    );
                  },
                ),
              ),
            if (state.isPremium) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                    'AI insights',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _AiInsightTeaser(
                    summary: _aiInsightSummary(state),
                    onOpen: () => context.push('/journal/insights'),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: _QuickScanCard(
                  onTap: () => context.push('/scan'),
                  cardColor: cardColor,
                  onSurface: onSurface,
                  muted: muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.cardColor,
    required this.onSurface,
    required this.muted,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color cardColor;
  final Color onSurface;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrewNowHeroCard extends StatelessWidget {
  const _BrewNowHeroCard({
    required this.bean,
    required this.isPeakFresh,
    required this.onCardTap,
    required this.onBrew,
  });

  final Bean bean;
  final bool isPeakFresh;
  final VoidCallback onCardTap;
  final VoidCallback onBrew;

  @override
  Widget build(BuildContext context) {
    final days = bean.daysFromRoast;
    final daysLine = days < 0
        ? 'Roast date unknown'
        : '$days day${days == 1 ? '' : 's'} from roast';

    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onCardTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BeanTheme.espresso,
                BeanTheme.espresso.withOpacity(0.88),
                BeanTheme.lightRoast.withOpacity(0.92),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: BeanTheme.crema,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPeakFresh ? 'At peak' : 'Brew now',
                            style: const TextStyle(
                              color: BeanTheme.crema,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  bean.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bean.roaster,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  daysLine,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: BeanTheme.crema,
                      foregroundColor: BeanTheme.espresso,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onBrew,
                    icon: const Icon(Icons.coffee_maker_rounded),
                    label: const Text(
                      'Brew',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHeroCard extends StatelessWidget {
  const _EmptyHeroCard({
    required this.cardColor,
    required this.onSurface,
    required this.muted,
    required this.onAddBeans,
    required this.onScan,
  });

  final Color cardColor;
  final Color onSurface;
  final Color muted;
  final VoidCallback onAddBeans;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BeanTheme.latte),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.coffee_outlined, color: BeanTheme.caramel, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No beans ready to brew',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add beans to your library or scan a bag to build your pantry.',
            style: TextStyle(color: muted, height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onAddBeans,
                  child: const Text('Open library'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onScan,
                  child: const Text('Scan bag'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FreshBeanCard extends StatelessWidget {
  const _FreshBeanCard({
    required this.bean,
    required this.cardColor,
    required this.onSurface,
    required this.muted,
    required this.onTap,
  });

  final Bean bean;
  final Color cardColor;
  final Color onSurface;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = bean.daysFromRoast;
    final daysText =
        days < 0 ? '—' : '${days}d from roast';

    Color badgeBg = BeanTheme.mint.withOpacity(0.18);
    Color badgeFg = BeanTheme.mint;
    if (bean.freshnessLevel == FreshnessLevel.peak) {
      badgeBg = BeanTheme.cherry.withOpacity(0.12);
      badgeFg = BeanTheme.cherry;
    }

    return SizedBox(
      width: 200,
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bean.freshnessLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeFg,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.eco_rounded, size: 18, color: BeanTheme.mint),
                  ],
                ),
                const Spacer(),
                Text(
                  bean.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bean.roaster,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  daysText,
                  style: TextStyle(
                    fontSize: 12,
                    color: muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFreshBeans extends StatelessWidget {
  const _EmptyFreshBeans({
    required this.cardColor,
    required this.onSurface,
    required this.muted,
    required this.onLibrary,
  });

  final Color cardColor;
  final Color onSurface;
  final Color muted;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BeanTheme.latte),
      ),
      child: Row(
        children: [
          Icon(Icons.grass_rounded, color: BeanTheme.mint, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nothing at peak freshness',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add roast dates to see peak windows, or rest new beans a few days.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.3),
                ),
                TextButton(
                  onPressed: onLibrary,
                  child: const Text('Manage pantry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgingBeanTile extends StatelessWidget {
  const _AgingBeanTile({required this.bean, required this.onTap});

  final Bean bean;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = bean.daysFromRoast;
    final daysLine =
        days < 0 ? 'Roast date unknown' : '$days days since roast';

    return Material(
      color: BeanTheme.honey.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BeanTheme.honey.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.hourglass_top_rounded,
                    color: BeanTheme.honey.darken(0.08)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bean.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: BeanTheme.espresso,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${bean.roaster} · $daysLine',
                      style: TextStyle(
                        fontSize: 12,
                        color: BeanTheme.espresso.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bean.freshnessLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: BeanTheme.espresso,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: BeanTheme.espresso),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBrews extends StatelessWidget {
  const _EmptyBrews({
    required this.cardColor,
    required this.onSurface,
    required this.muted,
    required this.onBrew,
  });

  final Color cardColor;
  final Color onSurface;
  final Color muted;
  final VoidCallback onBrew;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BeanTheme.latte),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  color: BeanTheme.caramel, size: 28),
              const SizedBox(width: 10),
              Text(
                'No brews logged yet',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Log a brew to track recipes, ratings, and AI feedback over time.',
            style: TextStyle(color: muted, height: 1.35),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onBrew,
            child: const Text('Start a brew'),
          ),
        ],
      ),
    );
  }
}

class _RecentBrewTile extends StatelessWidget {
  const _RecentBrewTile({
    required this.brew,
    required this.beanName,
    required this.cardColor,
    required this.onSurface,
    required this.muted,
    required this.onTap,
  });

  final Brew brew;
  final String beanName;
  final Color cardColor;
  final Color onSurface;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat.MMMd().format(brew.brewDate);
    final rating = brew.rating;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BeanTheme.latte.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.coffee_rounded,
                  color: BeanTheme.espresso,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brew.method,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      beanName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StarRow(rating: rating),
                        const Spacer(),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: BeanTheme.lightRoast),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final full = rating.floor().clamp(0, 5);
    final hasHalf = (rating - full) >= 0.5 && full < 5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < full) {
          return const Icon(Icons.star_rounded,
              size: 18, color: BeanTheme.honey);
        }
        if (i == full && hasHalf) {
          return const Icon(Icons.star_half_rounded,
              size: 18, color: BeanTheme.honey);
        }
        return Icon(Icons.star_outline_rounded,
            size: 18, color: BeanTheme.lightRoast.withOpacity(0.45));
      }),
    );
  }
}

class _AiInsightTeaser extends StatelessWidget {
  const _AiInsightTeaser({
    required this.summary,
    required this.onOpen,
  });

  final String summary;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                BeanTheme.blueberry.withOpacity(0.22),
                BeanTheme.mint.withOpacity(0.18),
              ],
            ),
            border: Border.all(color: BeanTheme.blueberry.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      color: BeanTheme.blueberry),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Premium · AI snapshot',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: BeanTheme.espresso,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        summary,
                        style: TextStyle(
                          color: BeanTheme.espresso.withOpacity(0.78),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Text(
                            'View full insights',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: BeanTheme.cherry,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 18, color: BeanTheme.cherry),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickScanCard extends StatelessWidget {
  const _QuickScanCard({
    required this.onTap,
    required this.cardColor,
    required this.onSurface,
    required this.muted,
  });

  final VoidCallback onTap;
  final Color cardColor;
  final Color onSurface;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: BeanTheme.espresso.withOpacity(0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BeanTheme.cherry.withOpacity(0.15),
                      BeanTheme.honey.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.document_scanner_rounded,
                    color: BeanTheme.cherry, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick scan',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capture a bag label—add beans in seconds.',
                      style: TextStyle(color: muted, fontSize: 13, height: 1.25),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_circle_right_rounded,
                  color: BeanTheme.caramel, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

extension on Color {
  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }
}
