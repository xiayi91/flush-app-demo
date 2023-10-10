part of 'listing_details_bloc.dart';

abstract class ListingDetailsEvent {}

class GetListingReviewsEvent extends ListingDetailsEvent {}

class ListingFavUpdatedEvent extends ListingDetailsEvent {}

class DeleteListingEvent extends ListingDetailsEvent {}

class LoadingEvent extends ListingDetailsEvent {}
