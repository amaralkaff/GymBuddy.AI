class ProgressResponse {
  final int statusCode;
  final String averageCurrentWeight;
  final double caloriesBurnIn3Month;
  final List<ProgressData> data;

  ProgressResponse({
    required this.statusCode,
    required this.averageCurrentWeight,
    required this.caloriesBurnIn3Month,
    required this.data,
  });

  factory ProgressResponse.fromJson(Map<String, dynamic> json) {
    return ProgressResponse(
      statusCode: json['statusCode'] as int,
      averageCurrentWeight: json['averageCurrentWeight'] ?? '0.0',
      caloriesBurnIn3Month: _parseDouble(json['caloriesBurnIn3Month']),
      data: (json['data'] as List)
          .map((item) => ProgressData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class ProgressData {
  final double currentWeight;
  final double totalCalories;
  final int month;
  final int year;

  ProgressData({
    required this.currentWeight,
    required this.totalCalories,
    required this.month,
    required this.year,
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      currentWeight: _parseDouble(json['currentWeight']),
      totalCalories: _parseDouble(json['totalCalories']),
      month: json['month'] as int,
      year: json['year'] as int,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
