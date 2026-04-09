import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/brew.dart';
import '../../models/bean.dart';
import '../../providers/app_state.dart';

/// AI Brew Optimizer: pick bean & method, fetch recipe, dial in, time, save.
class BrewLogScreen extends StatefulWidget {
  const BrewLogScreen({super.key, this.beanId});

  final String? beanId;

  @override
  State<BrewLogScreen> createState() => _BrewLogScreenState();
}

class _BrewLogScreenState extends State<BrewLogScreen> {
  String? _beanId;
  String? _method;

  double _doseGrams = 15;
  double _waterMl = 250;
  double _waterTempC = 93;
  int _grindSetting = 20;
  String? _grinder;

  final Stopwatch _brewStopwatch = Stopwatch();
  Timer? _brewTicker;
  Duration _brewElapsed = Duration.zero;

  int? _bloomTotalSeconds;
  int? _bloomRemainingSeconds;
  Timer? _bloomTimer;
  bool _bloomRunning = false;

  Map<String, dynamic>? _aiRecipe;
  bool _loadingRecipe = false;

  double _rating = 0;
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _beanId = widget.beanId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = context.read<AppState>();
      final beans = app.activeBeans;
      if (_beanId != null && beans.every((b) => b.id != _beanId)) {
        _beanId = beans.isNotEmpty ? beans.first.id : null;
      } else if (_beanId == null && beans.isNotEmpty) {
        _beanId = beans.first.id;
      }
      final profileGrinder = app.userProfile?.equipment.grinder;
      if (profileGrinder != null &&
          AppConstants.grinders.contains(profileGrinder)) {
        _grinder = profileGrinder;
      } else {
        _grinder = AppConstants.grinders.first;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _brewTicker?.cancel();
    _bloomTimer?.cancel();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _startBrewTicker() {
    _brewTicker?.cancel();
    _brewTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _brewElapsed = _brewStopwatch.elapsed);
    });
  }

  void _brewStart() {
    if (_brewStopwatch.isRunning) return;
    _brewStopwatch.start();
    _startBrewTicker();
    setState(() {});
  }

  void _brewPause() {
    _brewStopwatch.stop();
    _brewTicker?.cancel();
    _brewTicker = null;
    setState(() => _brewElapsed = _brewStopwatch.elapsed);
  }

  void _brewReset() {
    _brewStopwatch.stop();
    _brewStopwatch.reset();
    _brewTicker?.cancel();
    _brewTicker = null;
    setState(() => _brewElapsed = Duration.zero);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    final cs = (d.inMilliseconds % 1000) ~/ 100;
    return '$m:${s.toString().padLeft(2, '0')}.$cs';
  }

  void _configureBloomFromRecipe(Map<String, dynamic> recipe) {
    final sec = recipe['bloom_time_seconds'];
    if (sec is num && sec > 0) {
      _bloomTotalSeconds = sec.round();
      _bloomRemainingSeconds = _bloomTotalSeconds;
    } else {
      _bloomTotalSeconds = null;
      _bloomRemainingSeconds = null;
    }
    _bloomTimer?.cancel();
    _bloomRunning = false;
  }

  void _startBloomCountdown() {
    if (_bloomRemainingSeconds == null || _bloomRemainingSeconds! <= 0) {
      if (_bloomTotalSeconds != null && _bloomTotalSeconds! > 0) {
        setState(() => _bloomRemainingSeconds = _bloomTotalSeconds);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set a bloom time from AI recipe first, or skip bloom.')),
        );
        return;
      }
    }
    _bloomTimer?.cancel();
    _bloomRunning = true;
    _bloomTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        final r = (_bloomRemainingSeconds ?? 0) - 1;
        if (r <= 0) {
          _bloomRemainingSeconds = 0;
          _bloomRunning = false;
          t.cancel();
          _bloomTimer = null;
        } else {
          _bloomRemainingSeconds = r;
        }
      });
    });
    setState(() {});
  }

  void _pauseBloom() {
    _bloomTimer?.cancel();
    _bloomTimer = null;
    setState(() => _bloomRunning = false);
  }

  void _resetBloom() {
    _bloomTimer?.cancel();
    _bloomTimer = null;
    _bloomRunning = false;
    setState(() {
      _bloomRemainingSeconds =
          _bloomTotalSeconds != null ? _bloomTotalSeconds : null;
    });
  }

  Duration? get _bloomDurationResult {
    if (_bloomTotalSeconds == null || _bloomTotalSeconds! <= 0) return null;
    if (_bloomRemainingSeconds == 0) {
      return Duration(seconds: _bloomTotalSeconds!);
    }
    return null;
  }

  IconData _methodIcon(String method) {
    final m = method.toLowerCase();
    if (m.contains('espresso')) return Icons.coffee_maker_outlined;
    if (m.contains('french')) return Icons.local_cafe_outlined;
    if (m.contains('aero')) return Icons.air_outlined;
    if (m.contains('chemex')) return Icons.water_drop_outlined;
    if (m.contains('cold')) return Icons.ac_unit;
    return Icons.water_outlined;
  }

  Future<void> _fetchRecipe(AppState app, Bean bean) async {
    if (_method == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a brew method first.')),
      );
      return;
    }
    setState(() {
      _loadingRecipe = true;
    });
    try {
      final recipe = await app.getBrewRecipe(bean, _method!);
      if (!mounted) return;
      setState(() {
        _aiRecipe = recipe;
        if (recipe['dose_grams'] is num) {
          _doseGrams = (recipe['dose_grams'] as num).toDouble();
        }
        if (recipe['water_ml'] is num) {
          _waterMl = (recipe['water_ml'] as num).toDouble();
        }
        if (recipe['water_temp_celsius'] is num) {
          _waterTempC = (recipe['water_temp_celsius'] as num).toDouble();
        }
        if (recipe['grind_setting'] is num) {
          _grindSetting = (recipe['grind_setting'] as num).round();
        }
        if (recipe['brew_time_seconds'] is num) {
          final secs = (recipe['brew_time_seconds'] as num).round();
          _brewReset();
          _brewElapsed = Duration(seconds: secs);
        }
        _configureBloomFromRecipe(recipe);
        _loadingRecipe = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRecipe = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load recipe: $e')),
      );
    }
  }

  Future<void> _saveBrew(AppState app) async {
    if (_beanId == null || _method == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a bean and brew method.')),
      );
      return;
    }
    if (!app.canLogBrew()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Free brew log limit reached. Upgrade to keep logging.'),
        ),
      );
      return;
    }
    if (_doseGrams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dose must be greater than zero.')),
      );
      return;
    }

    final brew = Brew(
      beanId: _beanId!,
      method: _method!,
      doseGrams: _doseGrams,
      waterMl: _waterMl,
      waterTempCelsius: _waterTempC,
      grindSetting: _grindSetting,
      grinder: _grinder,
      brewTime: _brewElapsed,
      bloomTime: _bloomDurationResult,
      rating: _rating,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      aiRecipe: _aiRecipe,
    );

    await app.addBrew(brew);
    if (!mounted) return;
    context.go('/brew/${brew.id}');
  }

  Widget _stepHeader(int step, String title, String subtitle) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: BeanTheme.caramel.withOpacity(0.35),
          child: Text(
            '$step',
            style: theme.textTheme.titleMedium?.copyWith(
              color: BeanTheme.espresso,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aiRecipeCard() {
    final recipe = _aiRecipe;
    if (recipe == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final instructions = recipe['instructions'];
    final tips = recipe['tips'];
    return Card(
      color: BeanTheme.milk,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: BeanTheme.honey, size: 22),
                const SizedBox(width: 8),
                Text('AI recipe', style: theme.textTheme.titleMedium),
              ],
            ),
            if (recipe['ratio'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Target ratio: ${recipe['ratio']}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: BeanTheme.espresso,
                ),
              ),
            ],
            if (instructions is List && instructions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Steps', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ...instructions.mapIndexed((i, line) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}. ', style: theme.textTheme.bodyMedium),
                      Expanded(
                        child: Text('$line', style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (tips is List && tips.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Tips', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ...tips.map((dynamic t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.tips_and_updates_outlined, size: 18, color: BeanTheme.mint),
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

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final beans = app.activeBeans;
    final bean = _beanId != null
        ? beans.firstWhereOrNull((b) => b.id == _beanId)
        : null;

    final ratioLabel = _doseGrams > 0
        ? '1:${(_waterMl / _doseGrams).toStringAsFixed(1)}'
        : '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log a brew'),
      ),
      body: beans.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Add a bean to your library first.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/library'),
                      child: const Text('Open library'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _stepHeader(1, 'Bean', 'Choose what you brewed'),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BeanTheme.latte, width: 1.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      value:
                          beans.firstWhere((b) => b.id == _beanId, orElse: () => beans.first).id,
                      items: beans
                          .map(
                            (b) => DropdownMenuItem(
                              value: b.id,
                              child: Text('${b.name} · ${b.roaster}'),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        if (id != null) setState(() => _beanId = id);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _stepHeader(2, 'Method', 'How did you brew it?'),
                const SizedBox(height: 12),
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
                    final m = AppConstants.brewMethods[i];
                    final selected = _method == m;
                    return Material(
                      color: selected
                          ? BeanTheme.caramel.withOpacity(0.35)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => setState(() => _method = m),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _methodIcon(m),
                                size: 28,
                                color: selected ? BeanTheme.espresso : BeanTheme.caramel,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                m,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                if (bean != null)
                  FilledButton.tonalIcon(
                    onPressed: _loadingRecipe ? null : () => _fetchRecipe(app, bean),
                    icon: _loadingRecipe
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.psychology_outlined),
                    label: Text(_loadingRecipe ? 'Getting recipe…' : 'Get AI Recipe'),
                  ),
                const SizedBox(height: 16),
                _aiRecipeCard(),
                const SizedBox(height: 24),
                Text('Parameters', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _numericRow(
                          label: 'Dose',
                          unit: 'g',
                          valueText: _doseGrams.toStringAsFixed(1),
                          onMinus: () => setState(() {
                            _doseGrams = (_doseGrams - 0.5).clamp(5.0, 60.0);
                          }),
                          onPlus: () => setState(() {
                            _doseGrams = (_doseGrams + 0.5).clamp(5.0, 60.0);
                          }),
                        ),
                        const Divider(height: 28),
                        _numericRow(
                          label: 'Water',
                          unit: 'ml',
                          valueText: _waterMl.toStringAsFixed(0),
                          onMinus: () => setState(() {
                            _waterMl = (_waterMl - 10).clamp(20.0, 1000.0);
                          }),
                          onPlus: () => setState(() {
                            _waterMl = (_waterMl + 10).clamp(20.0, 1000.0);
                          }),
                        ),
                        const Divider(height: 28),
                        Text('Live ratio', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          ratioLabel,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: BeanTheme.espresso,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Divider(height: 28),
                        Text(
                          'Water temperature (${_waterTempC.round()}°C)',
                          style: theme.textTheme.titleSmall,
                        ),
                        Slider(
                          value: _waterTempC.clamp(80.0, 100.0),
                          min: 80,
                          max: 100,
                          divisions: 40,
                          label: '${_waterTempC.round()}°C',
                          onChanged: (v) => setState(() => _waterTempC = v),
                        ),
                        const Divider(height: 28),
                        _numericRow(
                          label: 'Grind setting',
                          unit: '',
                          valueText: '$_grindSetting',
                          onMinus: () => setState(() {
                            _grindSetting = (_grindSetting - 1).clamp(1, 60);
                          }),
                          onPlus: () => setState(() {
                            _grindSetting = (_grindSetting + 1).clamp(1, 60);
                          }),
                        ),
                        const Divider(height: 28),
                        Text('Grinder', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _grinder != null &&
                                  AppConstants.grinders.contains(_grinder)
                              ? _grinder
                              : AppConstants.grinders.first,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: AppConstants.grinders
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (g) => setState(() => _grinder = g),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Brew timer', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _formatDuration(_brewElapsed),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton.tonal(
                              onPressed: _brewStart,
                              child: const Text('Start'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonal(
                              onPressed: _brewPause,
                              child: const Text('Pause'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _brewReset,
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Bloom timer', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _bloomRemainingSeconds != null
                              ? '${_bloomRemainingSeconds}s left'
                              : 'Optional — use after loading an AI recipe',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton.tonal(
                              onPressed: _bloomRunning ? null : _startBloomCountdown,
                              child: const Text('Start'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonal(
                              onPressed: _bloomRunning ? _pauseBloom : null,
                              child: const Text('Pause'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _resetBloom,
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Rating', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: RatingBar.builder(
                      initialRating: _rating,
                      minRating: 0,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      glowColor: BeanTheme.honey.withOpacity(0.4),
                      itemBuilder: (context, _) => Icon(
                        Icons.star_rounded,
                        color: BeanTheme.honey,
                      ),
                      onRatingUpdate: (r) => setState(() => _rating = r),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Notes', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'How did it taste? Anything to tweak next time?',
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => _saveBrew(app),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Brew'),
                ),
              ],
            ),
    );
  }

  Widget _numericRow({
    required String label,
    required String unit,
    required String valueText,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.titleSmall),
        ),
        IconButton.filledTonal(
          onPressed: onMinus,
          icon: const Icon(Icons.remove),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            unit.isEmpty ? valueText : '$valueText $unit',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: onPlus,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
