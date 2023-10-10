part of 'reauth_user_bloc.dart';

abstract class ReauthUserState {}

class ReauthUserInitial extends ReauthUserState {
  AuthProviders provider;

  ReauthUserInitial({required this.provider});
}

class CodeSentState extends ReauthUserState {
  String verificationID;

  CodeSentState({required this.verificationID});
}

class AutoPhoneVerificationCompletedState extends ReauthUserState {
  auth.PhoneAuthCredential credential;

  AutoPhoneVerificationCompletedState({required this.credential});
}

class ReauthSuccessfulSate extends ReauthUserState {}

class ReauthFailureState extends ReauthUserState {
  String errorMessage;

  ReauthFailureState({required this.errorMessage});
}
