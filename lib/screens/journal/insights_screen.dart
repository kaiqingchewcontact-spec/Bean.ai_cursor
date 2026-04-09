import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/bean.dart';
import '../../models/tasting_note.dart';
import '../../providers/app_state.dart';

/// AI palate insights with charts; premium-gated for full experience.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  Map<String, dynamic>? _ai;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final app = context.read<AppState>();
    if (!app.isPremium) return;
    setState(() => _loading = true);
    try {
      final data = await app.getPalateInsights();
      if (mounted) setState(() => _ai = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String? _categoryForDescriptor(String d) {
    for (final cat in AppConstants.flavorCategories) {
      final list = AppConstants.flavorWheel[cat];
      if (list != null && list.contains(d)) return cat;
    }
    return null;
  }

  static Map<String, double> _avgRadar(List<TastingNote> notes) {
    if (notes.isEmpty) {
      return {
        'Aroma': 0,
        'Acidity': 0,
        'Sweetness': 0,
        'Body': 0,
        'Balance': 0,
        'Aftertaste': 0,
        'Cleanliness': 0,
      };
    }
    double sum(String key) {
      switch (key) {
        case 'Aroma':
          return notes.map((n) => n.aroma).reduce((a, b) => a + b);
        case 'Acidity':
          return notes.map((n) => n.acidity).reduce((a, b) => a + b);
        case 'Sweetness':
          return notes.map((n) => n.sweetness).reduce((a, b) => a + b);
        case 'Body':
          return notes.map((n) => n.body).reduce((a, b) => a + b);
        case 'Balance':
          return notes.map((n) => n.balance).reduce((a, b) => a + b);
        case 'Aftertaste':
          return notes.map((n) => n.aftertaste).reduce((a, b) => a + b);
        case 'Cleanliness':
          return notes.map((n) => n.cleanliness).reduce((a, b) => a + b);
        default:
          return 0;
      }
    }

    const keys = [
      'Aroma',
      'Acidity',
      'Sweetness',
      'Body',
      'Balance',
      'Aftertaste',
      'Cleanliness',
    ];
    final n = notes.length.toDouble();
    return {for (final k in keys) k: sum(k) / n};
  }

  static Map<String, int> _categoryCounts(List<TastingNote> notes) {
    final m = <String, int>{};
    for (final note in notes) {
      for (final d in note.descriptors) {
        final c = _categoryForDescriptor(d);
        if (c != null) m[c] = (m[c] ?? 0) + 1;
      }
    }
    return m;
  }

  static Map<String, List<double>> _scoresByOrigin(
    List<TastingNote> notes,
    List<Bean> beans,
  ) {
    final byOrigin = <String, List<double>>{};
    for (final n in notes) {
      if (n.beanId == null) continue;
      try {
        final bean = beans.firstWhere((b) => b.id == n.beanId);
        byOrigin.putIfAbsent(bean.origin, () => []).add(n.overallScore);
      } catch (_) {}
    }
    return byOrigin;
  }

  static List<FlSpot> _trendSpots(List<TastingNote> notes) {
    if (notes.length < 2) return [const FlSpot(0, 0), const FlSpot(1, 0)];
    final sorted = List<TastingNote>.from(notes)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final spots = <FlSpot>[];
    double sum = 0;
    for (var i = 0; i < sorted.length; i++) {
      sum += sorted[i].overallScore;
      final avg = sum / (i + 1);
      spots.add(FlSpot(i.toDouble(), avg));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final notes = app.tastingNotes;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? BeanTheme.darkCard : Colors.white;

    if (!app.isPremium) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Palate')),
        body: _PaywallPrompt(onUpgrade: () => context.push('/paywall')),
      );
    }

    final radar = _avgRadar(notes);
    final radarKeys = radar.keys.toList();
    final radarValues = radarKeys.map((k) => radar[k]!).toList();

    final catCounts = _categoryCounts(notes);
    final topCats = catCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final pieTotal = topCats.fold<int>(0, (s, e) => s + e.value);

    final originMap = _scoresByOrigin(notes, app.beans);
    final originAvgs = originMap.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return MapEntry(e.key, avg);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topOrigins = originAvgs.take(6).toList();

    final trendSpots = _trendSpots(notes);
    final maxY = trendSpots.map((s) => s.y).fold<double>(10, (a, b) => a > b ? a : b);
    final minY = trendSpots.map((s) => s.y).fold<double>(10, (a, b) => a < b ? a : b);

    final avgAcidity = notes.isEmpty
        ? 0.0
        : notes.map((n) => n.acidity).reduce((a, b) => a + b) / notes.length;
    final highAcidNotes = notes.where((n) => n.acidity >= 7).length;
    final acidityOutOf5 = (avgAcidity / 10 * 5).clamp(0.0, 5.0);

    final summary = _ai?['summary'] as String? ??
        (notes.isEmpty
            ? 'Log a few tasting notes to unlock richer AI insights about your palate.'
            : 'Your journal is growing—keep logging cups to refine these insights.');
    final suggestion = _ai?['suggestion'] as String? ??
        'Try a bean from a new origin that matches your top flavor categories.';

    final palette = [
      BeanTheme.caramel,
      BeanTheme.cherry,
      BeanTheme.mint,
      BeanTheme.blueberry,
      BeanTheme.honey,
      BeanTheme.lightRoast,
      BeanTheme.mediumRoast,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Palate'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: BeanTheme.caramel,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              'Your Palate',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Patterns from ${notes.length} tasting ${notes.length == 1 ? 'note' : 'notes'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? BeanTheme.crema.withOpacity(0.55) : BeanTheme.lightRoast,
                  ),
            ),
            const SizedBox(height: 20),
            _InsightCard(
              color: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Average sensory profile', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (notes.isEmpty)
                    const Text('Add tasting notes to see your radar.')
                  else
                    SizedBox(
                      height: 240,
                      child: RadarChart(
                        RadarChartData(
                          dataSets: [
                            RadarDataSet(
                              fillColor: BeanTheme.caramel.withOpacity(0.22),
                              borderColor: BeanTheme.caramel,
                              borderWidth: 2,
                              entryRadius: 4,
                              dataEntries:
                                  radarValues.map((v) => RadarEntry(value: v)).toList(),
                            ),
                          ],
                          radarBackgroundColor:
                              isDark ? BeanTheme.darkBg.withOpacity(0.4) : BeanTheme.milk,
                          borderData: FlBorderData(show: false),
                          radarBorderData: BorderSide(
                            color: isDark
                                ? BeanTheme.mediumRoast.withOpacity(0.35)
                                : BeanTheme.latte,
                          ),
                          gridBorderData: BorderSide(
                            color: isDark
                                ? BeanTheme.mediumRoast.withOpacity(0.22)
                                : BeanTheme.latte,
                          ),
                          tickBorderData: BorderSide(
                            color: isDark
                                ? BeanTheme.mediumRoast.withOpacity(0.18)
                                : BeanTheme.latte,
                          ),
                          titleTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: isDark
                                    ? BeanTheme.crema.withOpacity(0.75)
                                    : BeanTheme.mediumRoast,
                              ),
                          tickCount: 5,
                          ticksTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                color: isDark
                                    ? BeanTheme.crema.withOpacity(0.35)
                                    : BeanTheme.lightRoast,
                              ),
                          getTitle: (index, angle) {
                            final t = radarKeys[index % radarKeys.length];
                            return RadarChartTitle(
                              text: t.length > 8 ? '${t.substring(0, 7)}…' : t,
                              angle: angle,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    color: cardColor,
                    title: 'Acidity affinity',
                    value: '${acidityOutOf5.toStringAsFixed(1)}/5',
                    subtitle:
                        '$highAcidNotes cup${highAcidNotes == 1 ? '' : 's'} rated 7+ acidity',
                    icon: Icons.bubble_chart_rounded,
                    accent: BeanTheme.cherry,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStatCard(
                    color: cardColor,
                    title: 'Avg sweetness',
                    value: notes.isEmpty
                        ? '—'
                        : '${(notes.map((n) => n.sweetness).reduce((a, b) => a + b) / notes.length).toStringAsFixed(1)}/10',
                    subtitle: 'From your sliders',
                    icon: Icons.cake_rounded,
                    accent: BeanTheme.honey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InsightCard(
              color: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flavor categories', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'How often your descriptors map to each wheel category',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? BeanTheme.crema.withOpacity(0.5) : BeanTheme.lightRoast,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (pieTotal == 0)
                    const Text('Tag flavors on your notes to populate this chart.')
                  else
                    SizedBox(
                      height: 200,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 36,
                                sections: List.generate(topCats.length.clamp(0, 7), (i) {
                                  final e = topCats[i];
                                  final pct = e.value / pieTotal;
                                  return PieChartSectionData(
                                    color: palette[i % palette.length].withOpacity(0.85),
                                    value: e.value.toDouble(),
                                    title: '${(pct * 100).round()}%',
                                    radius: 52,
                                    titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(topCats.length.clamp(0, 7), (i) {
                                final e = topCats[i];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: palette[i % palette.length],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          e.key,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.labelMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (topCats.isNotEmpty && pieTotal > 0) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: topCats.isEmpty
                              ? 4
                              : topCats.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble() + 1,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (v, m) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= topCats.length.clamp(0, 8)) {
                                    return const SizedBox.shrink();
                                  }
                                  final label = topCats[i].key;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      label.length > 5 ? '${label.substring(0, 4)}…' : label,
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color: isDark
                                  ? BeanTheme.mediumRoast.withOpacity(0.2)
                                  : BeanTheme.latte,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(topCats.length.clamp(0, 8), (i) {
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: topCats[i].value.toDouble(),
                                  width: 14,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      palette[i % palette.length].withOpacity(0.45),
                                      palette[i % palette.length],
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _InsightCard(
              color: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Origins you score highest', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (topOrigins.isEmpty)
                    const Text('Link notes to beans with origins to see this breakdown.')
                  else
                    ...topOrigins.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(e.key, style: Theme.of(context).textTheme.titleSmall),
                            ),
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (e.value / 10).clamp(0.0, 1.0),
                                  minHeight: 10,
                                  backgroundColor:
                                      isDark ? BeanTheme.darkBg : BeanTheme.latte,
                                  color: BeanTheme.mint,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              e.value.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _InsightCard(
              color: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Brewing enjoyment trend', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Running average of your overall scores over time',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? BeanTheme.crema.withOpacity(0.5) : BeanTheme.lightRoast,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (notes.length < 2)
                    const Text('Log at least two notes to see a trend line.')
                  else
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          minY: (minY - 0.5).clamp(0, 10),
                          maxY: (maxY + 0.5).clamp(0, 10),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color: isDark
                                  ? BeanTheme.mediumRoast.withOpacity(0.2)
                                  : BeanTheme.latte,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                interval: (trendSpots.length / 4).ceilToDouble().clamp(1, 99),
                                getTitlesWidget: (v, m) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= trendSpots.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final sorted = List<TastingNote>.from(notes)
                                    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                                  if (i >= sorted.length) return const SizedBox.shrink();
                                  return Text(
                                    DateFormat.Md().format(sorted[i].createdAt),
                                    style: Theme.of(context).textTheme.labelSmall,
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                interval: 2,
                                getTitlesWidget: (v, m) => Text(
                                  v.toInt().toString(),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: trendSpots,
                              isCurved: true,
                              color: BeanTheme.blueberry,
                              barWidth: 3,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (s, p, bar, i) => FlDotCirclePainter(
                                  radius: 3,
                                  color: BeanTheme.cherry,
                                  strokeWidth: 0,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    BeanTheme.blueberry.withOpacity(0.25),
                                    BeanTheme.blueberry.withOpacity(0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _InsightCard(
              color: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: BeanTheme.blueberry, size: 22),
                      const SizedBox(width: 8),
                      Text('AI summary', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(summary, style: Theme.of(context).textTheme.bodyLarge),
                  if (_loading) const LinearProgressIndicator(minHeight: 2),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _InsightCard(
              color: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: BeanTheme.honey, size: 22),
                      const SizedBox(width: 8),
                      Text('Try next', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(suggestion, style: Theme.of(context).textTheme.bodyMedium),
                  if (_ai?['top_origins'] is List) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Origins to explore: ${(_ai!['top_origins'] as List).join(', ')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? BeanTheme.crema.withOpacity(0.65) : BeanTheme.mediumRoast,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? BeanTheme.mediumRoast.withOpacity(0.35) : BeanTheme.latte,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: BeanTheme.espresso.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final Color color;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
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
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? BeanTheme.crema.withOpacity(0.55) : BeanTheme.lightRoast,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PaywallPrompt extends StatelessWidget {
  const _PaywallPrompt({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    BeanTheme.caramel.withOpacity(0.45),
                    BeanTheme.honey.withOpacity(0.15),
                  ],
                ),
              ),
              child: const Icon(Icons.lock_rounded, size: 48, color: BeanTheme.espresso),
            ),
            const SizedBox(height: 24),
            Text(
              'Unlock your palate dashboard',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Premium members get AI summaries, full charts, origin breakdowns, and personalized bean ideas based on every journal entry.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? BeanTheme.crema.withOpacity(0.7)
                        : BeanTheme.mediumRoast,
                  ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: onUpgrade,
              child: const Text('See Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
