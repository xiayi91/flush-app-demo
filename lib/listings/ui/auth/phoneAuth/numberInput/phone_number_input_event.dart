part of 'phone_number_input_bloc.dart';

abstract class PhoneNumberInputEvent {}

class RetrieveLostDataEvent extends PhoneNumberInputEvent {}

class ChooseImageFromGalleryEvent extends PhoneNumberInputEvent {
  ChooseImageFromGalleryEvent();
}

class CaptureImageByCameraEvent extends PhoneNumberInputEvent {
  CaptureImageByCameraEvent();
}

class ValidateFieldsEvent extends PhoneNumberInputEvent {
  GlobalKey<FormState> key;
  bool acceptEula, isLogin, isPhoneValid;

  ValidateFieldsEvent(
    this.key, {
    required this.acceptEula,
    required this.isLogin,
    required this.isPhoneValid,
  });
}

class ToggleEulaCheckboxEvent extends PhoneNumberInputEvent {
  bool eulaAccepted;

  ToggleEulaCheckboxEvent({required this.eulaAccepted});
}

class VerifyPhoneNumberEvent extends PhoneNumberInputEvent {
  String phoneNumber;

  VerifyPhoneNumberEvent({required this.phoneNumber});
}
