import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:instaflutter/constants.dart';
import 'package:instaflutter/core/model/user.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/auth/api/authentication_repository.dart';
import 'package:instaflutter/listings/ui/auth/reauthUser/reauth_user_bloc.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart' as apple;

class AuthFirebaseUtils extends AuthenticationRepository {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseFunctions functions = FirebaseFunctions.instance;
  Reference storage = FirebaseStorage.instance.ref();

  @override
  Future<ListingsUser?> getAuthUser() async {
    auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      ListingsUser? user = await _getCurrentUser(firebaseUser.uid);
      if (user != null) {
        user.active = true;
        user.pushToken = await firebaseMessaging.getToken() ?? '';
        await _updateCurrentUser(user);
        return user;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  @override
  Future<dynamic> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      auth.UserCredential result = await auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await firestore
          .collection(usersCollection)
          .doc(result.user?.uid ?? '')
          .get();
      ListingsUser? user;
      if (documentSnapshot.exists) {
        user = ListingsUser.fromJson(documentSnapshot.data() ?? {});
        user.active = true;
        user.pushToken = await firebaseMessaging.getToken() ?? '';
        await _updateCurrentUser(user);
      }
      return user;
    } on auth.FirebaseAuthException catch (e, s) {
      debugPrint('apiManager.loginWithEmailAndPassword $e $s');
      switch (e.code) {
        case 'invalid-email':
          return 'Email address is malformed.';
        case 'wrong-password':
          return 'Wrong password.';
        case 'user-not-found':
          return 'No user corresponding to the given email address.';
        case 'user-disabled':
          return 'This user has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts to sign in as this user.';
      }
      return 'Unexpected firebase error, Please try again.';
    } catch (e, s) {
      debugPrint('apiManager.loginWithEmailAndPassword $e $s');
      return 'Login failed, Please try again.';
    }
  }

  @override
  loginWithFacebook() async {
    FacebookAuth facebookAuth = FacebookAuth.instance;
    bool isLogged = await facebookAuth.accessToken != null;
    if (!isLogged) {
      LoginResult result = await facebookAuth.login();
      if (result.status == LoginStatus.success) {
        AccessToken? token = await facebookAuth.accessToken;
        return await _handleFacebookLogin(
            await facebookAuth.getUserData(), token!);
      }
    } else {
      AccessToken? token = await facebookAuth.accessToken;
      return await _handleFacebookLogin(
          await facebookAuth.getUserData(), token!);
    }
  }

  @override
  loginWithApple() async {
    final appleCredential = await apple.TheAppleSignIn.performRequests([
      const apple.AppleIdRequest(
          requestedScopes: [apple.Scope.email, apple.Scope.fullName])
    ]);
    if (appleCredential.error != null) {
      return 'Couldn\'t login with apple.';
    }

    if (appleCredential.status == apple.AuthorizationStatus.authorized) {
      final auth.AuthCredential credential =
          auth.OAuthProvider('apple.com').credential(
        accessToken: String.fromCharCodes(
            appleCredential.credential?.authorizationCode ?? []),
        idToken: String.fromCharCodes(
            appleCredential.credential?.identityToken ?? []),
      );
      return await _handleAppleLogin(credential, appleCredential.credential!);
    } else {
      return 'Couldn\'t login with apple.';
    }
  }

  @override
  verifyPhoneNumber({
    required String phoneNumber,
    required auth.PhoneCodeAutoRetrievalTimeout phoneCodeAutoRetrievalTimeout,
    required auth.PhoneCodeSent phoneCodeSent,
    required auth.PhoneVerificationFailed phoneVerificationFailed,
    required auth.PhoneVerificationCompleted phoneVerificationCompleted,
  }) async {
    await auth.FirebaseAuth.instance.verifyPhoneNumber(
      timeout: const Duration(seconds: 30),
      phoneNumber: phoneNumber,
      verificationCompleted: phoneVerificationCompleted,
      verificationFailed: phoneVerificationFailed,
      codeSent: phoneCodeSent,
      codeAutoRetrievalTimeout: phoneCodeAutoRetrievalTimeout,
    );
  }

