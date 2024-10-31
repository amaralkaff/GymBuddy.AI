// lib/models/weight_manager.dart

import 'package:flutter_bloc/flutter_bloc.dart';

class WeightManager extends Cubit<int> {
  // Initialize with a default value (0) instead of null
  WeightManager() : super(0);

  void updateWeight(int weight) {
    emit(weight.toInt()); // Ensure it's an integer
  }

  int getWeight() => state;

  bool hasWeight() => state > 0;
}