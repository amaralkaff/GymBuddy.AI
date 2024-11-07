import 'dart:async';
import 'dart:math' show min, max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:workout_ai/models/progress_data.dart' as progress;
import 'package:workout_ai/services/progress_service.dart';
import 'package:workout_ai/services/workout_info_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProgressData();
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

  Widget _buildShimmerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShimmerWeightCard(),
        const SizedBox(height: 20),
        ...List.generate(
            3,
            (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildShimmerWorkoutItem(),
                )),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildShimmerWorkoutItem() {
    return Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
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
      ),
    );
  }

  Widget _buildShimmerWeightCard() {
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
              width: 120,
              height: 16,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 32,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.70,
              child: Container(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 60,
                height: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 180,
              height: 16,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 32,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
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
      if (!mounted) return;
      setState(() {
        _isLoadingProgress = false;
      });
    }
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
                      // Add bottom padding
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

    final weightChange =
        sortedData.last.currentWeight - sortedData.first.currentWeight;
    final percentChange = (weightChange / sortedData.first.currentWeight * 100);
    final isGain = weightChange > 0;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderSection(isGain, weightChange, percentChange),
          const SizedBox(height: 24),
          _buildChart(sortedData),
          const SizedBox(height: 8),
          _buildChartLegend(),
          const SizedBox(height: 20),
          _buildCaloriesSection(sortedData),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
      bool isGain, double weightChange, double percentChange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Weight',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _progressData!.data.last.currentWeight.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Kg',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_progressData!.data.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isGain ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isGain ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: isGain ? Colors.red.shade600 : Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${weightChange.abs().toStringAsFixed(1)} (${isGain ? '+' : '-'}${percentChange.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    color: isGain ? Colors.red.shade600 : Colors.green.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Weight', Colors.blue),
        if (_progressData != null && _progressData!.data.length > 1) ...[
          const SizedBox(width: 24),
          _buildLegendItem('Calories', Colors.green),
        ],
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<progress.ProgressData> sortedData) {
    if (sortedData.isEmpty) return const SizedBox.shrink();

    try {
      final weights = sortedData.map((d) => d.currentWeight).toList();
      if (weights.isEmpty) return const SizedBox.shrink();

      final minWeight = weights.reduce(min);
      final maxWeight = weights.reduce(max);

      if (maxWeight - minWeight < 0.01) {
        return Container(
          height: 200,
          alignment: Alignment.center,
          child: Text(
            'Weight: ${weights.first.toStringAsFixed(1)} kg',
            style: const TextStyle(fontSize: 16),
          ),
        );
      }

      return RepaintBoundary(
        child: AspectRatio(
          aspectRatio: 1.70,
          child: Padding(
            padding:
                const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxWeight - minWeight) / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
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
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedData.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _getMonthName(sortedData[index].month),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (maxWeight - minWeight) / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (sortedData.length - 1).toDouble(),
                minY: minWeight - 1,
                maxY: maxWeight + 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: sortedData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.currentWeight,
                      );
                    }).toList(),
                    isCurved: false,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.blue,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Chart error: $e');
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('Unable to display chart'),
      );
    }
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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

  Widget _buildWorkoutItem(WorkoutInfo workout, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
          ),
        ),
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
        ),
      ),
    );
  }

  Widget _buildCaloriesSection(List<progress.ProgressData> sortedData) {
    final lastEntry = sortedData.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Calories',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              lastEntry.totalCalories.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'kcal',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
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
    return monthNames[month - 1];
  }
}
