import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/weight_entry.dart';

class WeightChartWidget extends StatelessWidget {
  final List<WeightEntry> entries;
  final String unit;

  const WeightChartWidget({
    super.key,
    required this.entries,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart,
                  size: 40,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.2)),
              const SizedBox(height: 8),
              Text(
                'Log at least 2 entries to see a chart',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final sorted = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.inUnit(unit));
    }).toList();

    final vals = spots.map((s) => s.y).toList();
    final minVal = vals.reduce((a, b) => a < b ? a : b);
    final maxVal = vals.reduce((a, b) => a > b ? a : b);
    final padding = ((maxVal - minVal) * 0.2).clamp(1.0, 10.0);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: minVal - padding,
          maxY: maxVal + padding,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: cs.onSurface.withOpacity(0.08),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                getTitlesWidget: (val, meta) => Text(
                  '${val.toStringAsFixed(0)} $unit',
                  style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurface.withOpacity(0.5)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (sorted.length / 5).ceilToDouble().clamp(1, 999),
                getTitlesWidget: (val, meta) {
                  final idx = val.round();
                  if (idx < 0 || idx >= sorted.length) return const SizedBox();
                  return Text(
                    DateFormat('M/d').format(sorted[idx].date),
                    style: TextStyle(
                        fontSize: 9,
                        color: cs.onSurface.withOpacity(0.5)),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: cs.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: sorted.length <= 20,
                getDotPainter: (spot, pct, bar, idx) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: cs.primary,
                  strokeColor: cs.surface,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withOpacity(0.25),
                    cs.primary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((ts) {
                final entry = sorted[ts.spotIndex];
                return LineTooltipItem(
                  '${DateFormat('MMM d').format(entry.date)}\n'
                  '${entry.inUnit(unit).toStringAsFixed(1)} $unit',
                  TextStyle(
                    color: cs.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
