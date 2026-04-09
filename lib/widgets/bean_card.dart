import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/bean.dart';

class BeanCard extends StatelessWidget {
  final Bean bean;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool compact;

  const BeanCard({
    super.key,
    required this.bean,
    this.onTap,
    this.onFavoriteToggle,
    this.compact = false,
  });

  Color _freshnessColor() {
    switch (bean.freshnessLevel) {
      case FreshnessLevel.resting:
        return BeanTheme.blueberry;
      case FreshnessLevel.peak:
        return BeanTheme.mint;
      case FreshnessLevel.fresh:
        return BeanTheme.mint.withOpacity(0.7);
      case FreshnessLevel.aging:
        return BeanTheme.honey;
      case FreshnessLevel.stale:
        return BeanTheme.cherry;
      case FreshnessLevel.unknown:
        return BeanTheme.lightRoast;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _freshnessColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    bean.freshnessLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _freshnessColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bean.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              bean.roaster,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BeanTheme.lightRoast,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (bean.daysFromRoast >= 0)
              Text(
                '${bean.daysFromRoast}d from roast',
                style: TextStyle(
                  fontSize: 11,
                  color: BeanTheme.lightRoast.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: BeanTheme.latte,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.coffee_rounded,
                color: BeanTheme.mediumRoast,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bean.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onFavoriteToggle != null)
                        GestureDetector(
                          onTap: onFavoriteToggle,
                          child: Icon(
                            bean.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: bean.isFavorite
                                ? BeanTheme.cherry
                                : BeanTheme.lightRoast,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bean.roaster} · ${bean.origin}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BeanTheme.lightRoast,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildBadge(bean.roastLevel, BeanTheme.latte),
                      const SizedBox(width: 6),
                      _buildFreshnessBadge(),
                      const Spacer(),
                      if (bean.rating > 0) ...[
                        Icon(Icons.star_rounded, size: 14, color: BeanTheme.honey),
                        const SizedBox(width: 2),
                        Text(
                          bean.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (bean.brewCount > 0) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.coffee_rounded, size: 14, color: BeanTheme.lightRoast),
                        const SizedBox(width: 2),
                        Text(
                          '${bean.brewCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: BeanTheme.lightRoast,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFreshnessBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _freshnessColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _freshnessColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            bean.freshnessLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _freshnessColor(),
            ),
          ),
        ],
      ),
    );
  }
}
