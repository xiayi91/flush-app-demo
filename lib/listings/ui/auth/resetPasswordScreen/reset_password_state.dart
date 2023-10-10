part of 'reset_password_cubit.dart';

abstract class ResetPasswordState {}

class ResetPasswordInitial extends ResetPasswordState {}

class ValidResetPasswordFieldState extends ResetPasswordState {}

class ResetPasswordFailureState extends ResetPasswordState {
  String errorMessage;

  ResetPasswordFailureState({required this.errorMessage});
}

class ResetPasswordDoneState extends ResetPasswordState {}
