import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/trend_analytics.dart';

/// Reusable fl_chart widget for multi-week compliance trend visualization.
///
/// Renders:
/// - Overall compliance line across weeks
/// - 4-week moving average overlay
/// - Rolling per-SOP line graph (for single-SOP decay analysis)
/// - Bilingual labels
/// - Honest empty state when insufficient data
class TrendChartWidget extends StatelessWidget {
  const TrendChartWidget({
    super.key,
    required this.trendResult,
    this.locale = 'en',
    this.height = 280,
    this.showPerSopChart = true,
  });

  final TrendAnalysisResult trendResult;
  final String locale;
  final double height;
  final bool showPerSopChart;

  @override
  Widget build(BuildContext context) {
    if (!trendResult.hasSufficientData) {
      return _InsufficientDataCard(
        locale: locale,
        weekCount: trendResult.weeklySeries.length,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Compliance + MA chart
        _SectionHeader(
          titleEn: 'Overall Compliance Trend',
          titleMr: 'एकूण पालन कल',
          locale: locale,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: _OverallTrendChart(
            series: trendResult.weeklySeries,
            movingAverages: trendResult.movingAverages,
          ),
        ),

        if (showPerSopChart && _hasPerSopData()) ...[
          const SizedBox(height: 24),
          _SectionHeader(
            titleEn: 'Per-SOP Rolling Compliance',
            titleMr: 'SOP-अनुसार रोलिंग पालन',
            locale: locale,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: height,
            child: _PerSopTrendChart(
              series: trendResult.weeklySeries,
            ),
          ),
        ],

        if (trendResult.detectedPatterns.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(
            titleEn: 'Detected Patterns',
            titleMr: 'आढळलेले कल',
            locale: locale,
          ),
          const SizedBox(height: 8),
          ...trendResult.detectedPatterns.map(
            (p) => _PatternCard(pattern: p, locale: locale),
          ),
        ],
      ],
    );
  }

  bool _hasPerSopData() {
    return trendResult.weeklySeries.any((w) => w.perSopPct.isNotEmpty);
  }
}

/// Insufficient data empty-state card (graceful degradation).
class _InsufficientDataCard extends StatelessWidget {
  const _InsufficientDataCard({
    required this.locale,
    required this.weekCount,
  });

  final String locale;
  final int weekCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEn = locale != 'mr';
    final needed = 4 - weekCount;

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              isEn
                  ? 'Insufficient Data for Trend Analysis'
                  : 'कल विश्लेषणासाठी अपुरा डेटा',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isEn
                  ? 'Need at least 4 weekly reports to compute trends. Currently have $weekCount report${weekCount == 1 ? '' : 's'} ($needed more needed).'
                  : 'कल गणनेसाठी किमान ४ साप्ताहिक अहवाल आवश्यक आहेत. सध्या $weekCount अहवाल${weekCount == 1 ? '' : ''} आहे${weekCount == 1 ? '' : 'त'} (आणखी $needed आवश्यक).',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Overall compliance line + 4-week MA overlay.
class _OverallTrendChart extends StatelessWidget {
  const _OverallTrendChart({
    required this.series,
    required this.movingAverages,
  });

  final List<WeeklyDataPoint> series;
  final List<MovingAveragePoint> movingAverages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complianceColor = theme.colorScheme.primary;
    final maColor = theme.colorScheme.tertiary;

    // Overall compliance spots
    final complianceSpots = <FlSpot>[];
    for (var i = 0; i < series.length; i++) {
      complianceSpots.add(FlSpot(i.toDouble(), series[i].overallPct));
    }

    // MA spots (skip nulls)
    final maSpots = <FlSpot>[];
    for (var i = 0; i < movingAverages.length; i++) {
      if (movingAverages[i].value != null) {
        maSpots.add(FlSpot(i.toDouble(), movingAverages[i].value!));
      }
    }

