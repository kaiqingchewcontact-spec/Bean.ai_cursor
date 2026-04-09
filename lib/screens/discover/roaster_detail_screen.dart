import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../models/bean.dart';
import '../../models/roaster.dart';
import '../../providers/app_state.dart';

/// Roaster profile synthesized from library beans plus partner metadata.
class RoasterDetailScreen extends StatefulWidget {
  const RoasterDetailScreen({super.key, required this.roasterId});

  final String roasterId;

  @override
  State<RoasterDetailScreen> createState() => _RoasterDetailScreenState();
}

class _RoasterDetailScreenState extends State<RoasterDetailScreen> {
  static List<Roaster> _knownPartners() => [
        Roaster(
          id: Uri.encodeComponent('Onyx Coffee Lab'),
          name: 'Onyx Coffee Lab',
          location: 'Rogers, AR',
          website: 'https://onyxcoffeelab.com',
          description:
              'Award-winning roaster known for transparent sourcing and vibrant profiles.',
          imageUrl: null,
          rating: 4.9,
          beanCount: 42,
          specialties: ['Light roast', 'Ethiopia', 'Experimental'],
          isPartner: true,
          promoCode: 'BEANAI15',
        ),
        Roaster(
          id: Uri.encodeComponent('Sey Coffee'),
          name: 'Sey Coffee',
          location: 'Brooklyn, NY',
          website: 'https://seycoffee.com',
          description: 'Minimal intervention roasting with a focus on clarity and terroir.',
          imageUrl: null,
          rating: 4.85,
          beanCount: 38,
          specialties: ['Floral', 'Gesha', 'Washed'],
          isPartner: true,
          promoCode: 'SEYBEAN10',
        ),
      ];

  Roaster? _roasterFromBeans(String name, List<Bean> beans) {
    final mine = beans.where((b) => b.roaster == name).toList();
    if (mine.isEmpty) return null;
    return Roaster(
      id: widget.roasterId,
      name: name,
      location: mine.first.region ?? mine.first.origin,
      rating: mine.map((b) => b.rating).fold<double>(0, (a, b) => a + b) / mine.length,
      beanCount: mine.length,
      specialties: mine
          .expand((b) => [b.process, b.roastLevel])
          .toSet()
          .take(8)
          .toList(),
      isPartner: false,
    );
  }

  Roaster _resolveRoaster(AppState app) {
    final decoded = Uri.decodeComponent(widget.roasterId);
    for (final p in _knownPartners()) {
      if (p.id == widget.roasterId || p.name == decoded) return p;
    }
    final fromBeans = _roasterFromBeans(decoded, app.beans);
    if (fromBeans != null) return fromBeans;
    return Roaster(
      id: widget.roasterId,
      name: decoded.isNotEmpty ? decoded : 'Roaster',
      location: null,
      description: 'Add beans from this roaster to your library to enrich this profile.',
      rating: 0,
      beanCount: 0,
    );
  }

  List<Bean> _theirBeans(AppState app, String roasterName) {
    return app.beans.where((b) => b.roaster == roasterName).toList();
  }

  Subscription? _subscription(AppState app, Roaster r) {
    try {
      return app.subscriptions.firstWhere(
        (s) =>
            s.roasterId == widget.roasterId ||
            s.roasterId == r.id ||
            s.roasterName == r.name,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _openSite(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final r = _resolveRoaster(app);
    final beans = _theirBeans(app, r.name);
    final sub = _subscription(app, r);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                r.name,
                style: const TextStyle(
                  shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          BeanTheme.espresso,
                          BeanTheme.cherry.withOpacity(0.85),
                          BeanTheme.caramel.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  if (r.logoUrl != null)
                    Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: NetworkImage(r.logoUrl!),
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (r.location != null)
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 20, color: BeanTheme.mint),
                        const SizedBox(width: 6),
                        Text(r.location!, style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                  if (r.website != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _openSite(r.website),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded, size: 20, color: BeanTheme.blueberry),
                          const SizedBox(width: 6),
                          Text(
                            r.website!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: BeanTheme.blueberry,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: BeanTheme.honey, size: 28),
                      const SizedBox(width: 6),
                      Text(
                        r.rating > 0 ? r.rating.toStringAsFixed(2) : '—',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${r.beanCount} beans)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? BeanTheme.crema.withOpacity(0.55) : BeanTheme.lightRoast,
                            ),
                      ),
                    ],
                  ),
                  if (r.isPartner) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: BeanTheme.honey.withOpacity(0.2),
                        border: Border.all(color: BeanTheme.honey.withOpacity(0.45)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded, color: BeanTheme.espresso),
                              const SizedBox(width: 8),
                              Text(
                                'Partner roaster',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                          if (r.promoCode != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Promo: ${r.promoCode}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            FilledButton.tonal(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: r.promoCode!));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Promo code copied')),
                                  );
                                }
                              },
                              child: const Text('Copy code'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (r.description != null) ...[
                    const SizedBox(height: 20),
                    Text('About', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(r.description!, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                  if (r.specialties.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Specialties', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: r.specialties
                          .map(
                            (s) => Chip(
                              label: Text(s),
                              backgroundColor: isDark ? BeanTheme.darkCard : BeanTheme.latte,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (sub != null) ...[
                    const SizedBox(height: 20),
                    Text('Your subscription', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.local_shipping_rounded, color: BeanTheme.mint),
                      title: Text(sub.planName),
                      subtitle: Text(
                        'Next delivery ${DateFormat.yMMMd().format(sub.nextDelivery)} · '
                        '${sub.daysUntilNext} days',
                      ),
                      trailing: sub.valueRating != null
                          ? Text('★ ${sub.valueRating!.toStringAsFixed(1)}')
                          : null,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('In your library', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (beans.isEmpty)
                    Text(
                      'No beans from ${r.name} yet. Scan a bag or add manually from the library.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? BeanTheme.crema.withOpacity(0.6) : BeanTheme.mediumRoast,
                          ),
                    )
                  else
                    ...beans.map(
                      (b) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => context.push('/library/${b.id}'),
                          title: Text(b.name),
                          subtitle: Text('${b.origin} · ${b.process}'),
                          trailing: Text(
                            b.rating > 0 ? b.rating.toStringAsFixed(1) : '—',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (r.website != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openSite(r.website),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Visit website'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
