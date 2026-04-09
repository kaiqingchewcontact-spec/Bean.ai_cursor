import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/brew.dart';

class BrewCard extends StatelessWidget {
  final Brew brew;
  final String? beanName;
  final VoidCallback? onTap;

  const BrewCard({
    super.key,
    required this.brew,
    this.beanName,
    this.onTap,
  });

  IconData _methodIcon() {
    final method = brew.method.toLowerCase();
    if (method.contains('espresso')) return Icons.coffee_rounded;
    if (method.contains('pour') || method.contains('v60')) return Icons.water_drop_rounded;
    if (method.contains('french') || method.contains('press')) return Icons.compress_rounded;
    if (method.contains('aero')) return Icons.air_rounded;
    if (method.contains('cold')) return Icons.ac_unit_rounded;
    if (method.contains('chemex')) return Icons.science_rounded;
    if (method.contains('moka')) return Icons.local_fire_department_rounded;
    if (method.contains('drip') || method.contains('filter')) return Icons.filter_alt_rounded;
    return Icons.coffee_maker_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: BeanTheme.caramel.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _methodIcon(),
                color: BeanTheme.caramel,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brew.method,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    beanName ?? 'Unknown Bean',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BeanTheme.lightRoast,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      brew.ratioLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: BeanTheme.mediumRoast,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      brew.brewTimeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: BeanTheme.lightRoast,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (brew.rating > 0) ...[
                      ...List.generate(5, (i) {
                        return Icon(
                          i < brew.rating.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 14,
                          color: i < brew.rating.round()
                              ? BeanTheme.honey
                              : BeanTheme.lightRoast.withOpacity(0.3),
                        );
                      }),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      DateFormat('MMM d').format(brew.brewDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: BeanTheme.lightRoast.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
