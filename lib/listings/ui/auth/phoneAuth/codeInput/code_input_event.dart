part of 'code_input_bloc.dart';

abstract class CodeInputEvent {}

class SubmitCodeEvent extends CodeInputEvent {
  String code, verificationID;

  SubmitCodeEvent({required this.code, required this.verificationID});
}
