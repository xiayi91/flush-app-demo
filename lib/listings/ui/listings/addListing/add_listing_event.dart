part of 'add_listing_bloc.dart';

abstract class AddListingEvent {}

class GetCategoriesEvent extends AddListingEvent {}

class PublishListingEvent extends AddListingEvent {
  ListingModel listingModel;

  PublishListingEvent({
    required this.listingModel,
  });
}

class CategorySelectedEvent extends AddListingEvent {
  CategoriesModel? categoriesModel;

  CategorySelectedEvent({required this.categoriesModel});
}

class SetFiltersEvent extends AddListingEvent {
  Map<String, String>? filters;

  SetFiltersEvent({required this.filters});
}

class GetPlaceDetailsEvent extends AddListingEvent {
  Prediction prediction;

  GetPlaceDetailsEvent({required this.prediction});
}

class AddImageToListingEvent extends AddListingEvent {
  bool fromGallery;

  AddImageToListingEvent({required this.fromGallery});
}

class RemoveListingImageEvent extends AddListingEvent {
  File image;

  RemoveListingImageEvent({required this.image});
}

class ValidateListingInputEvent extends AddListingEvent {
  String title;
  String description;
  String price;
  CategoriesModel? category;
  Map<String, String>? filters;
  PlaceDetails? placeDetails;

  ValidateListingInputEvent({
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.filters,
    required this.placeDetails,
  });
}
