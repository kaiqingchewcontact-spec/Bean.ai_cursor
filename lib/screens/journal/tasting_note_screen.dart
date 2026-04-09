import 'dart:ui' show FontFeature;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/tasting_note.dart';
import '../../providers/app_state.dart';

/// Create a tasting note with sliders, radar preview, flavor chips, and optional AI summary.
class TastingNoteScreen extends StatefulWidget {
  const TastingNoteScreen({super.key, this.brewId});

  final String? brewId;

  @override
  State<TastingNoteScreen> createState() => _TastingNoteScreenState();
}

class _TastingNoteScreenState extends State<TastingNoteScreen> {
  String? _beanId;
  double _aroma = 5;
  double _acidity = 5;
  double _sweetness = 5;
  double _body = 5;
  double _balance = 5;
  double _aftertaste = 5;
  double _cleanliness = 5;
  double _overall = 5;
  final Set<String> _descriptors = {};
  final TextEditingController _notes = TextEditingController();
  Map<String, dynamic>? _aiSummary;
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromBrew());
  }

  void _prefillFromBrew() {
    final app = context.read<AppState>();
    final bid = widget.brewId;
    if (bid == null) return;
    for (final b in app.brews) {
      if (b.id == bid) {
        setState(() => _beanId = b.beanId);
        break;
      }
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  List<double> get _radarValues => [
        _aroma,
        _acidity,
        _sweetness,
        _body,
        _balance,
        _aftertaste,
        _cleanliness,
      ];

  static const List<String> _radarTitles = [
    'Aroma',
    'Acidity',
    'Sweet',
    'Body',
    'Balance',
    'After',
    'Clean',
  ];

  Future<void> _runAiSummary(AppState app) async {
    if (!app.isPremium) {
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Premium feature'),
          content: const Text(
            'AI tasting summaries help you spot patterns faster. Upgrade to unlock.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('View plans')),
          ],
        ),
      );
      if (go == true && mounted) context.push('/paywall');
      return;
    }

    setState(() => _aiLoading = true);
    try {
      final desc = _descriptors.isEmpty ? 'none listed' : _descriptors.join(', ');
      final prompt =
          'Summarize this coffee tasting in 2 short sentences for a journal. '
          'Overall ${_overall.toStringAsFixed(1)}/10. '
          'Profile: aroma $_aroma, acidity $_acidity, sweetness $_sweetness, body $_body, '
          'balance $_balance, aftertaste $_aftertaste, cleanliness $_cleanliness. '
          'Descriptors: $desc. Taster notes: ${_notes.text.trim().isEmpty ? "none" : _notes.text.trim()}';
      final text = await app.aiService.getBrewCoaching(prompt);
      if (mounted) {
        setState(() {
          _aiSummary = {
            'summary': text,
            'at': DateTime.now().toIso8601String(),
          };
        });
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _save(AppState app) async {
    if (_beanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a bean for this note')),
      );
      return;
    }
    final note = TastingNote(
      brewId: widget.brewId,
      beanId: _beanId,
      overallScore: _overall,
      aroma: _aroma,
      acidity: _acidity,
      sweetness: _sweetness,
      body: _body,
      balance: _balance,
      aftertaste: _aftertaste,
      cleanliness: _cleanliness,
      descriptors: _descriptors.toList()..sort(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      aiSummary: _aiSummary,
    );
    await app.addTastingNote(note);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final beans = app.activeBeans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasting note'),
        actions: [
          TextButton(
            onPressed: () => _save(app),
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionTitle(title: 'Bean', subtitle: 'What are you tasting?'),
          const SizedBox(height: 8),
          if (beans.isEmpty)
            Text(
              'Add a bean to your library before logging a tasting note.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? BeanTheme.crema.withOpacity(0.65)
                        : BeanTheme.mediumRoast,
                  ),
            )
          else
            DropdownButtonFormField<String>(
              value: _beanId != null && beans.any((b) => b.id == _beanId) ? _beanId : null,
              decoration: const InputDecoration(
                labelText: 'Select bean',
                prefixIcon: Icon(Icons.coffee_rounded),
              ),
              items: beans
                  .map(
                    (b) => DropdownMenuItem(
                      value: b.id,
                      child: Text('${b.name} · ${b.roaster}', overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _beanId = v),
            ),
          const SizedBox(height: 28),
          _SectionTitle(title: 'Overall impression', subtitle: 'How much did you enjoy the cup?'),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                RatingBar.builder(
                  initialRating: _overall / 2,
                  minRating: 0.5,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 40,
                  unratedColor: (isDark ? BeanTheme.crema : BeanTheme.espresso).withOpacity(0.2),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star_rounded,
                    color: BeanTheme.honey,
                  ),
                  onRatingUpdate: (r) => setState(() => _overall = (r * 2).clamp(0.0, 10.0)),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_overall.toStringAsFixed(1)} / 10',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: BeanTheme.caramel,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionTitle(title: 'Sensory profile', subtitle: 'Slide to score each attribute (0–10)'),
          const SizedBox(height: 12),
          _ScoreSlider(
            label: 'Aroma',
            value: _aroma,
            icon: Icons.air_rounded,
            onChanged: (v) => setState(() => _aroma = v),
            accent: BeanTheme.blueberry,
          ),
          _ScoreSlider(
            label: 'Acidity',
            value: _acidity,
            icon: Icons.bubble_chart_rounded,
            onChanged: (v) => setState(() => _acidity = v),
            accent: BeanTheme.cherry,
          ),
          _ScoreSlider(
            label: 'Sweetness',
            value: _sweetness,
            icon: Icons.cake_rounded,
            onChanged: (v) => setState(() => _sweetness = v),
            accent: BeanTheme.honey,
          ),
          _ScoreSlider(
            label: 'Body',
            value: _body,
            icon: Icons.water_drop_rounded,
            onChanged: (v) => setState(() => _body = v),
            accent: BeanTheme.caramel,
          ),
          _ScoreSlider(
            label: 'Balance',
            value: _balance,
            icon: Icons.balance_rounded,
            onChanged: (v) => setState(() => _balance = v),
            accent: BeanTheme.mint,
          ),
          _ScoreSlider(
            label: 'Aftertaste',
            value: _aftertaste,
            icon: Icons.more_horiz_rounded,
            onChanged: (v) => setState(() => _aftertaste = v),
            accent: BeanTheme.mediumRoast,
          ),
          _ScoreSlider(
            label: 'Cleanliness',
            value: _cleanliness,
            icon: Icons.auto_fix_high_rounded,
            onChanged: (v) => setState(() => _cleanliness = v),
            accent: BeanTheme.lightRoast,
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: 'Radar preview', subtitle: 'Your cup shape at a glance'),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: BeanTheme.caramel.withOpacity(0.25),
                    borderColor: BeanTheme.caramel,
                    borderWidth: 2,
                    entryRadius: 4,
                    dataEntries: _radarValues.map((v) => RadarEntry(value: v)).toList(),
                  ),
                ],
                radarBackgroundColor: isDark
                    ? BeanTheme.darkBg.withOpacity(0.5)
                    : BeanTheme.milk,
                borderData: FlBorderData(show: false),
                radarBorderData: BorderSide(
                  color: isDark ? BeanTheme.mediumRoast.withOpacity(0.4) : BeanTheme.latte,
                ),
                gridBorderData: BorderSide(
                  color: isDark ? BeanTheme.mediumRoast.withOpacity(0.25) : BeanTheme.latte,
                ),
                tickBorderData: BorderSide(
                  color: isDark ? BeanTheme.mediumRoast.withOpacity(0.2) : BeanTheme.latte,
                ),
                titleTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: isDark ? BeanTheme.crema.withOpacity(0.75) : BeanTheme.mediumRoast,
                    ),
                tickCount: 5,
                ticksTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: isDark ? BeanTheme.crema.withOpacity(0.35) : BeanTheme.lightRoast,
                    ),
                getTitle: (index, angle) {
                  return RadarChartTitle(
                    text: _radarTitles[index % _radarTitles.length],
                    angle: angle,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 28),
          _SectionTitle(
            title: 'Flavor descriptors',
            subtitle: 'Tap a category, then pick chips (flavor wheel)',
          ),
          const SizedBox(height: 8),
          ...AppConstants.flavorCategories.map((cat) {
            final options = AppConstants.flavorWheel[cat] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isDark ? BeanTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: ExpansionTile(
                  key: PageStorageKey('cat_$cat'),
                  title: Text(
                    cat,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: options.map((d) {
                        final selected = _descriptors.contains(d);
                        return FilterChip(
                          label: Text(d),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              if (selected) {
                                _descriptors.remove(d);
                              } else {
                                _descriptors.add(d);
                              }
                            });
                          },
                          selectedColor: BeanTheme.caramel.withOpacity(0.35),
                          checkmarkColor: BeanTheme.espresso,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          _SectionTitle(title: 'Notes', subtitle: 'Anything else worth remembering?'),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              hintText: 'Brew method, grind, water, or surprise flavors…',
            ),
          ),
          const SizedBox(height: 24),
          if (_aiSummary != null && _aiSummary!['summary'] != null) ...[
            _SectionTitle(title: 'AI summary', subtitle: 'Generated from your scores & notes'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    BeanTheme.blueberry.withOpacity(0.15),
                    BeanTheme.mint.withOpacity(0.12),
                  ],
                ),
                border: Border.all(color: BeanTheme.blueberry.withOpacity(0.25)),
              ),
              child: Text(
                '${_aiSummary!['summary']}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            onPressed: _aiLoading ? null : () => _runAiSummary(app),
            icon: _aiLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(app.isPremium ? 'Get AI summary' : 'Get AI summary (Premium)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: BeanTheme.blueberry,
              side: BorderSide(color: BeanTheme.blueberry.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _save(app),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Save tasting note'),
            style: FilledButton.styleFrom(
              backgroundColor: BeanTheme.espresso,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? BeanTheme.crema.withOpacity(0.55) : BeanTheme.lightRoast,
              ),
        ),
      ],
    );
  }
}

class _ScoreSlider extends StatelessWidget {
  const _ScoreSlider({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
    required this.accent,
  });

  final String label;
  final double value;
  final IconData icon;
  final ValueChanged<double> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? BeanTheme.darkCard : BeanTheme.latte,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        value.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accent,
                    inactiveTrackColor: accent.withOpacity(0.2),
                    thumbColor: accent,
                    overlayColor: accent.withOpacity(0.15),
                  ),
                  child: Slider(
                    min: 0,
                    max: 10,
                    divisions: 100,
                    value: value.clamp(0, 10),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
