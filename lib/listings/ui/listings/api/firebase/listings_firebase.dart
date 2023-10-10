import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/categories_model.dart';
import 'package:instaflutter/listings/model/filter_model.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listing_review_model.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_repository.dart';
import 'package:path/path.dart' as path;

class ListingsFirebaseUtils extends ListingsRepository {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Reference storage = FirebaseStorage.instance.ref();

  @override
  Future<void> approveListing({required ListingModel listingModel}) async {
    listingModel.isApproved = true;
    await firestore
        .collection(listingsCollection)
        .doc(listingModel.id)
        .update(listingModel.toJson());
  }

  @override
  Future<void> deleteListing({required ListingModel listingModel}) async {
    await firestore
        .collection(listingsCollection)
        .doc(listingModel.id)
        .delete();
    for (var imageUrl in listingModel.photos) {
      await deleteImageFromStorage(imageUrl);
    }
  }

  @override
  Future<List<CategoriesModel>> getCategories() async {
    var result =
        await firestore.collection(categoriesCollection).orderBy('order').get();
    List<CategoriesModel> listOfCategories = [];
    for (var doc in result.docs) {
      try {
        listOfCategories.add(CategoriesModel.fromJson(doc.data()));
      } catch (e, s) {
        debugPrint('FireStoreUtils.getCategories failed to parse object '
            '${doc.id} $e $s');
      }
    }
    return listOfCategories;
  }

  @override
  Future<List<ListingModel>> getFavoriteListings(
      {required List<String> favListingsIDs}) async {
    List<ListingModel> listings = [];
    for (String listingID in favListingsIDs) {
      ListingModel? listingModel = await getListing(listingID: listingID);
      if (listingModel != null) {
        listingModel.isFav = true;
        listings.add(listingModel);
      }
    }
    return listings;
  }

  @override
  Future<List<FilterModel>> getFilters() async {
    var result = await firestore.collection(filtersCollection).get();
    List<FilterModel> filters = [];
    for (var doc in result.docs) {
      try {
        filters.add(FilterModel.fromJson(doc.data()));
      } catch (e, s) {
        debugPrint('FireStoreUtils.getFilters failed to parse object '
            '${doc.id} $e $s');
      }
    }
    return filters;
  }

  @override
  Future<ListingModel?> getListing({required String listingID}) async {
    var result =
        await firestore.collection(listingsCollection).doc(listingID).get();
    ListingModel? listingModel;
    if (result.data() != null && result.exists) {
      listingModel = ListingModel.fromJson(result.data()!);
    }
    return listingModel;
  }

  @override
  Future<List<ListingModel>> getListings(
      {required List<String> favListingsIDs}) async {
    var result = await firestore.collection(listingsCollection).get();
    List<ListingModel> listings = [];
    for (var doc in result.docs) {
      try {
        listings.add(ListingModel.fromJson(doc.data())
          ..isFav = favListingsIDs.contains(doc.id));
      } catch (e, s) {
        debugPrint('FireStoreUtils.getListings failed to parse listing object '
            '${doc.id} $e $s');
      }
    }
    return listings;
  }

  @override
  Future<List<ListingModel>> getListingsByCategoryID({
    required String categoryID,
    required List<String> favListingsIDs,
  }) async {
    var result = await firestore
        .collection(listingsCollection)
        .where('categoryID', isEqualTo: categoryID)
        .get();
    List<ListingModel> listings = [];
    for (var doc in result.docs) {
      try {
        listings.add(ListingModel.fromJson(doc.data())
          ..isFav = favListingsIDs.contains(doc.id));
      } catch (e, s) {
        debugPrint(
            'FireStoreUtils.getListingsByCategoryID failed to parse listing object '
            '${doc.id} $e $s');
      }
    }
    return listings;
  }

  @override
  Future<List<ListingModel>> getMyListings({
    required String currentUserID,
    required List<String> favListingsIDs,
  }) async {
    var result = await firestore
        .collection(listingsCollection)
        .where('authorID', isEqualTo: currentUserID)
        .get();
    List<ListingModel> listings = [];
    for (var doc in result.docs) {
      try {
        listings.add(ListingModel.fromJson(doc.data())
          ..isFav = favListingsIDs.contains(doc.id));
      } catch (e) {
        debugPrint('FireStoreUtils.getMyListings failed to parse object '
            '${doc.id} $e');
      }
    }
    return listings;
  }

  @override
  Future<List<ListingModel>> getPendingListings(
      {required List<String> favListingsIDs}) async {
    var result = await firestore
        .collection(listingsCollection)
        .where('isApproved', isEqualTo: false)
        .get();
    List<ListingModel> listings = [];
    for (var doc in result.docs) {
      try {
        listings.add(ListingModel.fromJson(doc.data())
          ..isFav = favListingsIDs.contains(doc.id));
      } catch (e, s) {
        debugPrint('FireStoreUtils.getPendingListings failed to parse object '
            '${doc.id} $e $s');
      }
    }
    return listings;
  }

  @override
  Future<List<ListingReviewModel>> getReviews(
      {required String listingID}) async {
    var result = await firestore
        .collection(reviewCollection)
        .where('listingID', isEqualTo: listingID)
        .get();
    List<ListingReviewModel> reviews = [];
    for (var doc in result.docs) {
      try {
        reviews.add(ListingReviewModel.fromJson(doc.data()));
      } catch (e, s) {
        debugPrint('FireStoreUtils.getReviews failed to parse object '
            '${doc.id} $e $s');
      }
    }
    return reviews;
  }

  @override
  Future<void> postListing({required ListingModel newListing}) async {
    DocumentReference docRef = firestore.collection(listingsCollection).doc();
    newListing.id = docRef.id;
    await docRef.set(newListing.toJson());
  }

  @override
  Future<void> postReview({required ListingReviewModel reviewModel}) async {
    ListingModel? updatedListing =
        await getListing(listingID: reviewModel.listingID);
    if (updatedListing != null) {
      await firestore
          .collection(reviewCollection)
          .doc()
          .set(reviewModel.toJson());
      updatedListing.reviewsCount += 1;
      updatedListing.reviewsSum += reviewModel.starCount;
      await firestore
          .collection(listingsCollection)
          .doc(updatedListing.id)
          .update(updatedListing.toJson());
    }
  }

  @override
  Future<List<String>> uploadListingImages({required List<File> images}) async {
    List<String> imagesUrls = [];
    for (var image in images) {
      Reference upload =
          storage.child('listings/images/${image.uri.pathSegments.last}.png');
      File compressedImage = await compressImage(image);
      UploadTask uploadTask = upload.putFile(compressedImage);
      var downloadUrl =
          await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
      imagesUrls.add(downloadUrl.toString());
    }
    return imagesUrls;
  }

  Future<File> compressImage(File file) async {
    File compressedImage = await FlutterNativeImage.compressImage(
      file.path,
      quality: 25,
    );
    return compressedImage;
  }

  deleteImageFromStorage(String imageURL) async {
    var fileUrl = Uri.decodeFull(path.basename(imageURL))
        .replaceAll(RegExp(r'(\?alt).*'), '');
    await storage.child(fileUrl).delete();
  }
}
