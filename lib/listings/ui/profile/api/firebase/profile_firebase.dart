import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:instaflutter/constants.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/auth/reauthUser/reauth_user_bloc.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_repository.dart';
import 'package:path/path.dart' as path;

class ProfileFirebaseUtils extends ProfileRepository {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Reference storage = FirebaseStorage.instance.ref();

  @override
  updateCurrentUser(ListingsUser currentUser) async => await firestore
      .collection(usersCollection)
      .doc(currentUser.userID)
      .set(currentUser.toJson(), SetOptions(merge: true));

  @override
  Future<String> uploadUserImageToServer(
      {required File image, required String userID}) async {
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

  @override
  deleteImageFromStorage(String imageURL) async {
    var fileUrl = Uri.decodeFull(path.basename(imageURL))
        .replaceAll(RegExp(r'(\?alt).*'), '');

    final Reference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(fileUrl);
    await firebaseStorageRef.delete();
  }

  Future<AuthProviders?> getUserAuthProvider() async {
    AuthProviders? authProvider;

    List<auth.UserInfo> userInfoList =
        auth.FirebaseAuth.instance.currentUser?.providerData ?? [];
    await Future.forEach(userInfoList, (auth.UserInfo info) {
      if (info.providerId == 'password') {
        authProvider = AuthProviders.password;
      } else if (info.providerId == 'phone') {
        authProvider = AuthProviders.phone;
      }
    });
    return authProvider;
  }

  @override
  deleteUser({required ListingsUser user}) {
    throw UnimplementedError();
  }
}
