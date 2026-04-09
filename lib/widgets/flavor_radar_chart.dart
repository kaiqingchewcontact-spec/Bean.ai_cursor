import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';

class FlavorRadarChart extends StatelessWidget {
  final Map<String, double> scores;
  final double maxValue;
  final double size;

  const FlavorRadarChart({
    super.key,
    required this.scores,
    this.maxValue = 10,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return SizedBox(
        height: size,
        child: Center(
          child: Text(
            'No data yet',
            style: TextStyle(color: BeanTheme.lightRoast),
          ),
        ),
      );
    }

    final labels = scores.keys.toList();
    final values = scores.values.toList();

    return SizedBox(
      height: size,
      width: size,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              dataEntries: values
                  .map((v) => RadarEntry(value: v))
                  .toList(),
              borderColor: BeanTheme.caramel,
              fillColor: BeanTheme.caramel.withOpacity(0.2),
              borderWidth: 2,
              entryRadius: 3,
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: BorderSide(
            color: BeanTheme.latte,
            width: 1,
          ),
          titlePositionPercentageOffset: 0.2,
          titleTextStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: BeanTheme.mediumRoast,
          ),
          getTitle: (index, angle) {
            return RadarChartTitle(
              text: labels[index],
              angle: 0,
            );
          },
          tickCount: 5,
          ticksTextStyle: const TextStyle(fontSize: 0),
          tickBorderData: BorderSide(
            color: BeanTheme.latte.withOpacity(0.5),
            width: 0.5,
          ),
          gridBorderData: BorderSide(
            color: BeanTheme.latte,
            width: 0.5,
          ),
          radarShape: RadarShape.polygon,
        ),
      ),
    );
  }
}
