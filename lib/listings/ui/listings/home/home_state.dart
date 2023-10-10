part of 'home_bloc.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class LoadingCategoriesState extends HomeState {}

class LoadingListingsState extends HomeState {}

class ToggleShowAllState extends HomeState {}

class CategoriesListState extends HomeState {
  List<CategoriesModel> categories;

  CategoriesListState({required this.categories});
}

class ListingsListState extends HomeState {
  List<ListingModel?> listingsWithAds;

  ListingsListState({required this.listingsWithAds});
}

class ListingFavToggleState extends HomeState {
  ListingModel listing;
  ListingsUser updatedUser;

  ListingFavToggleState({required this.listing, required this.updatedUser});
}

class LoadingState extends HomeState {}
