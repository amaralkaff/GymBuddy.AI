import 'package:flutter/material.dart';
import 'package:workout_ai/services/workout_info_service.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressTracker extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return _buildErrorWidget();
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildWeightTracker(),
        const SizedBox(height: 20),
        if (workouts.isEmpty)
          _buildEmptyState()
        else
          ...workouts.map((workout) {
            final color =
                workout.woName.contains('Push') ? Colors.blue : Colors.green;
            return _buildWorkoutItem(workout, color);
          }),
      ],
    );
  }

  Widget _buildWeightTracker() {
    final weightData = [
      WeightData(DateTime(2024, 1, 1), 92.3),
      WeightData(DateTime(2024, 2, 1), 80.4),
      WeightData(DateTime(2024, 3, 1), 90.22),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                        '90.22',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward,
                        size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '4.2 (+2.68%)',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= weightData.length)
                          return const Text('');
                        return Text(
                          _getMonthName(weightData[value.toInt()].date.month),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                  border: Border.all(color: const Color(0xff37434d)),
                ),
                minX: 0,
                maxX: weightData.length.toDouble() - 1,
                minY: _getMinWeight(weightData) - 5,
                maxY: _getMaxWeight(weightData) + 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: weightData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.weight);
                    }).toList(),
                    isCurved: true,
                    color: Colors.grey.shade600,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.grey.shade600,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        return LineTooltipItem(
                          '${barSpot.y.toStringAsFixed(1)} kg',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calories Burned',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '1280',
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
              ),
            ],
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
                  error!.contains('Authentication')
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
            error!,
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: onRetry,
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
      child: Column(
        children: [
          Row(
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
                          '${workout.sumWo} sets',
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

  double _getMinWeight(List<WeightData> data) {
    return data.map((item) => item.weight).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxWeight(List<WeightData> data) {
    return data.map((item) => item.weight).reduce((a, b) => a > b ? a : b);
  }
}

class WeightData {
  final DateTime date;
  final double weight;

  WeightData(this.date, this.weight);
}
