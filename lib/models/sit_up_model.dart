import 'package:flutter_bloc/flutter_bloc.dart';

enum SitUpState {
  neutral,    // Starting position (lying down)
  init,       // Beginning to lift
  complete    // Upper body raised
}

class SitUpCounter extends Cubit<SitUpState> {
  int counter = 0;
  
  SitUpCounter() : super(SitUpState.neutral);
  
  void setSitUpState(SitUpState currentState) {
    emit(currentState);
  }
  
  void incrementCounter() {
    counter++;
    emit(SitUpState.complete);
  }
  
  void resetCounter() {
    counter = 0;
    emit(state);
  }
}