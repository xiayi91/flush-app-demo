part of 'category_listings_bloc.dart';

abstract class CategoryListingsState {}

class CategoryListingsInitial extends CategoryListingsState {}

class ListingsReadyState extends CategoryListingsState {
  List<ListingModel> listings;

  ListingsReadyState({required this.listings});
}

class LoadingState extends CategoryListingsState {}
