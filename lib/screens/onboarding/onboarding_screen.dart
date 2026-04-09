import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';

/// Bean.ai onboarding — three animated pages with coffee-themed gradients.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Smart Bean Scanner',
      description:
          'Scan any coffee bag with AI vision to build your digital stash.',
      icon: Icons.local_cafe_rounded,
      gradient: [
        BeanTheme.espresso,
        BeanTheme.darkRoast,
        BeanTheme.mediumRoast,
      ],
      accent: BeanTheme.caramel,
    ),
    _OnboardingPageData(
      title: 'AI Brew Optimizer',
      description:
          'Get personalized recipes and real-time coaching for the perfect cup.',
      icon: Icons.science_rounded,
      gradient: [
        BeanTheme.darkRoast,
        BeanTheme.mediumRoast,
        BeanTheme.lightRoast,
      ],
      accent: BeanTheme.honey,
    ),
    _OnboardingPageData(
      title: 'Your Flavor Journey',
      description:
          'Track your palate, discover patterns, and unlock new favorites.',
      icon: Icons.auto_graph_rounded,
      gradient: [
        BeanTheme.mediumRoast,
        BeanTheme.cherry,
        BeanTheme.espresso,
      ],
      accent: BeanTheme.mint,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goHome() {
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            itemBuilder: (context, index) {
              final data = _pages[index];
              return _OnboardingPageContent(data: data, pageIndex: index);
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: TextButton(
                  onPressed: _goHome,
                  style: TextButton.styleFrom(
                    foregroundColor: BeanTheme.crema.withOpacity(0.95),
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _pageIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: active ? 28 : 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: active
                                ? BeanTheme.caramel
                                : BeanTheme.crema.withOpacity(0.35),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: BeanTheme.caramel
                                          .withOpacity(0.45),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),
                    if (_pageIndex < _pages.length - 1)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
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
                          child: const Text('Next'),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _goHome,
                          style: FilledButton.styleFrom(
                            backgroundColor: BeanTheme.honey,
                            foregroundColor: BeanTheme.espresso,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Get Started'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.accent,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final Color accent;
}

class _OnboardingPageContent extends StatelessWidget {
  const _OnboardingPageContent({
    required this.data,
    required this.pageIndex,
  });

  final _OnboardingPageData data;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.gradient,
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.accent.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BeanTheme.milk.withOpacity(0.06),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 72, 28, 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Bean.ai',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: BeanTheme.crema.withOpacity(0.85),
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                  )
                      .animate(key: ValueKey('brand_$pageIndex'))
                      .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                      .slideY(
                        begin: -0.15,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 8),
                  Text(
                    'Your AI Coffee Companion',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: BeanTheme.latte.withOpacity(0.9),
                        ),
                  )
                      .animate(key: ValueKey('tag_$pageIndex'))
                      .fadeIn(delay: 80.ms, duration: 500.ms)
                      .slideY(
                        begin: -0.1,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BeanTheme.milk.withOpacity(0.14),
                      border: Border.all(
                        color: BeanTheme.crema.withOpacity(0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.22),
                          blurRadius: 32,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Icon(
                      data.icon,
                      size: 88,
                      color: BeanTheme.crema,
                    ),
                  )
                      .animate(key: ValueKey('icon_$pageIndex'))
                      .fadeIn(duration: 550.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.88, 0.88),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: 40),
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: BeanTheme.milk,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                  )
                      .animate(key: ValueKey('title_$pageIndex'))
                      .fadeIn(delay: 100.ms, duration: 550.ms)
                      .slideY(
                        begin: 0.12,
                        end: 0,
                        duration: 550.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 16),
                  Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: BeanTheme.crema.withOpacity(0.92),
                          height: 1.45,
                        ),
                  )
                      .animate(key: ValueKey('desc_$pageIndex'))
                      .fadeIn(delay: 180.ms, duration: 600.ms)
                      .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
