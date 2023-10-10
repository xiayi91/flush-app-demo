import 'dart:io';

import 'package:instaflutter/listings/model/listings_user.dart';

abstract class ProfileRepository {
  /// Updates the [currentUser] object in the database.
  updateCurrentUser(ListingsUser currentUser);

  /// this method is used to upload the user image to firestore
  /// @param image file to be uploaded to firestore
  /// @param userID the userID used as part of the image name on firestore
  /// @return the full download url used to view the image
  Future<String> uploadUserImageToServer(
      {required File image, required String userID});

  /// delete an image from remote storage using the [imageURL]
  deleteImageFromStorage(String imageURL);

  deleteUser({required ListingsUser user});
}
