class ProgressData {
  final double currentWeight;
  final double totalCalories;
  final int month;

  ProgressData({
    required this.currentWeight,
    required this.totalCalories,
    required this.month,
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      currentWeight: _parseDouble(json['currentWeight']),
      totalCalories: _parseDouble(json['totalCalories']),
      month: json['month'] as int,
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

class ProgressResponse {
  final int statusCode;
  final String averageCurrentWeight;
  final List<ProgressData> data;

  ProgressResponse({
    required this.statusCode,
    required this.averageCurrentWeight,
    required this.data,
  });

  factory ProgressResponse.fromJson(Map<String, dynamic> json) {
    return ProgressResponse(
      statusCode: json['statusCode'] as int,
      averageCurrentWeight: json['averageCurrentWeight'] as String,
      data: (json['data'] as List)
          .map((item) => ProgressData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  double get averageWeight => double.tryParse(averageCurrentWeight) ?? 0.0;
}
