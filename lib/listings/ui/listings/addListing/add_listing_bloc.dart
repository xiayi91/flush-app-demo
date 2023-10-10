import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:instaflutter/constants.dart';
import 'package:instaflutter/listings/model/categories_model.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_repository.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:image_picker/image_picker.dart';

part 'add_listing_event.dart';
part 'add_listing_state.dart';

class AddListingBloc extends Bloc<AddListingEvent, AddListingState> {
  final ListingsUser currentUser;
  final ListingsRepository listingsRepository;
  final ImagePicker _imagePicker = ImagePicker();
  final List<File> listingImages = [];

  AddListingBloc({required this.currentUser, required this.listingsRepository})
      : super(AddListingInitial()) {
    on<GetCategoriesEvent>((event, emit) async {
      List<CategoriesModel> categories =
          await listingsRepository.getCategories();
      emit(CategoriesFetchedState(categories: categories));
    });
    on<ValidateListingInputEvent>((event, emit) {
      if (event.title.isEmpty) {
        emit(AddListingErrorState(
          errorTitle: 'Missing Title',
          errorMessage: 'You need a title for the listing.',
        ));
      } else if (event.description.isEmpty) {
        emit(AddListingErrorState(
          errorTitle: 'Missing Description',
          errorMessage: 'You need a short description for the listing.',
        ));
      } else if (event.price.isEmpty) {
        emit(AddListingErrorState(
          errorTitle: 'Missing Price',
          errorMessage: 'You need to set a price for the listing.',
        ));
      } else if (event.category == null) {
        emit(AddListingErrorState(
          errorTitle: 'Missing Category',
          errorMessage: 'You need to choose a category for the listing.',
        ));
      } else if (event.filters?.isEmpty ?? true) {
        emit(AddListingErrorState(
          errorTitle: 'Missing Filters',
          errorMessage: 'You need to set filters for the listing.',
        ));
      } else if (event.placeDetails == null) {
        emit(AddListingErrorState(
          errorTitle: 'Missing Location',
          errorMessage: 'You need a valid location for the listing.',
        ));
      } else if (listingImages.isEmpty) {
        emit(AddListingErrorState(
          errorTitle: 'Missing Photos',
          errorMessage: 'You need at least one photo for the listing.',
        ));
      } else {
        add(PublishListingEvent(
            listingModel: ListingModel(
          title: event.title,
          createdAt: Timestamp.now().seconds,
          authorID: currentUser.userID,
          authorName: currentUser.fullName(),
          authorProfilePic: currentUser.profilePictureURL,
          categoryID: event.category!.id,
          categoryPhoto: event.category!.photo,
          categoryTitle: event.category!.title,
          description: event.description,
          price: '${event.price}\$',
          latitude: event.placeDetails!.geometry!.location.lat,
          longitude: event.placeDetails!.geometry!.location.lng,
          filters: event.filters ?? {},
          place: event.placeDetails!.formattedAddress ?? '',
          reviewsCount: 0,
          reviewsSum: 0,
          isApproved: false,
        )));
      }
    });
    on<PublishListingEvent>((event, emit) async {
      updateProgress('Uploading Images...'.tr());
      List<String> imagesUrls =
          await listingsRepository.uploadListingImages(images: listingImages);
      event.listingModel.photo = imagesUrls.first;
      event.listingModel.photos = imagesUrls;
      updateProgress('Posting listing, almost done...'.tr());
      await listingsRepository.postListing(newListing: event.listingModel);
      emit(ListingPublishedState());
    });

    on<CategorySelectedEvent>((event, emit) =>
        emit(CategorySelectedState(category: event.categoriesModel!)));
    on<SetFiltersEvent>(
        (event, emit) => emit(SetFiltersState(filters: event.filters)));
    on<GetPlaceDetailsEvent>((event, emit) async {
      var result = await GoogleMapsPlaces(apiKey: googleApiKey)
          .getDetailsByPlaceId(event.prediction.placeId ?? '');
      emit(PlaceDetailsState(placeDetails: result.result));
    });

    on<AddImageToListingEvent>((event, emit) async {
      ImageSource source =
          event.fromGallery ? ImageSource.gallery : ImageSource.camera;
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        listingImages.add(File(image.path));
        emit(ListingImagesUpdatedState(images: listingImages));
      }
    });

    on<RemoveListingImageEvent>((event, emit) {
      listingImages.remove(event.image);
      emit(ListingImagesUpdatedState(images: listingImages));
    });
  }
}
