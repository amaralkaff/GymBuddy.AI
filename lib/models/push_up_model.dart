import 'package:flutter_bloc/flutter_bloc.dart';

enum PushUpState {
  neutral,
  init,
  complete
}

class PushUpCounter extends Cubit<PushUpState> {
  int counter = 0;

  PushUpCounter() : super(PushUpState.neutral);

  void setPushUpState(PushUpState currentState) {
    emit(currentState);
  }

  void incrementCounter() {
    counter++;
    emit(PushUpState.complete);
  }
}
