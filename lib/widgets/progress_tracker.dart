import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:workout_ai/services/progress_service.dart';
import 'package:workout_ai/models/progress_data.dart' as progress;
import 'package:workout_ai/services/workout_info_service.dart';
import 'dart:math' show min, max;

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
  String? _progressError;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    try {
      setState(() {
        _isLoadingProgress = true;
        _progressError = null;
      });

      final progressService = ProgressService();
      final data = await progressService.getProgress();

      setState(() {
        _progressData = data;
        _isLoadingProgress = false;
      });
    } catch (e) {
      setState(() {
        _progressError = e.toString();
        _isLoadingProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || _isLoadingProgress) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.error != null) {
      return _buildErrorWidget();
    }

    if (_progressError != null) {
      return _buildProgressErrorWidget();
    }

    return RefreshIndicator(
      onRefresh: _loadProgressData,
      child: ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildWeightTracker(),
          const SizedBox(height: 20),
          if (widget.workouts.isEmpty)
            _buildEmptyState()
          else
            ...widget.workouts.map((workout) {
              final color =
                  workout.woName.contains('Push') ? Colors.blue : Colors.green;
              return _buildWorkoutItem(workout, color);
            }),
        ],
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
        child: const Text('No progress data available'),
      );
    }

    // Sort data by month
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
              'Current Weight', // Changed from 'Average Weight'
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  // Use current weight from the latest data point
                  _progressData!.data.last.currentWeight.toString(),
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
        // Only show weight change if we have more than one month of data
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
                  '${weightChange.abs().toStringAsFixed(2)} (${isGain ? '+' : '-'}${percentChange.toStringAsFixed(1)}%)',
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

  Widget _buildChart(List<progress.ProgressData> sortedData) {
    // Calculate ranges
    final minWeight = sortedData.map((d) => d.currentWeight).reduce(min);
    final maxWeight = sortedData.map((d) => d.currentWeight).reduce(max);
    final minCalories = sortedData.map((d) => d.totalCalories).reduce(min);
    final maxCalories = sortedData.map((d) => d.totalCalories).reduce(max);

    // Calculate scale factors
    final weightRange = maxWeight - minWeight;
    final caloriesRange = maxCalories - minCalories;

    // Adjust padding and range for single month
    final chartPadding = sortedData.length == 1
        ? maxWeight * 0.1 // 10% of the weight value
        : weightRange * 0.1;

    // For single month, create a wider display range
    final effectiveMinWeight = sortedData.length == 1
        ? minWeight * 0.9 // Show 90% of the weight value as minimum
        : minWeight - chartPadding;
    final effectiveMaxWeight = sortedData.length == 1
        ? maxWeight * 1.1 // Show 110% of the weight value as maximum
        : maxWeight + chartPadding;

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding:
            const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (effectiveMaxWeight - effectiveMinWeight) / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                );
              },
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
                    if (value.toInt() >= sortedData.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _getMonthName(sortedData[value.toInt()].month),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: sortedData.length == 1
                      ? (effectiveMaxWeight - effectiveMinWeight) / 5
                      : weightRange / 5,
                  reservedSize: 45,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(1),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX:
                sortedData.length == 1 ? 1 : (sortedData.length - 1).toDouble(),
            minY: effectiveMinWeight,
            maxY: effectiveMaxWeight,
            lineBarsData: [
              // Weight Line
              LineChartBarData(
                spots: sortedData.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value.currentWeight,
                  );
                }).toList(),
                isCurved:
                    sortedData.length > 1, // Only curve if multiple points
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
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
              // Calories Line (scaled to weight range)
              if (sortedData.length >
                  1) // Only show calories line for multiple months
                LineChartBarData(
                  spots: sortedData.asMap().entries.map((entry) {
                    final scaledCalories =
                        (entry.value.totalCalories - minCalories) *
                                (weightRange / caloriesRange) +
                            minWeight;
                    return FlSpot(entry.key.toDouble(), scaledCalories);
                  }).toList(),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  dashArray: [5, 5],
                ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => Colors.blue,
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final data = sortedData[spot.x.toInt()];
                    final isWeight = spot.barIndex == 0;
                    return LineTooltipItem(
                      isWeight
                          ? 'Weight: ${data.currentWeight.toStringAsFixed(1)} kg'
                          : 'Month Total: ${data.totalCalories.toStringAsFixed(1)} cal',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '\n${_getMonthName(data.month)}',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 10,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
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

  Widget _buildCaloriesSection(List<progress.ProgressData> sortedData) {
    // Just use the calories from the current month
    final currentMonthCalories = sortedData.last.totalCalories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calories Burned This Month', // Changed text to be more specific
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              currentMonthCalories.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Kcal',
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

  Widget _buildProgressErrorWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
          const SizedBox(height: 16),
          Text(
            'Error loading progress data:\n$_progressError',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadProgressData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.error!.contains('Authentication')
                      ? 'Please log in again to view your progress'
                      : 'Unable to load workout progress',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.error!,
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.fitness_center, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No workouts yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Complete your first workout to see your progress here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutItem(WorkoutInfo workout, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            workout.woName.contains('Push')
                ? Icons.fitness_center
                : Icons.accessibility_new,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
        ),
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
    return monthNames[month - 1];
  }
}
