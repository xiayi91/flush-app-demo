// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:instaflutter/listings/ui/auth/api/authentication_repository.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart' as apple;

part 'reauth_user_event.dart';

part 'reauth_user_state.dart';

enum AuthProviders { password, phone, facebook, apple }

class ReauthUserBloc extends Bloc<ReauthUserEvent, ReauthUserState> {
  final AuthenticationRepository authenticationRepository;

  ReauthUserBloc(
      {required AuthProviders provider, required this.authenticationRepository})
      : super(ReauthUserInitial(provider: provider)) {
    on<PasswordClickEvent>((event, emit) async {
      if (event.password.isNotEmpty) {
        bool success = await authenticationRepository.updateOrDeleteAuthUser(
            provider,
            isDelete: event.isDeleteUser,
            currentEmail: event.currentEmail,
            newEmail: event.newEmail,
            password: event.password);
        if (success) {
          emit(ReauthSuccessfulSate());
        } else {
          emit(ReauthFailureState(
              errorMessage:
                  'Please double check your email and password and try again.'
                      .tr()));
        }
      } else {
        emit(ReauthFailureState(
            errorMessage: 'Password is required to update email'.tr()));
      }
    });

    on<FacebookClickEvent>((event, emit) async {
      try {
        AccessToken? token;
        FacebookAuth facebookAuth = FacebookAuth.instance;
        if (await facebookAuth.accessToken == null) {
          LoginResult result = await facebookAuth.login();
          if (result.status == LoginStatus.success) {
            token = await facebookAuth.accessToken;
          } else {
            emit(ReauthFailureState(
                errorMessage: 'Authentication failed with Facebook.'.tr()));
          }
        } else {
          token = await facebookAuth.accessToken;
        }
        if (token != null) {
          bool success = await authenticationRepository.updateOrDeleteAuthUser(
              provider,
              isDelete: true,
              accessToken: token);
          if (success) {
            emit(ReauthSuccessfulSate());
          } else {
            emit(ReauthFailureState(
                errorMessage: 'Couldn\'t verify with Facebook.'.tr()));
          }
        } else {
          emit(ReauthFailureState(
              errorMessage: 'Couldn\'t verify with Facebook.'.tr()));
        }
      } catch (e, s) {
        debugPrint('FacebookClickEvent $e $s');
        emit(ReauthFailureState(
            errorMessage: 'Couldn\'t verify with Facebook.'.tr()));
      }
    });

    on<AppleClickEvent>((event, emit) async {
      try {
        final appleCredential = await apple.TheAppleSignIn.performRequests([
          const apple.AppleIdRequest(
              requestedScopes: [apple.Scope.email, apple.Scope.fullName])
        ]);
        if (appleCredential.error != null) {
          emit(ReauthFailureState(
              errorMessage: 'Couldn\'t verify with Apple.'.tr()));
        }
        if (appleCredential.status == apple.AuthorizationStatus.authorized) {
          bool success = await authenticationRepository.updateOrDeleteAuthUser(
              provider,
              isDelete: true,
              appleCredential: appleCredential);
          if (success) {
            emit(ReauthSuccessfulSate());
          } else {
            emit(ReauthFailureState(
                errorMessage: 'Couldn\'t verify with Apple.'.tr()));
          }
        } else {
          emit(ReauthFailureState(
              errorMessage: 'Couldn\'t verify with Apple.'.tr()));
        }
      } catch (e, s) {
        debugPrint('AppleClickEvent $e $s');
        emit(ReauthFailureState(
            errorMessage: 'Couldn\'t verify with Apple.'.tr()));
      }
    });

    on<SubmitSmsCodeEvent>((event, emit) async {
      try {
        bool success;
        if (event.isDeleteUser) {
          success = await authenticationRepository.updateOrDeleteAuthUser(
              provider,
              isDelete: event.isDeleteUser,
              smsCode: event.smsCode,
              verificationId: event.verificationID);
        } else {
          await authenticationRepository.updatePhoneNumber(
              authenticationRepository.getUserAuthCredential(provider,
                      smsCode: event.smsCode,
                      verificationId: event.verificationID)
                  as auth.PhoneAuthCredential);
          success = true;
        }
        if (success) {
          emit(ReauthSuccessfulSate());
        } else {
          emit(ReauthFailureState(
              errorMessage: 'Couldn\'t verify SMS code.'.tr()));
        }
      } catch (e, s) {
        debugPrint('SubmitSmsCodeEvent $e $s');
        emit(ReauthFailureState(
            errorMessage: 'Couldn\'t verify SMS code.'.tr()));
      }
    });
    on<VerifyPhoneNumberEvent>((event, emit) async {
      await authenticationRepository.verifyPhoneNumber(
          phoneNumber: event.phoneNumber,
          phoneCodeAutoRetrievalTimeout: onPhoneCodeAutoRetrievalTimeout,
          phoneCodeSent: onPhoneCodeSent,
          phoneVerificationFailed: onPhoneVerificationFailed,
          phoneVerificationCompleted: onPhoneVerificationCompleted);
    });
  }

  void onPhoneVerificationCompleted(
      auth.PhoneAuthCredential phoneAuthCredential) {
    emit(AutoPhoneVerificationCompletedState(credential: phoneAuthCredential));
  }

  void onPhoneVerificationFailed(auth.FirebaseAuthException error) {
    String message = 'An error has occurred, please try again.'.tr();
    switch (error.code) {
      case 'invalid-verification-code':
        message = 'Invalid code or has been expired.'.tr();
        break;
      case 'user-disabled':
        message = 'This user has been disabled.'.tr();
        break;
      default:
        message = 'An error has occurred, please try again.'.tr();
        break;
    }
    debugPrint(
        'PhoneNumberInputBloc.onPhoneVerificationFailed ${error.code} ${error.message}');
    emit(ReauthFailureState(errorMessage: message));
  }

  void onPhoneCodeSent(String verificationId, int? forceResendingToken) {
    emit(CodeSentState(verificationID: verificationId));
  }

  void onPhoneCodeAutoRetrievalTimeout(String verificationId) {
    emit(CodeSentState(verificationID: verificationId));
  }
}
