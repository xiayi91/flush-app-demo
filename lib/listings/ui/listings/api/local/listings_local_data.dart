import 'dart:io';

import 'package:instaflutter/listings/model/categories_model.dart';
import 'package:instaflutter/listings/model/filter_model.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listing_review_model.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_repository.dart';

class ListingsLocalData extends ListingsRepository {
  @override
  Future<void> approveListing({required ListingModel listingModel}) {
    // TODO: implement approveListing
    throw UnimplementedError();
  }

  @override
  Future<void> deleteListing({required ListingModel listingModel}) {
    // TODO: implement deleteListing
    throw UnimplementedError();
  }

  @override
  Future<List<CategoriesModel>> getCategories() {
    // TODO: implement getCategories
    throw UnimplementedError();
  }

  @override
  Future<List<ListingModel>> getFavoriteListings(
      {required List<String> favListingsIDs}) {
    // TODO: implement getFavoriteListings
    throw UnimplementedError();
  }

  @override
  Future<List<FilterModel>> getFilters() {
    // TODO: implement getFilters
    throw UnimplementedError();
  }

  @override
  Future<ListingModel> getListing({required String listingID}) {
    // TODO: implement getListing
    throw UnimplementedError();
  }

  @override
  Future<List<ListingReviewModel>> getReviews({required String listingID}) {
    // TODO: implement getReviews
    throw UnimplementedError();
  }

  @override
  Future<void> postListing({required ListingModel newListing}) {
    // TODO: implement postListing
    throw UnimplementedError();
  }

  @override
  Future<void> postReview({required ListingReviewModel reviewModel}) {
    // TODO: implement postReview
    throw UnimplementedError();
  }

  @override
  Future<List<String>> uploadListingImages({required List<File> images}) {
    // TODO: implement uploadListingImages
    throw UnimplementedError();
  }

  @override
  Future<List<ListingModel>> getListings(
      {required List<String> favListingsIDs}) {
    // TODO: implement getListings
    throw UnimplementedError();
  }

  @override
  Future<List<ListingModel>> getListingsByCategoryID(
      {required String categoryID, required List<String> favListingsIDs}) {
    // TODO: implement getListingsByCategoryID
    throw UnimplementedError();
  }

  @override
  Future<List<ListingModel>> getMyListings(
      {required String currentUserID, required List<String> favListingsIDs}) {
    // TODO: implement getMyListings
    throw UnimplementedError();
  }

  @override
  Future<List<ListingModel>> getPendingListings(
      {required List<String> favListingsIDs}) {
    // TODO: implement getPendingListings
    throw UnimplementedError();
  }
}
