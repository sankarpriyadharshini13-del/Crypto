import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/ticker.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class PriceChart extends StatelessWidget {
  final List<Candle> candles;
  const PriceChart({super.key, required this.candles});

  @override
  Widget build(BuildContext context) {
    final t0 = candles.first.time.millisecondsSinceEpoch;
    final spots = [
      for (final c in candles) FlSpot((c.time.millisecondsSinceEpoch - t0) / 60000.0, c.close),
    ];
    final minY = candles.map((c) => c.low).reduce(math.min);
    final maxY = candles.map((c) => c.high).reduce(math.max);
    final pad = (maxY - minY) > 0 ? (maxY - minY) * 0.12 : maxY * 0.002;
    final up = candles.last.close >= candles.first.close;
    final color = up ? AppColors.up : AppColors.down;
    final maxX = spots.last.x > 0 ? spots.last.x : 1.0;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY - pad,
        maxY: maxY + pad,
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border.withOpacity(0.5), strokeWidth: 1),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface2,
            getTooltipItems: (touched) => touched.map((s) {
              final c = candles[s.spotIndex];
              return LineTooltipItem(
                '${fmtPrice(c.close)}\n',
                const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 13),
                children: [
                  TextSpan(text: fmtTime(c.time), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500, fontSize: 11)),
                ],
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.12,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2.2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.28), color.withOpacity(0.0)],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }
}
