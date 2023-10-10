import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:instaflutter/listings/ui/auth/api/authentication_repository.dart';

part 'code_input_event.dart';

part 'code_input_state.dart';

class CodeInputBloc extends Bloc<CodeInputEvent, CodeInputState> {
  final AuthenticationRepository authenticationRepository;

  CodeInputBloc({required this.authenticationRepository})
      : super(CodeInputInitial()) {
    on<SubmitCodeEvent>(
      (event, emit) async {
        dynamic result = await authenticationRepository.submitPhoneNumberCode(
            event.verificationID, event.code);
        if (result is auth.PhoneAuthCredential) {
          emit(CodeSubmittedState(credential: result));
        } else if (result is String) {
          emit(CodeSubmitFailedState(errorMessage: result));
        }
      },
    );
  }
}
