part of 'my_listings_bloc.dart';

abstract class MyListingsState {}

class MyListingsInitial extends MyListingsState {}

class MyListingsReadyState extends MyListingsState {
  List<ListingModel> myListings;

  MyListingsReadyState({required this.myListings});
}

class ListingFavToggleState extends MyListingsState {
  ListingModel listing;
  ListingsUser updatedUser;

  ListingFavToggleState({required this.listing, required this.updatedUser});
}

class LoadingState extends MyListingsState {}
