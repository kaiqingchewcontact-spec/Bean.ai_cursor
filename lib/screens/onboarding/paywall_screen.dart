import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';

enum _PlanKind { monthly, yearly, lifetime }

/// Premium subscription paywall for Bean.ai.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  _PlanKind _selected = _PlanKind.yearly;

  static const double _monthlyPrice = 4.99;
  static const double _yearlyPrice = 49;
  static const double _lifetimePrice = 99;

  String get _yearlySavingsLabel {
    final fullYearMonthly = _monthlyPrice * 12;
    final saved = fullYearMonthly - _yearlyPrice;
    final pct = ((saved / fullYearMonthly) * 100).round();
    return 'Save ~\$${saved.toStringAsFixed(2)}/yr ($pct% off monthly)';
  }

  String get _ctaLabel {
    switch (_selected) {
      case _PlanKind.monthly:
      case _PlanKind.yearly:
        return 'Start Free Trial';
      case _PlanKind.lifetime:
        return 'Subscribe Now';
    }
  }

  void _onRestore() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Restore purchases will connect to your store account.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: BeanTheme.darkRoast,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: BeanTheme.darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroHeader(theme: theme),
                    const SizedBox(height: 28),
                    Text(
                      'Everything you need to brew smarter',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: BeanTheme.crema.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _FeatureRow(
                      icon: Icons.document_scanner_outlined,
                      title: 'Unlimited scans',
                      subtitle: 'Digitize every bag in seconds',
                    ),
                    const _FeatureRow(
                      icon: Icons.psychology_outlined,
                      title: 'AI Brew Coach',
                      subtitle: 'Step-by-step guidance tuned to you',
                    ),
                    const _FeatureRow(
                      icon: Icons.insights_outlined,
                      title: 'Advanced insights',
                      subtitle: 'See patterns in your taste profile',
                    ),
                    const _FeatureRow(
                      icon: Icons.local_cafe_outlined,
                      title: 'Bean of the Week',
                      subtitle: 'Curated picks to expand your palate',
                    ),
                    const _FeatureRow(
                      icon: Icons.ios_share_outlined,
                      title: 'Export & widgets',
                      subtitle: 'Take your stash and stats anywhere',
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Choose your plan',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: BeanTheme.milk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _PricingCard(
                      title: 'Monthly',
                      priceLine: '\$${_monthlyPrice.toStringAsFixed(2)}/mo',
                      subline: 'Flexible — cancel anytime',
                      selected: _selected == _PlanKind.monthly,
                      onTap: () => setState(() => _selected = _PlanKind.monthly),
                    ),
                    const SizedBox(height: 12),
                    _PricingCard(
                      title: 'Yearly',
                      priceLine: '\$${_yearlyPrice.toStringAsFixed(0)}/yr',
                      subline: _yearlySavingsLabel,
                      badge: 'Best Value',
                      selected: _selected == _PlanKind.yearly,
                      onTap: () => setState(() => _selected = _PlanKind.yearly),
                    ),
                    const SizedBox(height: 12),
                    _PricingCard(
                      title: 'Lifetime',
                      priceLine: '\$${_lifetimePrice.toStringAsFixed(0)}',
                      subline: 'One-time — yours forever',
                      selected: _selected == _PlanKind.lifetime,
                      onTap: () =>
                          setState(() => _selected = _PlanKind.lifetime),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$_ctaLabel — store integration pending'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: BeanTheme.espresso,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: BeanTheme.caramel,
                      foregroundColor: BeanTheme.espresso,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _ctaLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _onRestore,
                    child: Text(
                      'Restore Purchases',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: BeanTheme.crema.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/'),
                      child: Text(
                        'Continue with Free',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: BeanTheme.mint,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor:
                              BeanTheme.mint.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BeanTheme.darkRoast,
            BeanTheme.espresso,
            BeanTheme.mediumRoast.withOpacity(0.95),
          ],
        ),
        border: Border.all(
          color: BeanTheme.caramel.withOpacity(0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BeanTheme.milk.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: BeanTheme.crema.withOpacity(0.2),
              ),
            ),
            child: Icon(
              Icons.coffee_maker_outlined,
              size: 44,
              color: BeanTheme.caramel,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bean.ai',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: BeanTheme.milk,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your AI Coffee Companion',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: BeanTheme.crema.withOpacity(0.88),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Unlock the Full Bean.ai Experience',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: BeanTheme.milk,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: BeanTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BeanTheme.caramel.withOpacity(0.22),
              ),
            ),
            child: Icon(icon, color: BeanTheme.honey, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: BeanTheme.milk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: BeanTheme.crema.withOpacity(0.75),
                    height: 1.35,
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

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.title,
    required this.priceLine,
    required this.subline,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String priceLine;
  final String subline;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BeanTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? BeanTheme.caramel
                  : BeanTheme.mediumRoast.withOpacity(0.35),
              width: selected ? 2.2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: BeanTheme.caramel.withOpacity(0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: BeanTheme.milk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: BeanTheme.honey.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: BeanTheme.honey.withOpacity(0.45),
                              ),
                            ),
                            child: Text(
                              badge!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: BeanTheme.honey,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      priceLine,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: BeanTheme.caramel,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subline,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: BeanTheme.crema.withOpacity(0.72),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? BeanTheme.caramel : BeanTheme.lightRoast,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
