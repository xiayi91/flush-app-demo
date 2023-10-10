part of 'phone_number_input_bloc.dart';

abstract class PhoneNumberInputState {}

class PhoneNumberInputInitial extends PhoneNumberInputState {}

class PictureSelectedState extends PhoneNumberInputState {
  File? imageFile;

  PictureSelectedState({required this.imageFile});
}

class PhoneInputFailureState extends PhoneNumberInputState {
  String errorMessage;

  PhoneInputFailureState({required this.errorMessage});
}

class ValidFieldsState extends PhoneNumberInputState {}

class EulaToggleState extends PhoneNumberInputState {
  bool eulaAccepted;

  EulaToggleState(this.eulaAccepted);
}

class CodeSentState extends PhoneNumberInputState {
  String verificationID;

  CodeSentState({required this.verificationID});
}

class AutoPhoneVerificationCompletedState extends PhoneNumberInputState {
  auth.PhoneAuthCredential credential;

  AutoPhoneVerificationCompletedState({required this.credential});
}
