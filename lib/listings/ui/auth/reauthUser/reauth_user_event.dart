part of 'reauth_user_bloc.dart';

abstract class ReauthUserEvent {}

class VerifyPhoneNumberEvent extends ReauthUserEvent {
  String phoneNumber;

  VerifyPhoneNumberEvent({required this.phoneNumber});
}

class PasswordClickEvent extends ReauthUserEvent {
  String currentEmail;
  String? newEmail;
  String password;
  bool isDeleteUser;

  PasswordClickEvent({
    required this.currentEmail,
    required this.password,
    this.newEmail,
    required this.isDeleteUser,
  });
}

class FacebookClickEvent extends ReauthUserEvent {}

class AppleClickEvent extends ReauthUserEvent {}

class SubmitSmsCodeEvent extends ReauthUserEvent {
  String verificationID;
  String smsCode;
  bool isDeleteUser;

  SubmitSmsCodeEvent({
    required this.verificationID,
    required this.smsCode,
    this.isDeleteUser = true,
  });
}
