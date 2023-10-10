import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/auth/api/authentication_repository.dart';
import 'package:instaflutter/listings/ui/auth/reauthUser/reauth_user_bloc.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart' as apple;

class AuthCustomBackendUtils extends AuthenticationRepository {
  @override
  Future<ListingsUser?> getAuthUser() {
    // TODO: implement getAuthUser
    throw UnimplementedError();
  }

  @override
  auth.AuthCredential getUserAuthCredential(AuthProviders provider,
      {String? email,
      String? password,
      String? smsCode,
      String? verificationId,
      AccessToken? accessToken,
      apple.AuthorizationResult? appleCredential}) {
    // TODO: implement getUserAuthCredential
    throw UnimplementedError();
  }

  @override
  Future loginOrCreateUserWithPhoneNumberCredential(
      {required auth.PhoneAuthCredential credential,
      required String phoneNumber,
      String? firstName = 'Anonymous',
      String? lastName = 'User',
      File? image}) {
    // TODO: implement loginOrCreateUserWithPhoneNumberCredential
    throw UnimplementedError();
  }

  @override
  loginWithApple() {
    // TODO: implement loginWithApple
    throw UnimplementedError();
  }

  @override
  Future loginWithEmailAndPassword(String email, String password) {
    // TODO: implement loginWithEmailAndPassword
    throw UnimplementedError();
  }

  @override
  loginWithFacebook() {
    // TODO: implement loginWithFacebook
    throw UnimplementedError();
  }

  @override
  logout(ListingsUser user) {
    // TODO: implement logout
    throw UnimplementedError();
  }

  @override
  resetPassword(String emailAddress) {
    // TODO: implement resetPassword
    throw UnimplementedError();
  }

  @override
  Future signUpWithEmailAndPassword(
      {required String emailAddress,
      required String password,
      File? image,
      firstName = 'Anonymous',
      lastName = 'User'}) {
    // TODO: implement signUpWithEmailAndPassword
    throw UnimplementedError();
  }

  @override
  Future submitPhoneNumberCode(String verificationID, String code) {
    // TODO: implement submitPhoneNumberCode
    throw UnimplementedError();
  }

  @override
  Future<bool> updateOrDeleteAuthUser(AuthProviders provider,
      {required bool isDelete,
      String? currentEmail,
      String? newEmail,
      String? password,
      String? smsCode,
      String? verificationId,
      AccessToken? accessToken,
      apple.AuthorizationResult? appleCredential}) {
    // TODO: implement updateOrDeleteAuthUser
    throw UnimplementedError();
  }

  @override
  updatePhoneNumber(auth.PhoneAuthCredential credential) {
    // TODO: implement updatePhoneNumber
    throw UnimplementedError();
  }

  @override
  verifyPhoneNumber(
      {required String phoneNumber,
      required auth.PhoneCodeAutoRetrievalTimeout phoneCodeAutoRetrievalTimeout,
      required auth.PhoneCodeSent phoneCodeSent,
      required auth.PhoneVerificationFailed phoneVerificationFailed,
      required auth.PhoneVerificationCompleted phoneVerificationCompleted}) {
    // TODO: implement verifyPhoneNumber
    throw UnimplementedError();
  }
}
