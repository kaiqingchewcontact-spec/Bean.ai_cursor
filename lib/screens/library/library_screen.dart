import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/bean.dart';
import '../../providers/app_state.dart';

enum _LibraryFilter { all, fresh, aging, favorites }

enum _LibrarySort { recent, roastDate, rating, origin }

/// Pantry / library of beans with search, filters, and sort.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _search = TextEditingController();
  _LibraryFilter _filter = _LibraryFilter.all;
  _LibrarySort _sort = _LibrarySort.recent;
  bool _gridView = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String _originEmoji(String origin) {
    const map = {
      'Ethiopia': '🇪🇹',
      'Colombia': '🇨🇴',
      'Brazil': '🇧🇷',
      'Kenya': '🇰🇪',
      'Guatemala': '🇬🇹',
      'Costa Rica': '🇨🇷',
      'Peru': '🇵🇪',
      'Indonesia': '🇮🇩',
      'Honduras': '🇭🇳',
      'Rwanda': '🇷🇼',
      'Panama': '🇵🇦',
      'Yemen': '🇾🇪',
      'Mexico': '🇲🇽',
      'India': '🇮🇳',
      'Burundi': '🇧🇮',
      'El Salvador': '🇸🇻',
      'Nicaragua': '🇳🇮',
      'Tanzania': '🇹🇿',
      'Uganda': '🇺🇬',
      'Blend': '🌍',
    };
    return map[origin] ?? '📍';
  }

  List<Bean> _filteredAndSorted(AppState app) {
    Iterable<Bean> beans = app.activeBeans;
    switch (_filter) {
      case _LibraryFilter.all:
        break;
      case _LibraryFilter.fresh:
        beans = app.freshBeans;
        break;
      case _LibraryFilter.aging:
        beans = app.agingBeans;
        break;
      case _LibraryFilter.favorites:
        beans = beans.where((b) => b.isFavorite);
        break;
    }
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      beans = beans.where((b) {
        return b.name.toLowerCase().contains(q) ||
            b.roaster.toLowerCase().contains(q) ||
            b.origin.toLowerCase().contains(q) ||
            b.process.toLowerCase().contains(q);
      });
    }
    final list = beans.toList();
    switch (_sort) {
      case _LibrarySort.recent:
        list.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
      case _LibrarySort.roastDate:
        list.sort((a, b) {
          final ad = a.roastDate;
          final bd = b.roastDate;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad);
        });
        break;
      case _LibrarySort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _LibrarySort.origin:
        list.sort((a, b) => a.origin.compareTo(b.origin));
        break;
    }
    return list;
  }

  Future<void> _onRefresh() async {
    await context.read<AppState>().loadData();
    if (mounted) setState(() {});
  }

  Future<void> _showAddBeanDialog() async {
    final nameCtrl = TextEditingController();
    final roasterCtrl = TextEditingController();
    String origin = AppConstants.origins.first;
    String process = AppConstants.processes.first;
    String roast = AppConstants.roastLevels[2];
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add bean manually'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: roasterCtrl,
                      decoration: const InputDecoration(labelText: 'Roaster'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: origin,
                      decoration: const InputDecoration(labelText: 'Origin'),
                      items: AppConstants.origins
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => origin = v ?? origin),
                    ),
                    DropdownButtonFormField<String>(
                      value: process,
                      decoration: const InputDecoration(labelText: 'Process'),
                      items: AppConstants.processes
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => process = v ?? process),
                    ),
                    DropdownButtonFormField<String>(
                      value: roast,
                      decoration: const InputDecoration(labelText: 'Roast level'),
                      items: AppConstants.roastLevels
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => roast = v ?? roast),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
              ],
            );
          },
        );
      },
    );
    if (ok != true || !mounted) return;
    final app = context.read<AppState>();
    if (!app.canAddBean()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bean limit reached. Upgrade to add more.')),
      );
      return;
    }
    final name = nameCtrl.text.trim();
    final roaster = roasterCtrl.text.trim();
    if (name.isEmpty || roaster.isEmpty) return;
    final bean = Bean(
      name: name,
      roaster: roaster,
      origin: origin,
      process: process,
      roastLevel: roast,
    );
    await app.addBean(bean);
    nameCtrl.dispose();
    roasterCtrl.dispose();
    if (mounted) context.push('/library/${bean.id}');
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text('Sort by', style: Theme.of(ctx).textTheme.titleMedium),
              ),
              for (final s in _LibrarySort.values)
                RadioListTile<_LibrarySort>(
                  value: s,
                  groupValue: _sort,
                  title: Text(_sortLabel(s)),
                  onChanged: (v) {
                    setState(() => _sort = v ?? _sort);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  static String _sortLabel(_LibrarySort s) => switch (s) {
        _LibrarySort.recent => 'Recently added',
        _LibrarySort.roastDate => 'Roast date',
        _LibrarySort.rating => 'Rating',
        _LibrarySort.origin => 'Origin',
      };

  Color _freshnessColor(FreshnessLevel level) => switch (level) {
        FreshnessLevel.resting => BeanTheme.blueberry,
        FreshnessLevel.peak => BeanTheme.mint,
        FreshnessLevel.fresh => BeanTheme.honey,
        FreshnessLevel.aging => BeanTheme.caramel,
        FreshnessLevel.stale => BeanTheme.cherry,
        FreshnessLevel.unknown => BeanTheme.lightRoast,
      };

  Widget _freshnessBar(FreshnessLevel level) {
    const order = [
      FreshnessLevel.resting,
      FreshnessLevel.peak,
      FreshnessLevel.fresh,
      FreshnessLevel.aging,
      FreshnessLevel.stale,
    ];
    final idx = order.indexOf(level);
    return Row(
      children: List.generate(order.length, (i) {
        final active = idx >= 0 && i <= idx;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < order.length - 1 ? 3 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: active
                  ? _freshnessColor(level)
                  : BeanTheme.latte.withOpacity(0.25),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBeanCard(Bean bean) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? BeanTheme.darkCard : Colors.white;
    final onCard = isDark ? BeanTheme.crema : BeanTheme.espresso;
    final days = bean.daysFromRoast;
    final daysLabel = days < 0 ? 'Roast date unknown' : '$days d from roast';

    return Hero(
      tag: 'bean-hero-${bean.id}',
      child: Material(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/library/${bean.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _gridView
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_originEmoji(bean.origin), style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bean.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: onCard,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          if (bean.isFavorite)
                            Icon(Icons.favorite_rounded, size: 18, color: BeanTheme.cherry),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bean.roaster,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: onCard.withOpacity(0.65),
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(bean.roastLevel, style: const TextStyle(fontSize: 11)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(bean.origin, style: const TextStyle(fontSize: 11)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _freshnessBar(bean.freshnessLevel),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _freshnessColor(bean.freshnessLevel),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              bean.freshnessLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: onCard.withOpacity(0.75),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(daysLabel, style: TextStyle(fontSize: 11, color: onCard.withOpacity(0.55))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 18, color: BeanTheme.honey),
                          Text(
                            bean.rating > 0 ? bean.rating.toStringAsFixed(1) : '—',
                            style: TextStyle(fontSize: 13, color: onCard.withOpacity(0.85)),
                          ),
                          const Spacer(),
                          Icon(Icons.coffee_rounded, size: 16, color: onCard.withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Text(
                            '${bean.brewCount}',
                            style: TextStyle(fontSize: 13, color: onCard.withOpacity(0.85)),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(_originEmoji(bean.origin), style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bean.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: onCard,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              '${bean.roaster} · ${bean.origin}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: onCard.withOpacity(0.6),
                                  ),
                            ),
                            const SizedBox(height: 6),
                            _freshnessBar(bean.freshnessLevel),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Chip(
                            label: Text(bean.roastLevel, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.star_rounded, size: 16, color: BeanTheme.honey),
                              Text(bean.rating > 0 ? bean.rating.toStringAsFixed(1) : '—'),
                            ],
                          ),
                          Text(daysLabel, style: TextStyle(fontSize: 11, color: onCard.withOpacity(0.5))),
                          Text('${bean.brewCount} brews', style: TextStyle(fontSize: 11, color: onCard.withOpacity(0.5))),
                          if (bean.isFavorite) Icon(Icons.favorite_rounded, size: 16, color: BeanTheme.cherry),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final beans = _filteredAndSorted(app);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: 'Sort',
            onPressed: _showSortSheet,
            icon: const Icon(Icons.sort_rounded),
          ),
          IconButton(
            tooltip: _gridView ? 'List view' : 'Grid view',
            onPressed: () => setState(() => _gridView = !_gridView),
            icon: Icon(_gridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt_rounded),
                    title: const Text('Scan a bag'),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/scan');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_note_rounded),
                    title: const Text('Add manually'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddBeanDialog();
                    },
                  ),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search beans…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final f in _LibraryFilter.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(_filterLabel(f)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: BeanTheme.caramel,
              child: beans.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: isDark ? BeanTheme.crema.withOpacity(0.35) : BeanTheme.lightRoast.withOpacity(0.45),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your pantry is empty',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan your first bean to build your library.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: FilledButton.icon(
                            onPressed: () => context.push('/scan'),
                            icon: const Icon(Icons.document_scanner_outlined),
                            label: const Text('Open scanner'),
                          ),
                        ),
                      ],
                    )
                  : _gridView
                      ? GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: beans.length,
                          itemBuilder: (context, i) => _buildBeanCard(beans[i]),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: beans.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _buildBeanCard(beans[i]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  static String _filterLabel(_LibraryFilter f) => switch (f) {
        _LibraryFilter.all => 'All',
        _LibraryFilter.fresh => 'Fresh',
        _LibraryFilter.aging => 'Aging',
        _LibraryFilter.favorites => 'Favorites',
      };
}
