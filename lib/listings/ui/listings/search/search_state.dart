part of 'search_bloc.dart';

abstract class SearchState {}

class SearchInitial extends SearchState {}

class ListingsReadyState extends SearchState {
  List<ListingModel> listings;

  ListingsReadyState({required this.listings});
}

class ListingsFilteredState extends SearchState {
  List<ListingModel> filteredListings;

  ListingsFilteredState({required this.filteredListings});
}

class LoadingState extends SearchState {}
