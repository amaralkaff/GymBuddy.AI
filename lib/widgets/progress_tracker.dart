import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/progress_data.dart' as progress;
import '../services/progress_service.dart';
import '../services/workout_info_service.dart';

enum ChartView { weight, calories }

class ProgressTracker extends StatefulWidget {
  final List<WorkoutInfo> workouts;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const ProgressTracker({
    super.key,
    required this.workouts,
    required this.isLoading,
    this.error,
    required this.onRetry,
  });

  @override
  State<ProgressTracker> createState() => _ProgressTrackerState();
}

class _ProgressTrackerState extends State<ProgressTracker> {
  progress.ProgressResponse? _progressData;
  bool _isLoadingProgress = true;
  Timer? _refreshTimer;
  ChartView _currentView = ChartView.weight;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
    _setupRefreshTimer();
  }

  void _setupRefreshTimer() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadProgressData(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProgressData() async {
    if (!mounted) return;

    try {
      if (_progressData == null) {
        setState(() {
          _isLoadingProgress = true;
        });
      }

      final progressService = ProgressService();
      final data = await progressService.getProgress();

      if (!mounted) return;

      setState(() {
        _progressData = data;
        _isLoadingProgress = false;
      });
    } catch (e) {
      debugPrint('Error loading progress data: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingProgress = false;
      });
    }
  }

  void _toggleChartView(ChartView view) {
    setState(() {
      _currentView = view;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = widget.isLoading || _isLoadingProgress;

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadProgressData(),
            Future.delayed(const Duration(milliseconds: 500)),
          ]);
        },
        color: const Color(0xFFE8FE54),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? _buildShimmerContent()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWeightTracker(),
                      const SizedBox(height: 20),
                      if (widget.workouts.isEmpty)
                        _buildEmptyState()
                      else
                        ...widget.workouts.map((workout) {
                          final color = workout.woName.contains('Push')
                              ? Colors.blue
                              : Colors.green;
                          return _buildWorkoutItem(workout, color);
                        }),
                      const SizedBox(height: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightTracker() {
    if (_progressData == null || _progressData!.data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          height: 100,
          child: Center(
            child: Text('No progress data available'),
          ),
        ),
      );
    }

    final sortedData = List<progress.ProgressData>.from(_progressData!.data)
      ..sort((a, b) => a.month.compareTo(b.month));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progress History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _toggleChartView(ChartView.weight),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _currentView == ChartView.weight
                        ? Colors.blue.shade50
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _currentView == ChartView.weight
                          ? Colors.blue.shade200
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.monitor_weight_outlined,
                              color: Colors.blue.shade400, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Current Weight',
                            style: TextStyle(
                                color: Colors.blue.shade700, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${sortedData.last.currentWeight.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        'Avg: ${_progressData!.averageCurrentWeight} kg',
                        style: TextStyle(
                            color: Colors.blue.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _toggleChartView(ChartView.calories),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _currentView == ChartView.calories
                        ? Colors.orange.shade50
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _currentView == ChartView.calories
                          ? Colors.orange.shade200
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_fire_department,
                              color: Colors.orange.shade400, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Calories Burned',
                            style: TextStyle(
                                color: Colors.orange.shade700, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _progressData!.caloriesBurnIn3Month.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      Text(
                        '3-Month Total',
                        style: TextStyle(
                            color: Colors.orange.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 250,
          child: _buildChart(sortedData),
        ),
      ],
    );
  }

  Widget _buildChart(List<progress.ProgressData> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    try {
      final MaterialColor mainColor =
          _currentView == ChartView.weight ? Colors.blue : Colors.orange;
      final bool isWeight = _currentView == ChartView.weight;

      double minY = isWeight ? double.infinity : 0;
      double maxY = isWeight ? -double.infinity : 0;

      for (var item in data) {
        if (isWeight) {
          minY = math.min(minY, item.currentWeight);
          maxY = math.max(maxY, item.currentWeight);
        } else {
          maxY = math.max(maxY, item.totalCalories);
        }
      }

      if (isWeight && minY.isFinite && maxY.isFinite) {
        final padding = (maxY - minY) * 0.1;
        minY -= padding;
        maxY += padding;
      } else if (!isWeight) {
        maxY += maxY * 0.1;
      }

      if (!minY.isFinite || !maxY.isFinite || minY >= maxY) {
        minY = isWeight ? 0 : 0;
        maxY = isWeight ? 100 : 1000;
      }

      final interval = _calculateInterval(minY, maxY);

      return LineChart(
        LineChartData(
          backgroundColor: mainColor.shade50.withOpacity(0.3),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: Colors.white,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final item = data[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${_getMonthName(item.month)}/${item.year}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
                interval: 1,
                reservedSize: 35,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    isWeight
                        ? value.toStringAsFixed(1)
                        : value.toInt().toString(),
                    style: TextStyle(
                      color: mainColor.shade400,
                      fontSize: 12,
                    ),
                  );
                },
                interval: interval,
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  isWeight
                      ? entry.value.currentWeight
                      : entry.value.totalCalories,
                );
              }).toList(),
              isCurved: !isWeight,
              curveSmoothness: 0.3,
              color: mainColor.shade400,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 5,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: mainColor.shade400,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: mainColor.shade50.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error building chart: $e');
      return Container(
        height: 250,
        alignment: Alignment.center,
        child: Text('Error displaying chart: ${e.toString()}'),
      );
    }
  }

  double _calculateInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 1;

    final rough = range / 5;
    final magnitude = math.pow(10, (math.log(rough) / math.ln10).floor());
    final normalized = rough / magnitude;

    if (normalized < 1.5) return magnitude.toDouble();
    if (normalized < 3) return 2 * magnitude.toDouble();
    if (normalized < 7) return 5 * magnitude.toDouble();
    return 10 * magnitude.toDouble();
  }

  Widget _buildShimmerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 160,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildShimmerCard(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildShimmerCard(),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildShimmerChart(),
        const SizedBox(height: 20),
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildShimmerWorkoutItem(),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 80,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerChart() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerWorkoutItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  Widget _buildWorkoutItem(WorkoutInfo workout, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              workout.woName.contains('Push')
                  ? Icons.fitness_center
                  : Icons.accessibility_new,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  workout.woName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatChip(
                      '${workout.sumWo} reps',
                      color,
                      color.withOpacity(0.1),
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      '${workout.totalCalories.toStringAsFixed(1)} cal',
                      Colors.green,
                      Colors.green.withOpacity(0.1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No workouts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first workout to see your progress here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    if (month < 1 || month > 12) {
      debugPrint('Invalid month number: $month');
      return 'Invalid';
    }
    return monthNames[month - 1];
  }
}
