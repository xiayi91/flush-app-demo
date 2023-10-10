part of 'favorite_listings_bloc.dart';

abstract class FavoriteListingsState {}

class FavoriteListingsInitial extends FavoriteListingsState {}

class FavoriteListingsReadyState extends FavoriteListingsState {
  List<ListingModel> favorites;

  FavoriteListingsReadyState({required this.favorites});
}

class ListingFavToggleState extends FavoriteListingsState {
  ListingModel listing;
  ListingsUser updatedUser;

  ListingFavToggleState({required this.listing, required this.updatedUser});
}

class LoadingState extends FavoriteListingsState {}
