import 'dart:io';

import 'package:instaflutter/listings/model/categories_model.dart';
import 'package:instaflutter/listings/model/filter_model.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listing_review_model.dart';

abstract class ListingsRepository {
  Future<List<CategoriesModel>> getCategories();

  Future<List<ListingModel>> getListings(
      {required List<String> favListingsIDs});

  Future<List<ListingModel>> getMyListings({
    required String currentUserID,
    required List<String> favListingsIDs,
  });

  Future<ListingModel?> getListing({required String listingID});

  Future<List<ListingModel>> getFavoriteListings(
      {required List<String> favListingsIDs});

  Future<List<ListingModel>> getListingsByCategoryID(
      {required String categoryID, required List<String> favListingsIDs});

  Future<List<ListingModel>> getPendingListings(
      {required List<String> favListingsIDs});

  Future<List<FilterModel>> getFilters();

  Future<List<String>> uploadListingImages({required List<File> images});

  Future<void> postListing({required ListingModel newListing});

  Future<void> postReview({required ListingReviewModel reviewModel});

  Future<void> approveListing({required ListingModel listingModel});

  Future<void> deleteListing({required ListingModel listingModel});

  Future<List<ListingReviewModel>> getReviews({required String listingID});
}
