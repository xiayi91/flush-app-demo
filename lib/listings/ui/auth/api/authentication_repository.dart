import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/auth/reauthUser/reauth_user_bloc.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart' as apple;

abstract class AuthenticationRepository {
  Future<ListingsUser?> getAuthUser();

  /// Try to log in using user [email] and [password]
  /// Returns [ListingsUser] if user if logged in, or [String] error message if failed
  Future<dynamic> loginWithEmailAndPassword(String email, String password);

  /// Try to login with Facebook
  /// Returns [ListingsUser] if user if logged in, or [String] error message if failed
  loginWithFacebook();

  /// Try to login with Apple
  /// Returns [ListingsUser] if user if logged in, or [String] error message if failed
  loginWithApple();

  /// Logs the user in or create a new user if no user already registered with [credential] before.
  /// Returns [ListingsUser] if success, otherwise returns a [String] holding the error message
  Future<dynamic> loginOrCreateUserWithPhoneNumberCredential({
    required auth.PhoneAuthCredential credential,
    required String phoneNumber,
    String? firstName = 'Anonymous',
    String? lastName = 'User',
    File? image,
  });

  /// Signs up a new user using [emailAddress], [password], [image] as user's image, [firstName] and [lastName]
  /// Returns [ListingsUser] if user if logged in, or [String] error message if failed
  Future<dynamic> signUpWithEmailAndPassword(
      {required String emailAddress,
      required String password,
      File? image,
      firstName = 'Anonymous',
      lastName = 'User'});

  /// Logs the [user] of the system
  logout(ListingsUser user);

  /// submit the received code to firebase to complete the phone number
  /// verification process
  Future<dynamic> submitPhoneNumberCode(String verificationID, String code);

  /// Verifies [phoneNumber] input from user with back end
  /// [phoneCodeAutoRetrievalTimeout] is a callback function triggered when timeout for android devices if they can't auto retrieve the SMS code
  /// [phoneCodeSent] is a callback function triggered when the SMS code is sent from the backend
  /// [phoneVerificationFailed] is a callback function triggered when SMS code verification fails
  /// [phoneVerificationCompleted] is a callback function triggered when SMS code verification is complete
  verifyPhoneNumber({
    required String phoneNumber,
    required auth.PhoneCodeAutoRetrievalTimeout phoneCodeAutoRetrievalTimeout,
    required auth.PhoneCodeSent phoneCodeSent,
    required auth.PhoneVerificationFailed phoneVerificationFailed,
    required auth.PhoneVerificationCompleted phoneVerificationCompleted,
  });

  /// Re-Authenticates the user before doing sensitive steps like deleting user from the database or updating password or email
  /// [provider] the auth provider type
  /// other parameters are optional, and depends on the provider
  /// [isDelete] true if we are deleting the user, if false we are just editing sensitive data
  /// [currentEmail] only required when is [provider] == [AuthProviders.password]
  /// [newEmail] only required when is [provider] == [AuthProviders.password]
  /// [password] only required when is [provider] == [AuthProviders.password]
  /// [smsCode] only required when is [provider] == [AuthProviders.phone]
  /// [verificationId] only required when is [provider] == [AuthProviders.phone]
  /// [accessToken] only required is when [provider] == [AuthProviders.facebook]
  /// [appleCredential] only required is when [provider] == [AuthProviders.apple]
  /// Returns false if delete/update is successful
  Future<bool> updateOrDeleteAuthUser(AuthProviders provider,
      {required bool isDelete,
      String? currentEmail,
      String? newEmail,
      String? password,
      String? smsCode,
      String? verificationId,
      AccessToken? accessToken,
      apple.AuthorizationResult? appleCredential});

  ///update phone number used for phone auth using [credential]
  updatePhoneNumber(auth.PhoneAuthCredential credential);

  ///Returns authentication credential used for sensitive operation such as deleting user or updating login email or password or phone number
  auth.AuthCredential getUserAuthCredential(AuthProviders provider,
      {String? email,
      String? password,
      String? smsCode,
      String? verificationId,
      AccessToken? accessToken,
      apple.AuthorizationResult? appleCredential});

  /// Resets user password using this [emailAddress]
  resetPassword(String emailAddress);
}
