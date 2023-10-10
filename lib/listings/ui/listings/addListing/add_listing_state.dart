part of 'add_listing_bloc.dart';

abstract class AddListingState {}

class AddListingInitial extends AddListingState {}

class CategorySelectedState extends AddListingState {
  CategoriesModel category;

  CategorySelectedState({required this.category});
}

class CategoriesFetchedState extends AddListingState {
  List<CategoriesModel> categories;

  CategoriesFetchedState({required this.categories});
}

class SetFiltersState extends AddListingState {
  Map<String, String>? filters;

  SetFiltersState({required this.filters});
}

class PlaceDetailsState extends AddListingState {
  PlaceDetails placeDetails;

  PlaceDetailsState({required this.placeDetails});
}

class ListingImagesUpdatedState extends AddListingState {
  List<File> images;

  ListingImagesUpdatedState({required this.images});
}

class AddListingValidState extends AddListingState {}

class AddListingErrorState extends AddListingState {
  String errorTitle;
  String errorMessage;

  AddListingErrorState({
    required this.errorTitle,
    required this.errorMessage,
  });
}

class ListingPublishedState extends AddListingState {}
