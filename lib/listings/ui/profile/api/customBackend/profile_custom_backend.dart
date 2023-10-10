import 'dart:io';

import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_repository.dart';

class ProfileCustomBackendUtils extends ProfileRepository {
  @override
  updateCurrentUser(ListingsUser currentUser) {
    // TODO: implement updateCurrentUser
    throw UnimplementedError();
  }

  @override
  Future<String> uploadUserImageToServer(
      {required File image, required String userID}) {
    // TODO: implement uploadUserImageToServer
    throw UnimplementedError();
  }

  @override
  deleteImageFromStorage(String imageURL) {
    // TODO: implement deleteImageFromStorage
    throw UnimplementedError();
  }

  @override
  deleteUser({required ListingsUser user}) {
    // TODO: implement deleteUser
    throw UnimplementedError();
  }
}
