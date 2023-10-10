import 'package:bloc/bloc.dart';
import 'package:instaflutter/listings/model/categories_model.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_repository.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_repository.dart';

part 'home_event.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ListingsUser currentUser;
  final ListingsRepository listingsRepository;
  final ProfileRepository profileRepository;
  List<ListingModel> listings = [];
  List<ListingModel?> listingsWithAds = [];

  HomeBloc({
    required this.currentUser,
    required this.listingsRepository,
    required this.profileRepository,
  }) : super(HomeInitial()) {
    on<GetCategoriesEvent>((event, emit) async {
      emit(LoadingCategoriesState());
      List<CategoriesModel> categories =
          await listingsRepository.getCategories();
      emit(CategoriesListState(categories: categories));
    });

    on<GetListingsEvent>((event, emit) async {
      emit(LoadingListingsState());
      listings = await listingsRepository.getListings(
          favListingsIDs: currentUser.likedListingsIDs);
      calculateAdLocation();
      emit(ListingsListState(listingsWithAds: listingsWithAds));
    });

    on<ToggleShowAllEvent>((event, emit) => emit(ToggleShowAllState()));
    on<ListingDeletedByUserEvent>((event, emit) {
      listings.remove(event.listing);
      calculateAdLocation();
      emit(ListingsListState(listingsWithAds: listingsWithAds));
    });
    on<ListingFavUpdated>((event, emit) async {
      event.listing.isFav = !event.listing.isFav;
      listings.firstWhere((element) => element.id == event.listing.id).isFav =
          event.listing.isFav;
      if (event.listing.isFav) {
        currentUser.likedListingsIDs.add(event.listing.id);
      } else {
        currentUser.likedListingsIDs.remove(event.listing.id);
      }
      await profileRepository.updateCurrentUser(currentUser);
      emit(ListingFavToggleState(
        listing: event.listing,
        updatedUser: currentUser,
      ));
    });
    on<ListingDeleteByAdminEvent>((event, emit) async {
      await listingsRepository.deleteListing(listingModel: event.listing);
      listings.remove(event.listing);
      calculateAdLocation();
      emit(ListingsListState(listingsWithAds: listingsWithAds));
    });
    on<LoadingEvent>((event, emit) => emit(LoadingState()));
  }

  calculateAdLocation() {
    listingsWithAds.clear();
    for (int i = 0; i < listings.length; i++) {
      if ((listingsWithAds.length + 1) % 5 == 0) {
        listingsWithAds.add(null);
        listingsWithAds.add(listings[i]);
      } else {
        listingsWithAds.add(listings[i]);
      }
    }
  }
}