  @override
  Future<dynamic> submitPhoneNumberCode(
      String verificationID, String code) async {
    try {
      return auth.PhoneAuthProvider.credential(
          verificationId: verificationID, smsCode: code);
    } on auth.FirebaseAuthException catch (exception) {
      hideProgress();
      String message = 'Phone authentication failed.';
      switch (exception.code) {
        case 'invalid-verification-code':
          message = 'Invalid code or has been expired.';
          break;
        case 'user-disabled':
          message = 'This user has been disabled.';
          break;
        default:
          message = 'Phone authentication failed.';
          break;
      }
      return message.tr();
    } catch (e, s) {
      debugPrint('$e $s');
      return 'Phone authentication failed.'.tr();
    }
  }

  @override
  Future<dynamic> loginOrCreateUserWithPhoneNumberCredential({
    required auth.PhoneAuthCredential credential,
    required String phoneNumber,
    String? firstName = 'Anonymous',
    String? lastName = 'User',
    File? image,
  }) async {
    auth.UserCredential userCredential =
        await auth.FirebaseAuth.instance.signInWithCredential(credential);
    ListingsUser? user = await _getCurrentUser(userCredential.user?.uid ?? '');
    if (user != null) {
      user.active = true;
      user.pushToken = await firebaseMessaging.getToken() ?? '';
      await _updateCurrentUser(user);
      return user;
    } else {
      String profileImageUrl = '';
      if (image != null) {
        profileImageUrl = await _uploadUserImageToServer(
            image, userCredential.user?.uid ?? '');
      }
      ListingsUser user = ListingsUser(
          firstName: (firstName?.trim().isNotEmpty ?? false)
              ? firstName!.trim()
              : 'Anonymous',
          lastName: (lastName?.trim().isNotEmpty ?? false)
              ? lastName!.trim()
              : 'User',
          pushToken: await FirebaseMessaging.instance.getToken() ?? '',
          phoneNumber: phoneNumber,
          active: true,
          lastOnlineTimestamp: Timestamp.now(),
          settings: UserSettings(),
          email: '',
          profilePictureURL: profileImageUrl,
          userID: userCredential.user?.uid ?? '');
      String? errorMessage = await _createNewUser(user);
      if (errorMessage == null) {
        return user;
      } else {
        return 'Couldn\'t create new user with phone number.'.tr();
      }
    }
  }

