part of 'listing_details_bloc.dart';

abstract class ListingDetailsState {}

class ListingDetailsInitial extends ListingDetailsState {}

class ReviewsFetchedState extends ListingDetailsState {
  List<ListingReviewModel> reviews;

  ReviewsFetchedState({required this.reviews});
}

class ListingFavToggleState extends ListingDetailsState {
  ListingModel listing;
  ListingsUser updatedUser;

  ListingFavToggleState({required this.listing, required this.updatedUser});
}

class LoadingState extends ListingDetailsState {}

class DeletedListingState extends ListingDetailsState {}
