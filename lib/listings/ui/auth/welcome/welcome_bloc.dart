import 'package:bloc/bloc.dart';

part 'welcome_event.dart';

part 'welcome_state.dart';

class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeInitial> {
  WelcomeBloc() : super(WelcomeInitial()) {
    on<LoginPressedEvent>((event, emit) {
      emit(WelcomeInitial(pressTarget: WelcomePressTarget.login));
    });
    on<SignupPressedEvent>((event, emit) {
      emit(WelcomeInitial(pressTarget: WelcomePressTarget.signup));
    });
  }
}
