part of 'favorite_listings_bloc.dart';

abstract class FavoriteListingsEvent {}

class GetMyFavoriteListings extends FavoriteListingsEvent {}

class ListingFavUpdated extends FavoriteListingsEvent {
  ListingModel listing;

  ListingFavUpdated({required this.listing});
}

class ListingDeletedByUserEvent extends FavoriteListingsEvent {
  ListingModel listing;

  ListingDeletedByUserEvent({required this.listing});
}

class LoadingEvent extends FavoriteListingsEvent {}
