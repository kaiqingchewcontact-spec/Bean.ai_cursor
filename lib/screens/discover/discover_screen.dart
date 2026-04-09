import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/bean.dart';
import '../../models/roaster.dart';
import '../../providers/app_state.dart';

enum _DiscoverCategoryKind { origin, process, roast }

/// Discovery hub: AI picks, categories, trending beans, subscriptions, partners.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  static String roasterRouteId(String roasterName) => Uri.encodeComponent(roasterName);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _roasterSearch = TextEditingController();
  _DiscoverCategoryKind? _activeKind;
  String? _activeValue;

  @override
  void dispose() {
    _roasterSearch.dispose();
    super.dispose();
  }

  static List<Roaster> _roastersFromBeans(List<Bean> beans) {
    final byName = <String, List<Bean>>{};
    for (final b in beans) {
      byName.putIfAbsent(b.roaster, () => []).add(b);
    }
    return byName.entries.map((e) {
      final list = e.value;
      final origins = list.map((b) => b.origin).toSet().length;
      return Roaster(
        id: DiscoverScreen.roasterRouteId(e.key),
        name: e.key,
        location: list.first.region ?? list.first.origin,
        rating: list.map((b) => b.rating).fold<double>(0, (a, b) => a + b) /
            (list.isEmpty ? 1 : list.length),
        beanCount: list.length,
        specialties: list
            .expand((b) => [b.process, b.roastLevel, b.origin])
            .toSet()
            .take(6)
            .toList(),
        isPartner: false,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<Roaster> _partnerSpotlight() => [
        Roaster(
          id: DiscoverScreen.roasterRouteId('Onyx Coffee Lab'),
          name: 'Onyx Coffee Lab',
          location: 'Rogers, AR',
          website: 'https://onyxcoffeelab.com',
          description:
              'Award-winning roaster known for transparent sourcing and vibrant profiles.',
          rating: 4.9,
          beanCount: 42,
          specialties: ['Light roast', 'Ethiopia', 'Experimental'],
          isPartner: true,
          promoCode: 'BEANAI15',
        ),
        Roaster(
          id: DiscoverScreen.roasterRouteId('Sey Coffee'),
          name: 'Sey Coffee',
          location: 'Brooklyn, NY',
          website: 'https://seycoffee.com',
          description: 'Minimal intervention roasting with a focus on clarity and terroir.',
          rating: 4.85,
          beanCount: 38,
          specialties: ['Floral', 'Gesha', 'Washed'],
          isPartner: true,
          promoCode: 'SEYBEAN10',
        ),
      ];

  List<String> _preferredFlavorsFromNotes(AppState app) {
    final cats = <String>{};
    for (final n in app.tastingNotes) {
      for (final d in n.descriptors) {
        for (final cat in AppConstants.flavorCategories) {
          final w = AppConstants.flavorWheel[cat];
          if (w != null && w.contains(d)) cats.add(cat);
        }
      }
    }
    if (cats.isEmpty) {
      return ['Fruity', 'Sweet', 'Chocolatey'];
    }
    return cats.take(8).toList();
  }

  List<Bean> _categoryResults(AppState app) {
    if (_activeKind == null || _activeValue == null) return [];
    Iterable<Bean> b = app.activeBeans;
    switch (_activeKind!) {
      case _DiscoverCategoryKind.origin:
        b = b.where((x) => x.origin == _activeValue);
        break;
      case _DiscoverCategoryKind.process:
        b = b.where((x) => x.process == _activeValue);
        break;
      case _DiscoverCategoryKind.roast:
        b = b.where((x) => x.roastLevel == _activeValue);
        break;
    }
    return b.toList();
  }

  List<Roaster> _filteredRoasters(List<Roaster> all) {
    final q = _roasterSearch.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            (r.location ?? '').toLowerCase().contains(q))
        .toList();
  }

  Future<void> _addSubscriptionPrompt(AppState app) async {
    final roasters = _roastersFromBeans(app.beans);
    if (roasters.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add beans to your library to track a roaster subscription.')),
      );
      return;
    }
    Roaster? picked = roasters.first;
    final planCtrl = TextEditingController(text: 'Classic');
    final priceCtrl = TextEditingController(text: '22');
    DateTime next = DateTime.now().add(const Duration(days: 14));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return AlertDialog(
              title: const Text('Add subscription'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Roaster>(
                      value: picked,
                      items: roasters
                          .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                          .toList(),
                      onChanged: (v) => setModal(() => picked = v),
                      decoration: const InputDecoration(labelText: 'Roaster'),
                    ),
                    TextField(
                      controller: planCtrl,
                      decoration: const InputDecoration(labelText: 'Plan name'),
                    ),
                    TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: 'Price / month'),
                      keyboardType: TextInputType.number,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Next delivery'),
                      subtitle: Text(DateFormat.yMMMd().format(next)),
                      trailing: const Icon(Icons.calendar_today_rounded),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: next,
                        );
                        if (d != null) setModal(() => next = d);
                      },
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
      },
    );

    if (ok == true && picked != null && mounted) {
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
      await app.addSubscription(
        Subscription(
          id: const Uuid().v4(),
          roasterId: DiscoverScreen.roasterRouteId(picked!.name),
          roasterName: picked!.name,
          planName: planCtrl.text.trim().isEmpty ? 'Plan' : planCtrl.text.trim(),
          pricePerMonth: price,
          nextDelivery: next,
          lastDelivery: DateTime.now().subtract(const Duration(days: 30)),
          isActive: true,
          valueRating: 4.2,
        ),
      );
    }

    planCtrl.dispose();
    priceCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtle = isDark ? BeanTheme.crema.withOpacity(0.55) : BeanTheme.lightRoast;

    final fromBeans = _roastersFromBeans(app.beans);
    final partners = _partnerSpotlight();
    final roasterIndex = <String, Roaster>{
      for (final r in [...fromBeans, ...partners]) r.name: r,
    };
    final roasterList = roasterIndex.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final filteredRoasters = _filteredRoasters(roasterList);

    final liked = app.beans.where((b) => b.rating >= 4 || b.isFavorite).toList();
    final beanOfWeek = app.beans.isEmpty
        ? null
        : (app.favoriteBeans.isNotEmpty ? app.favoriteBeans.first : app.activeBeans.first);

    final categoryResults = _categoryResults(app);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            title: const Text('Discover'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _roasterSearch,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search roasters',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _roasterSearch.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _roasterSearch.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: app.aiService.getRecommendations(
                  likedBeans: liked.isNotEmpty ? liked : app.activeBeans.take(5).toList(),
                  preferredFlavors: _preferredFlavorsFromNotes(app),
                ),
                builder: (context, snap) {
                  final recs = snap.data ?? [];
                  return _Section(
                    title: 'Curated for you',
                    subtitle: 'Based on your library & journal',
                    child: snap.connectionState == ConnectionState.waiting && recs.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Column(
                            children: recs.take(4).map((m) {
                              final name = '${m['name'] ?? 'Bean'}';
                              final roaster = '${m['roaster'] ?? ''}';
                              final score = (m['match_score'] as num?)?.toDouble() ?? 0;
                              final reason = '${m['reason'] ?? ''}';
                              return _RecommendationCard(
                                beanName: name,
                                roaster: roaster,
                                matchScore: score,
                                reason: reason,
                              );
                            }).toList(),
                          ),
                  );
                },
              ),
            ),
          ),
          if (beanOfWeek != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _Section(
                  title: 'Bean of the Week',
                  subtitle: app.isPremium ? 'Rotating staff pick' : 'Premium members see full details',
                  child: _FeaturedBeanCard(
                    bean: beanOfWeek,
                    showPremiumBadge: true,
                    isPremium: app.isPremium,
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Browse by category', style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 42,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(
                    label: 'Origins',
                    selected: _activeKind == _DiscoverCategoryKind.origin,
                    onTap: () async {
                      final v = await _pickOption(context, 'Origin', AppConstants.origins);
                      if (v != null) {
                        setState(() {
                          _activeKind = _DiscoverCategoryKind.origin;
                          _activeValue = v;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Process',
                    selected: _activeKind == _DiscoverCategoryKind.process,
                    onTap: () async {
                      final v = await _pickOption(context, 'Process', AppConstants.processes);
                      if (v != null) {
                        setState(() {
                          _activeKind = _DiscoverCategoryKind.process;
                          _activeValue = v;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Roast level',
                    selected: _activeKind == _DiscoverCategoryKind.roast,
                    onTap: () async {
                      final v = await _pickOption(context, 'Roast level', AppConstants.roastLevels);
                      if (v != null) {
                        setState(() {
                          _activeKind = _DiscoverCategoryKind.roast;
                          _activeValue = v;
                        });
                      }
                    },
                  ),
                  if (_activeKind != null) ...[
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('Clear'),
                      onPressed: () => setState(() {
                        _activeKind = null;
                        _activeValue = null;
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_activeKind != null && _activeValue != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${_activeKind == _DiscoverCategoryKind.origin ? 'Origin' : _activeKind == _DiscoverCategoryKind.process ? 'Process' : 'Roast'}: $_activeValue · ${categoryResults.length} in library',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtle),
                ),
              ),
            ),
          if (categoryResults.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: categoryResults.length.clamp(0, 12),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final b = categoryResults[i];
                  return _BeanRow(bean: b);
                },
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: _Section(
                title: 'Trending in the community',
                subtitle: 'Beans your fellow brewers are reaching for often',
                child: Column(
                  children: () {
                    final t = List<Bean>.from(app.activeBeans)
                      ..sort((a, b) => b.brewCount.compareTo(a.brewCount));
                    final top = t.take(5).toList();
                    if (top.isEmpty) {
                      return [const Text('Add beans and log brews to see momentum here.')];
                    }
                    return top
                        .map(
                          (b) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: BeanTheme.caramel.withOpacity(0.25),
                              child: Text(
                                b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: BeanTheme.espresso),
                              ),
                            ),
                            title: Text(b.name),
                            subtitle: Text('${b.brewCount} brews logged · ${b.origin}'),
                            trailing: const Icon(Icons.trending_up_rounded, color: BeanTheme.mint),
                          ),
                        )
                        .toList();
                  }(),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your subscriptions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _addSubscriptionPrompt(app),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
          if (app.subscriptions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'No active subscriptions yet. Track deliveries and value in one place.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: subtle),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: app.subscriptions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final s = app.subscriptions[i];
                  return _SubscriptionCard(sub: s);
                },
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: _Section(
                title: 'Partner roaster spotlight',
                subtitle: 'Exclusive perks for Bean.ai members',
                child: Column(
                  children: partners.map((r) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => context.push('/discover/roaster/${r.id}'),
                        leading: CircleAvatar(
                          backgroundColor: BeanTheme.cherry.withOpacity(0.15),
                          child: const Icon(Icons.local_cafe_rounded, color: BeanTheme.cherry),
                        ),
                        title: Text(r.name),
                        subtitle: Text(r.location ?? ''),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: _Section(
                title: 'Roasters',
                subtitle: 'From your library & featured partners',
                child: Column(
                  children: filteredRoasters.isEmpty
                      ? [Text('No roasters match “${_roasterSearch.text}”.', style: TextStyle(color: subtle))]
                      : filteredRoasters.take(20).map((r) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () => context.push('/discover/roaster/${r.id}'),
                            leading: CircleAvatar(
                              backgroundColor: BeanTheme.blueberry.withOpacity(0.2),
                              child: Text(
                                r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: BeanTheme.blueberry,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(r.name),
                            subtitle: Text(
                              '${r.beanCount} beans in app · ★ ${r.rating.toStringAsFixed(1)}',
                            ),
                            trailing: r.isPartner
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: BeanTheme.honey.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Partner',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: BeanTheme.espresso,
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        }).toList(),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Future<String?> _pickOption(BuildContext context, String title, List<String> options) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.9,
          minChildSize: 0.35,
          builder: (context, scroll) {
            return ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              itemCount: options.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
                  );
                }
                final o = options[i - 1];
                return ListTile(
                  title: Text(o),
                  onTap: () => Navigator.pop(ctx, o),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? BeanTheme.crema.withOpacity(0.55) : BeanTheme.lightRoast,
              ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.beanName,
    required this.roaster,
    required this.matchScore,
    required this.reason,
  });

  final String beanName;
  final String roaster;
  final double matchScore;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? BeanTheme.darkCard : Colors.white,
        border: Border.all(
          color: isDark ? BeanTheme.mediumRoast.withOpacity(0.35) : BeanTheme.latte,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(beanName, style: Theme.of(context).textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BeanTheme.mint.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(matchScore * 100).round()}% match',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: BeanTheme.mint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            roaster,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? BeanTheme.crema.withOpacity(0.55) : BeanTheme.lightRoast,
                ),
          ),
          const SizedBox(height: 10),
          Text(reason, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _FeaturedBeanCard extends StatelessWidget {
  const _FeaturedBeanCard({
    required this.bean,
    required this.showPremiumBadge,
    required this.isPremium,
  });

  final Bean bean;
  final bool showPremiumBadge;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            BeanTheme.cherry.withOpacity(0.85),
            BeanTheme.honey.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: BeanTheme.cherry.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showPremiumBadge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPremium ? Icons.verified_rounded : Icons.lock_outline_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPremium ? 'Premium' : 'Premium highlight',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bean.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            '${bean.roaster} · ${bean.origin}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            isPremium
                ? '${bean.process} · ${bean.roastLevel}. ${bean.description ?? 'Dial in with your usual recipe—this lot loves clarity and gentle heat.'}'
                : 'Upgrade to read tasting notes, ideal brew methods, and rotating featured lots.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.92),
                ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: selected ? BeanTheme.caramel.withOpacity(0.35) : null,
    );
  }
}

class _BeanRow extends StatelessWidget {
  const _BeanRow({required this.bean});

  final Bean bean;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? BeanTheme.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        onTap: () => context.push('/library/${bean.id}'),
        title: Text(bean.name),
        subtitle: Text('${bean.roaster} · ${bean.process} · ${bean.roastLevel}'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.sub});

  final Subscription sub;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = sub.daysUntilNext;
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Expanded(
                child: Text(sub.roasterName, style: Theme.of(context).textTheme.titleMedium),
              ),
              if (sub.valueRating != null)
                Row(
                  children: [
                    const Icon(Icons.savings_outlined, size: 18, color: BeanTheme.honey),
                    const SizedBox(width: 4),
                    Text(
                      'Value ${sub.valueRating!.toStringAsFixed(1)}/5',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${sub.planName} · \$${sub.pricePerMonth.toStringAsFixed(2)}/mo',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.local_shipping_rounded, size: 18, color: BeanTheme.mint),
              const SizedBox(width: 6),
              Text(
                'Next: ${DateFormat.yMMMd().format(sub.nextDelivery)} ($days days)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
