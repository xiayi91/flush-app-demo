import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:instaflutter/listings/ui/auth/api/authentication_repository.dart';

part 'reset_password_state.dart';

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  final AuthenticationRepository authenticationRepository;

  ResetPasswordCubit({required this.authenticationRepository})
      : super(ResetPasswordInitial());

  resetPassword(String email) async {
    await authenticationRepository.resetPassword(email);
    emit(ResetPasswordDoneState());
  }

  checkValidField(GlobalKey<FormState> key) {
    if (key.currentState?.validate() ?? false) {
      key.currentState!.save();
      emit(ValidResetPasswordFieldState());
    } else {
      emit(ResetPasswordFailureState(
          errorMessage: 'Invalid email address.'.tr()));
    }
  }
}
