import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/auth/api/authentication_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'authentication_event.dart';

part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  ListingsUser? user;
  late SharedPreferences prefs;
  late bool finishedOnBoarding;
  final AuthenticationRepository authenticationRepository;

  AuthenticationBloc({this.user, required this.authenticationRepository})
      : super(AuthenticationState.unauthenticated()) {
    on<CheckFirstRunEvent>((event, emit) async {
      prefs = await SharedPreferences.getInstance();
      finishedOnBoarding = prefs.getBool(finishedOnBoardingConst) ?? false;
      if (!finishedOnBoarding) {
        emit(AuthenticationState.onboarding());
      } else {
        user = await authenticationRepository.getAuthUser();
        if (user == null) {
          emit(AuthenticationState.unauthenticated());
        } else {
          emit(AuthenticationState.authenticated(user!));
        }
      }
    });
    on<FinishedOnBoardingEvent>((event, emit) async {
      await prefs.setBool(finishedOnBoardingConst, true);
      emit(AuthenticationState.unauthenticated());
    });
    on<LoginWithEmailAndPasswordEvent>((event, emit) async {
      dynamic result = await authenticationRepository.loginWithEmailAndPassword(
          event.email, event.password);
      if (result != null && result is ListingsUser) {
        user = result;
        emit(AuthenticationState.authenticated(user!));
      } else if (result != null && result is String) {
        emit(AuthenticationState.unauthenticated(message: result));
      } else {
        emit(AuthenticationState.unauthenticated(
            message: 'Login failed, Please try again.'.tr()));
      }
    });
    on<LoginWithFacebookEvent>((event, emit) async {
      dynamic result = await authenticationRepository.loginWithFacebook();
      if (result != null && result is ListingsUser) {
        user = result;
        emit(AuthenticationState.authenticated(user!));
      } else if (result != null && result is String) {
        emit(AuthenticationState.unauthenticated(message: result));
      } else {
        emit(AuthenticationState.unauthenticated(
            message: 'Facebook login failed, Please try again.'.tr()));
      }
    });
    on<LoginWithAppleEvent>((event, emit) async {
      dynamic result = await authenticationRepository.loginWithApple();
      if (result != null && result is ListingsUser) {
        user = result;
        emit(AuthenticationState.authenticated(user!));
      } else if (result != null && result is String) {
        emit(AuthenticationState.unauthenticated(message: result));
      } else {
        emit(AuthenticationState.unauthenticated(
            message: 'Apple login failed, Please try again.'.tr()));
      }
    });

    on<LoginWithPhoneNumberEvent>((event, emit) async {
      dynamic result = await authenticationRepository
          .loginOrCreateUserWithPhoneNumberCredential(
              credential: event.credential,
              phoneNumber: event.phoneNumber,
              firstName: event.firstName,
              lastName: event.lastName,
              image: event.image);
      if (result is ListingsUser) {
        user = result;
        emit(AuthenticationState.authenticated(result));
      } else if (result is String) {
        emit(AuthenticationState.unauthenticated(message: result));
      }
    });
    on<SignupWithEmailAndPasswordEvent>((event, emit) async {
      dynamic result =
          await authenticationRepository.signUpWithEmailAndPassword(
              emailAddress: event.emailAddress,
              password: event.password,
              image: event.image,
              firstName: event.firstName,
              lastName: event.lastName);
      if (result != null && result is ListingsUser) {
        user = result;
        emit(AuthenticationState.authenticated(user!));
      } else if (result != null && result is String) {
        emit(AuthenticationState.unauthenticated(message: result));
      } else {
        emit(AuthenticationState.unauthenticated(
            message: 'Couldn\'t sign up'.tr()));
      }
    });
    on<UserDeletedEvent>((event, emit) {
      user = null;
      emit(AuthenticationState.unauthenticated());
    });
    on<LogoutEvent>((event, emit) async {
      await authenticationRepository.logout(event.user);
      user = null;
      emit(AuthenticationState.unauthenticated());
    });
  }
}
