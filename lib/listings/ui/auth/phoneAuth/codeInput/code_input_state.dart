part of 'code_input_bloc.dart';

abstract class CodeInputState {}

class CodeInputInitial extends CodeInputState {}

class CodeSubmittedState extends CodeInputState {
  auth.PhoneAuthCredential credential;

  CodeSubmittedState({required this.credential});
}

class CodeSubmitFailedState extends CodeInputState {
  String errorMessage;

  CodeSubmitFailedState({required this.errorMessage});
}
