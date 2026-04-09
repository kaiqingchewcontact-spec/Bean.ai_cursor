import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/bean.dart';
import '../../providers/app_state.dart';

/// Review and correct AI scan results, then add the bean to the library.
class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _raw;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _roasterCtrl;
  late final TextEditingController _regionCtrl;
  late final TextEditingController _varietalCtrl;
  late final TextEditingController _descriptionCtrl;

  String _origin = AppConstants.origins.first;
  String _process = AppConstants.processes.first;
  String _roastLevel = AppConstants.roastLevels[2];
  final Set<String> _selectedNotes = {};
  double _confidence = 0.5;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _roasterCtrl = TextEditingController();
    _regionCtrl = TextEditingController();
    _varietalCtrl = TextEditingController();
    _descriptionCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAnalysis());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roasterCtrl.dispose();
    _regionCtrl.dispose();
    _varietalCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    final app = context.read<AppState>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await app.aiService.analyzeBeanImage(widget.imagePath);
      if (!mounted) return;
      final notes = (data['tastingNotes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];
      setState(() {
        _raw = data;
        _confidence = (data['confidence'] as num?)?.toDouble() ?? 0.5;
        _nameCtrl.text = data['name'] as String? ?? '';
        _roasterCtrl.text = data['roaster'] as String? ?? '';
        _regionCtrl.text = data['region'] as String? ?? '';
        _varietalCtrl.text = data['varietal'] as String? ?? '';
        _descriptionCtrl.text = data['description'] as String? ?? '';
        _origin = _pickClosest(AppConstants.origins, data['origin'] as String?) ??
            AppConstants.origins.first;
        _process = _pickClosest(AppConstants.processes, data['process'] as String?) ??
            AppConstants.processes.first;
        _roastLevel =
            _pickClosest(AppConstants.roastLevels, data['roastLevel'] as String?) ??
                AppConstants.roastLevels[2];
        _selectedNotes
          ..clear()
          ..addAll(notes);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String? _pickClosest(List<String> options, String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.trim();
    for (final o in options) {
      if (o.toLowerCase() == v.toLowerCase()) return o;
    }
    for (final o in options) {
      if (o.toLowerCase().contains(v.toLowerCase()) ||
          v.toLowerCase().contains(o.toLowerCase())) {
        return o;
      }
    }
    return null;
  }

  _ConfidenceBand get _band {
    if (_confidence >= 0.8) return _ConfidenceBand.high;
    if (_confidence >= 0.5) return _ConfidenceBand.medium;
    return _ConfidenceBand.low;
  }

  Future<void> _addToLibrary() async {
    final app = context.read<AppState>();
    if (!app.canAddBean()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bean limit reached. Upgrade to add more.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final name = _nameCtrl.text.trim();
    final roaster = _roasterCtrl.text.trim();
    if (name.isEmpty || roaster.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and roaster are required.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final region = _regionCtrl.text.trim();
    final varietal = _varietalCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final bean = Bean(
      name: name,
      roaster: roaster,
      origin: _origin,
      region: region.isEmpty ? null : region,
      varietal: varietal.isEmpty ? null : varietal,
      process: _process,
      roastLevel: _roastLevel,
      tastingNotes: _selectedNotes.toList(),
      description: description.isEmpty ? null : description,
      imageUrl: widget.imagePath.isEmpty ? null : widget.imagePath,
      elevation: (_raw?['elevation'] as num?)?.toDouble(),
      aiAnalysis: _raw,
    );
    await app.addBean(bean);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${bean.name}" to your library'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go('/library/${bean.id}');
  }

  Widget _buildImagePreview() {
    final path = widget.imagePath;
    Widget child;
    if (path.isEmpty) {
      child = Icon(Icons.image_not_supported_outlined,
          size: 56, color: BeanTheme.crema.withOpacity(0.5));
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      child = Image.network(path, fit: BoxFit.cover);
    } else if (!kIsWeb) {
      child = Image.file(File(path), fit: BoxFit.cover);
    } else {
      child = Center(
        child: Text(
          path,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: BeanTheme.crema.withOpacity(0.7)),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: BeanTheme.darkCard, child: child),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.black.withOpacity(0.45),
                child: Text(
                  path.isEmpty ? 'No image path' : path.split('/').last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: BeanTheme.crema, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceChip() {
    final b = _band;
    final color = switch (b) {
      _ConfidenceBand.high => BeanTheme.mint,
      _ConfidenceBand.medium => BeanTheme.honey,
      _ConfidenceBand.low => BeanTheme.cherry,
    };
    final label = switch (b) {
      _ConfidenceBand.high => 'High confidence',
      _ConfidenceBand.medium => 'Medium confidence',
      _ConfidenceBand.low => 'Low confidence',
    };
    return Row(
      children: [
        Icon(Icons.verified_outlined, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _confidence.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: BeanTheme.darkCard,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultChips() {
    if (_loading) return const SizedBox.shrink();
    final chips = <Widget>[
      _SummaryChip(
        label: _nameCtrl.text.isEmpty ? '—' : _nameCtrl.text,
        icon: Icons.label_outline,
      ),
      _SummaryChip(
        label: _roasterCtrl.text.isEmpty ? '—' : _roasterCtrl.text,
        icon: Icons.storefront_outlined,
      ),
      _SummaryChip(label: _origin, icon: Icons.public),
      _SummaryChip(label: _process, icon: Icons.water_drop_outlined),
      _SummaryChip(label: _roastLevel, icon: Icons.local_fire_department_outlined),
    ];
    for (final n in _selectedNotes.take(6)) {
      chips.add(_SummaryChip(label: n, icon: Icons.spa_outlined));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan result'),
        backgroundColor: BeanTheme.darkBg,
        foregroundColor: BeanTheme.crema,
      ),
      backgroundColor: BeanTheme.darkBg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _buildImagePreview(),
          const SizedBox(height: 16),
          if (_error != null)
            Material(
              color: BeanTheme.cherry.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(color: BeanTheme.cherry.withOpacity(0.95)),
                ),
              ),
            ),
          if (_loading) ...[
            const SizedBox(height: 12),
            Shimmer.fromColors(
              baseColor: BeanTheme.darkCard,
              highlightColor: BeanTheme.mediumRoast.withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 10),
                  Container(height: 18, width: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 10),
                  Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BeanTheme.caramel,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Analyzing…',
                  style: theme.textTheme.titleMedium?.copyWith(color: BeanTheme.crema),
                ),
              ],
            ),
          ] else ...[
            _buildConfidenceChip(),
            const SizedBox(height: 16),
            Text('AI summary', style: theme.textTheme.titleSmall?.copyWith(color: BeanTheme.caramel)),
            const SizedBox(height: 8),
            _buildResultChips(),
            const SizedBox(height: 24),
            Text('Edit details', style: theme.textTheme.titleMedium?.copyWith(color: BeanTheme.crema)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: BeanTheme.crema),
              decoration: const InputDecoration(labelText: 'Bean name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roasterCtrl,
              style: const TextStyle(color: BeanTheme.crema),
              decoration: const InputDecoration(labelText: 'Roaster'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _origin,
              decoration: const InputDecoration(labelText: 'Origin'),
              dropdownColor: BeanTheme.darkCard,
              style: const TextStyle(color: BeanTheme.crema),
              items: AppConstants.origins
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _origin = v ?? _origin),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _process,
              decoration: const InputDecoration(labelText: 'Process'),
              dropdownColor: BeanTheme.darkCard,
              style: const TextStyle(color: BeanTheme.crema),
              items: AppConstants.processes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _process = v ?? _process),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _roastLevel,
              decoration: const InputDecoration(labelText: 'Roast level'),
              dropdownColor: BeanTheme.darkCard,
              style: const TextStyle(color: BeanTheme.crema),
              items: AppConstants.roastLevels
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _roastLevel = v ?? _roastLevel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _regionCtrl,
              style: const TextStyle(color: BeanTheme.crema),
              decoration: const InputDecoration(labelText: 'Region (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _varietalCtrl,
              style: const TextStyle(color: BeanTheme.crema),
              decoration: const InputDecoration(labelText: 'Varietal (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionCtrl,
              style: const TextStyle(color: BeanTheme.crema),
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 20),
            Text('Tasting notes', style: theme.textTheme.titleSmall?.copyWith(color: BeanTheme.caramel)),
            const SizedBox(height: 8),
            Text(
              'Tap notes from the flavor wheel to add or remove.',
              style: theme.textTheme.bodySmall?.copyWith(color: BeanTheme.crema.withOpacity(0.65)),
            ),
            const SizedBox(height: 12),
            for (final category in AppConstants.flavorWheel.keys) ...[
              Text(
                category,
                style: theme.textTheme.labelLarge?.copyWith(color: BeanTheme.latte),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.flavorWheel[category]!.map((note) {
                  final selected = _selectedNotes.contains(note);
                  return FilterChip(
                    label: Text(note),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedNotes.add(note);
                        } else {
                          _selectedNotes.remove(note);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addToLibrary,
              icon: const Icon(Icons.library_add_check_rounded),
              label: const Text('Add to Library'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/scan'),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Scan Again'),
            ),
          ],
        ],
      ),
    );
  }
}

enum _ConfidenceBand { high, medium, low }

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BeanTheme.darkCard,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: BeanTheme.caramel),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: BeanTheme.crema, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