  @override
  signUpWithEmailAndPassword(
      {required String emailAddress,
      required String password,
      File? image,
      firstName = 'Anonymous',
      lastName = 'User'}) async {
    try {
      auth.UserCredential result = await auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailAddress, password: password);
      String profilePicUrl = '';
      if (image != null) {
        updateProgress('Uploading image, Please wait...'.tr());
        profilePicUrl =
            await _uploadUserImageToServer(image, result.user?.uid ?? '');
      }
      ListingsUser user = ListingsUser(
          active: true,
          lastOnlineTimestamp: Timestamp.now(),
          settings: UserSettings(),
          email: emailAddress,
          firstName: firstName,
          userID: result.user?.uid ?? '',
          lastName: lastName,
          pushToken: await firebaseMessaging.getToken() ?? '',
          profilePictureURL: profilePicUrl);
      String? errorMessage = await _createNewUser(user);
      if (errorMessage == null) {
        return user;
      } else {
        return 'Couldn\'t sign up for firebase, Please try again.'.tr();
      }
    } on auth.FirebaseAuthException catch (error) {
      debugPrint('$error${error.stackTrace}');
      String message = 'Couldn\'t sign up'.tr();
      switch (error.code) {
        case 'email-already-in-use':
          message = 'Email already in use, Please pick another email!'.tr();
          break;
        case 'invalid-email':
          message = 'Enter valid e-mail'.tr();
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled'.tr();
          break;
        case 'weak-password':
          message = 'Password must be more than 5 characters'.tr();
          break;
        case 'too-many-requests':
          message = 'Too many requests, Please try again later.'.tr();
          break;
      }
      return message;
    } catch (e) {
      return 'Couldn\'t sign up'.tr();
    }
  }

  @override
  auth.AuthCredential getUserAuthCredential(AuthProviders provider,
      {String? email,
      String? password,
      String? smsCode,
      String? verificationId,
      AccessToken? accessToken,
      apple.AuthorizationResult? appleCredential}) {
    late auth.AuthCredential credential;
    switch (provider) {
      case AuthProviders.password:
        credential = auth.EmailAuthProvider.credential(
            email: email!, password: password!);
        break;
      case AuthProviders.phone:
        credential = auth.PhoneAuthProvider.credential(
            smsCode: smsCode!, verificationId: verificationId!);
        break;
      case AuthProviders.facebook:
        credential = auth.FacebookAuthProvider.credential(accessToken!.token);
        break;
      case AuthProviders.apple:
        credential = auth.OAuthProvider('apple.com').credential(
          accessToken: String.fromCharCodes(
              appleCredential!.credential?.authorizationCode ?? []),
          idToken: String.fromCharCodes(
              appleCredential.credential?.identityToken ?? []),
        );
        break;
    }
    return credential;
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
      apple.AuthorizationResult? appleCredential}) async {
    auth.AuthCredential credential = getUserAuthCredential(provider,
        email: currentEmail,
        password: password,
        smsCode: smsCode,
        verificationId: verificationId,
        accessToken: accessToken,
        appleCredential: appleCredential);

    auth.UserCredential? userCredential = await auth
        .FirebaseAuth.instance.currentUser!
        .reauthenticateWithCredential(credential);

    if (isDelete) {
      await _deleteUser();
      return true;
    } else {
      if (provider == AuthProviders.password) {
        await _updateEmail(newEmail!);
      }
      ListingsUser? user =
          await _getCurrentUser(userCredential.user?.uid ?? '');
      return user != null;
    }
  }

  @override
  resetPassword(String emailAddress) async => await auth.FirebaseAuth.instance
      .sendPasswordResetEmail(email: emailAddress);

  @override
  updatePhoneNumber(auth.PhoneAuthCredential credential) async =>
      await auth.FirebaseAuth.instance.currentUser!
          .updatePhoneNumber(credential);

  @override
  logout(ListingsUser user) async {
    user.active = false;
    user.lastOnlineTimestamp = Timestamp.now().seconds;
    await _updateCurrentUser(user);
    await auth.FirebaseAuth.instance.signOut();
  }

  /// Gets the user object by his userID [uid] field.
  /// Returns user object if found, and null if not found.
  Future<ListingsUser?> _getCurrentUser(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDocument =
        await firestore.collection(usersCollection).doc(uid).get();
    if (userDocument.exists) {
      return ListingsUser.fromJson(userDocument.data() ?? {});
    } else {
      return null;
    }
  }

  /// Updates the [user] object in the database.
  /// Returns the updated [user] object if updated successfully otherwise returns null.
  Future<ListingsUser?> _updateCurrentUser(ListingsUser user) async {
    return await firestore
        .collection(usersCollection)
        .doc(user.userID)
        .set(user.toJson(), SetOptions(merge: true))
        .then((document) {
      return user;
    }, onError: (e) {
      return null;
    });
  }

  /// this method is used to upload the user image to firestore
  /// @param image file to be uploaded to firestore
  /// @param userID the userID used as part of the image name on firestore
  /// @return the full download url used to view the image
  Future<String> _uploadUserImageToServer(File image, String userID) async {
    File compressedImage = await _compressImage(image);
    Reference upload = storage.child('images/$userID.png');
    UploadTask uploadTask = upload.putFile(compressedImage);
    var downloadUrl =
        await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  /// compress image file to make it load faster but with lower quality,
  /// change the quality parameter to control the quality of the image after
  /// being compressed(100 = max quality - 0 = low quality)
  /// @param file the image file that will be compressed
  /// @return File a new compressed file with smaller size
  Future<File> _compressImage(File file) async {
    File compressedImage = await FlutterNativeImage.compressImage(
      file.path,
      quality: 25,
    );
    return compressedImage;
  }

  _handleFacebookLogin(Map<String, dynamic> userData, AccessToken token) async {
    auth.UserCredential authResult = await auth.FirebaseAuth.instance
        .signInWithCredential(
            auth.FacebookAuthProvider.credential(token.token));
    ListingsUser? user = await _getCurrentUser(authResult.user?.uid ?? '');
    List<String> fullName = (userData['name'] as String).split(' ');
    String firstName = '';
    String lastName = '';
    if (fullName.isNotEmpty) {
      firstName = fullName.first;
      lastName = fullName.skip(1).join(' ');
    }
    if (user != null) {
      user.profilePictureURL = userData['picture']['data']['url'];
      user.firstName = firstName;
      user.lastName = lastName;
      user.email = userData['email'];
      user.active = true;
      user.pushToken = await firebaseMessaging.getToken() ?? '';
      dynamic result = await _updateCurrentUser(user);
      return result;
    } else {
      user = ListingsUser(
          email: userData['email'] ?? '',
          firstName: firstName,
          profilePictureURL: userData['picture']['data']['url'] ?? '',
          userID: authResult.user?.uid ?? '',
          lastOnlineTimestamp: Timestamp.now(),
          lastName: lastName,
          active: true,
          pushToken: await firebaseMessaging.getToken() ?? '',
          phoneNumber: '',
          settings: UserSettings());
      String? errorMessage = await _createNewUser(user);
      if (errorMessage == null) {
        return user;
      } else {
        return errorMessage;
      }
    }
  }

  _handleAppleLogin(
    auth.AuthCredential credential,
    apple.AppleIdCredential appleIdCredential,
  ) async {
    auth.UserCredential authResult =
        await auth.FirebaseAuth.instance.signInWithCredential(credential);
    ListingsUser? user = await _getCurrentUser(authResult.user?.uid ?? '');
    if (user != null) {
      user.active = true;
      user.pushToken = await firebaseMessaging.getToken() ?? '';
      dynamic result = await _updateCurrentUser(user);
      return result;
    } else {
      user = ListingsUser(
          email: appleIdCredential.email ?? '',
          firstName: appleIdCredential.fullName?.givenName ?? '',
          profilePictureURL: '',
          userID: authResult.user?.uid ?? '',
          lastOnlineTimestamp: Timestamp.now(),
          lastName: appleIdCredential.fullName?.familyName ?? '',
          active: true,
          pushToken: await firebaseMessaging.getToken() ?? '',
          phoneNumber: '',
          settings: UserSettings());
      String? errorMessage = await _createNewUser(user);
      if (errorMessage == null) {
        return user;
      } else {
        return errorMessage;
      }
    }
  }

  /// save a new user document in the USERS table in firebase firestore
  /// returns an error message on failure or null on success
  Future<String?> _createNewUser(ListingsUser user) async {
    try {
      await firestore
          .collection(usersCollection)
          .doc(user.userID)
          .set(user.toJson());
      return null;
    } catch (e, s) {
      debugPrint('apiManager.createNewUser $e $s');
      return 'Couldn\'t sign up'.tr();
    }
  }

  _updateEmail(String newEmail) async =>
      await auth.FirebaseAuth.instance.currentUser?.updateEmail(newEmail);

  _deleteUser() async {
    try {
      await firestore
          .collection(usersCollection)
          .doc(auth.FirebaseAuth.instance.currentUser!.uid)
          .delete();
      await auth.FirebaseAuth.instance.currentUser!.delete();
    } catch (e, s) {
      debugPrint('apiManager.deleteUser $e $s');
    }
  }
}
