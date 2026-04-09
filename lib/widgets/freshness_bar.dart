import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/bean.dart';

class FreshnessBar extends StatelessWidget {
  final FreshnessLevel level;
  final int daysFromRoast;
  final bool showLabels;

  const FreshnessBar({
    super.key,
    required this.level,
    required this.daysFromRoast,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: BeanTheme.latte,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stages = [
                _Stage('Resting', 0, 3, BeanTheme.blueberry),
                _Stage('Peak', 4, 14, BeanTheme.mint),
                _Stage('Fresh', 15, 21, BeanTheme.mint.withOpacity(0.6)),
                _Stage('Aging', 22, 30, BeanTheme.honey),
                _Stage('Stale', 31, 45, BeanTheme.cherry),
              ];

              final totalDays = 45.0;
              final currentPos = daysFromRoast.clamp(0, 45) / totalDays;

              return Stack(
                children: [
                  ...stages.map((stage) {
                    final start = stage.startDay / totalDays;
                    final end = stage.endDay / totalDays;
                    final isActive = daysFromRoast >= stage.startDay &&
                        daysFromRoast <= stage.endDay;

                    return Positioned(
                      left: constraints.maxWidth * start,
                      width: constraints.maxWidth * (end - start),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isActive
                              ? stage.color
                              : stage.color.withOpacity(0.2),
                          borderRadius: BorderRadius.horizontal(
                            left: stage.startDay == 0
                                ? const Radius.circular(3)
                                : Radius.zero,
                            right: stage.endDay == 45
                                ? const Radius.circular(3)
                                : Radius.zero,
                          ),
                        ),
                      ),
                    );
                  }),
                  if (daysFromRoast >= 0)
                    Positioned(
                      left: (constraints.maxWidth * currentPos) - 4,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _currentColor(),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _currentColor().withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resting',
                style: TextStyle(
                  fontSize: 9,
                  color: BeanTheme.lightRoast.withOpacity(0.6),
                ),
              ),
              Text(
                'Peak',
                style: TextStyle(
                  fontSize: 9,
                  color: BeanTheme.lightRoast.withOpacity(0.6),
                ),
              ),
              Text(
                'Fresh',
                style: TextStyle(
                  fontSize: 9,
                  color: BeanTheme.lightRoast.withOpacity(0.6),
                ),
              ),
              Text(
                'Aging',
                style: TextStyle(
                  fontSize: 9,
                  color: BeanTheme.lightRoast.withOpacity(0.6),
                ),
              ),
              Text(
                'Stale',
                style: TextStyle(
                  fontSize: 9,
                  color: BeanTheme.lightRoast.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _currentColor() {
    switch (level) {
      case FreshnessLevel.resting:
        return BeanTheme.blueberry;
      case FreshnessLevel.peak:
        return BeanTheme.mint;
      case FreshnessLevel.fresh:
        return BeanTheme.mint;
      case FreshnessLevel.aging:
        return BeanTheme.honey;
      case FreshnessLevel.stale:
        return BeanTheme.cherry;
      case FreshnessLevel.unknown:
        return BeanTheme.lightRoast;
    }
  }
}

class _Stage {
  final String label;
  final int startDay;
  final int endDay;
  final Color color;

  _Stage(this.label, this.startDay, this.endDay, this.color);
}