    // Determine Y-axis range
    final allPcts = series.map((s) => s.overallPct).toList();
    if (maSpots.isNotEmpty) {
      allPcts.addAll(
        movingAverages
            .where((m) => m.value != null)
            .map((m) => m.value!),
      );
    }
    final minY = ((allPcts.reduce((a, b) => a < b ? a : b) - 5) / 5).floor() * 5.0;
    final maxY = ((allPcts.reduce((a, b) => a > b ? a : b) + 5) / 5).ceil() * 5.0;

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 8),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (series.length - 1).toDouble(),
          minY: minY.clamp(0, 100),
          maxY: maxY.clamp(0, 100),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withAlpha(80),
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= series.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'W${series[idx].weekNumber}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 1),
              left: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          lineBarsData: [
            // Overall compliance line
            LineChartBarData(
              spots: complianceSpots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: complianceColor,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: complianceColor,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: complianceColor.withAlpha(30),
              ),
            ),
            // 4-Week MA overlay
            if (maSpots.isNotEmpty)
              LineChartBarData(
                spots: maSpots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: maColor,
                barWidth: 2,
                dashArray: [6, 3],
                dotData: const FlDotData(show: false),
              ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final isMA = spot.barIndex == 1;
                  return LineTooltipItem(
                    isMA
                        ? '4W MA: ${spot.y.toStringAsFixed(1)}%'
                        : 'W${series[spot.x.toInt()].weekNumber}: ${spot.y.toStringAsFixed(1)}%',
                    TextStyle(
                      color: isMA ? maColor : complianceColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Per-SOP rolling compliance chart (§4.5 — the rolling four-week per-SOP graph).
class _PerSopTrendChart extends StatelessWidget {
  const _PerSopTrendChart({required this.series});

  final List<WeeklyDataPoint> series;

  static const _sopColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFF44336), // Red
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFF795548), // Brown
    Color(0xFFE91E63), // Pink
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Collect all SOP IDs across weeks
    final allSopIds = <String>{};
    for (final w in series) {
      allSopIds.addAll(w.perSopPct.keys);
    }
    final sortedSopIds = allSopIds.toList()..sort();

    // Build line data for each SOP
    final lineBars = <LineChartBarData>[];
    for (var si = 0; si < sortedSopIds.length; si++) {
      final sopId = sortedSopIds[si];
      final color = _sopColors[si % _sopColors.length];
      final spots = <FlSpot>[];

      for (var i = 0; i < series.length; i++) {
        final pct = series[i].perSopPct[sopId];
        if (pct != null) {
          spots.add(FlSpot(i.toDouble(), pct));
        }
      }

      if (spots.length >= 2) {
        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: color,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 1.5,
                strokeColor: theme.colorScheme.surface,
              ),
            ),
          ),
        );
      }
    }

    if (lineBars.isEmpty) {
      return Center(
        child: Text(
          'No per-SOP data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Y-axis range
    final allPcts = <double>[];
    for (final w in series) {
      allPcts.addAll(w.perSopPct.values);
    }
    final minY = allPcts.isNotEmpty
        ? ((allPcts.reduce((a, b) => a < b ? a : b) - 5) / 5).floor() * 5.0
        : 70.0;
    final maxY = allPcts.isNotEmpty
        ? ((allPcts.reduce((a, b) => a > b ? a : b) + 5) / 5).ceil() * 5.0
        : 100.0;

    return Column(
      children: [
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: sortedSopIds.asMap().entries.map((e) {
            final color = _sopColors[e.key % _sopColors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 3,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'SOP ${e.value}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 8),
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (series.length - 1).toDouble(),
                minY: minY.clamp(0, 100),
                maxY: maxY.clamp(0, 100),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.dividerColor.withAlpha(80),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= series.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'W${series[idx].weekNumber}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor, width: 1),
                    left: BorderSide(color: theme.dividerColor, width: 1),
                  ),
                ),
                lineBarsData: lineBars,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final sopIdx = spot.barIndex;
                        final sopId =
                            sopIdx < sortedSopIds.length ? sortedSopIds[sopIdx] : '?';
                        return LineTooltipItem(
                          'SOP $sopId: ${spot.y.toStringAsFixed(1)}%',
                          TextStyle(
                            color: _sopColors[sopIdx % _sopColors.length],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Section header with bilingual title.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.titleEn,
    required this.titleMr,
    required this.locale,
  });

  final String titleEn;
  final String titleMr;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEn = locale != 'mr';
    return Text(
      isEn ? titleEn : titleMr,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

/// Card showing a detected trend pattern.
class _PatternCard extends StatelessWidget {
  const _PatternCard({
    required this.pattern,
    required this.locale,
  });

  final TrendPattern pattern;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEn = locale != 'mr';

    final Color severityColor;
    final IconData severityIcon;
    switch (pattern.severity) {
      case 'critical':
        severityColor = Colors.red.shade700;
        severityIcon = Icons.error;
        break;
      case 'warning':
        severityColor = Colors.orange.shade700;
        severityIcon = Icons.warning_amber_rounded;
        break;
      default:
        severityColor = Colors.blue.shade600;
        severityIcon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(severityIcon, color: severityColor),
        title: Text(
          isEn ? pattern.nameEn : pattern.nameMr,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: severityColor,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            isEn ? pattern.descriptionEn : pattern.descriptionMr,
            style: theme.textTheme.bodySmall,
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}
