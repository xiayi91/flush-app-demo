part of 'my_listings_bloc.dart';

abstract class MyListingsEvent {}

class GetMyListingsEvent extends MyListingsEvent {}

class ListingFavUpdated extends MyListingsEvent {
  ListingModel listing;

  ListingFavUpdated({required this.listing});
}

class ListingDeletedByUserEvent extends MyListingsEvent {
  ListingModel listing;

  ListingDeletedByUserEvent({required this.listing});
}

class LoadingEvent extends MyListingsEvent {}
