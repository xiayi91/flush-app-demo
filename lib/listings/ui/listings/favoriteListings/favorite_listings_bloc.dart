import 'package:bloc/bloc.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_repository.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_repository.dart';

part 'favorite_listings_event.dart';

part 'favorite_listings_state.dart';

class FavoriteListingsBloc
    extends Bloc<FavoriteListingsEvent, FavoriteListingsState> {
  final ListingsRepository listingsRepository;
  final ListingsUser currentUser;
  final ProfileRepository profileRepository;
  List<ListingModel> favorites = [];

  FavoriteListingsBloc({
    required this.listingsRepository,
    required this.currentUser,
    required this.profileRepository,
  }) : super(FavoriteListingsInitial()) {
    on<GetMyFavoriteListings>((event, emit) async {
      favorites = await listingsRepository.getFavoriteListings(
          favListingsIDs: currentUser.likedListingsIDs);
      emit(FavoriteListingsReadyState(favorites: favorites));
    });
    on<ListingFavUpdated>((event, emit) async {
      event.listing.isFav = !event.listing.isFav;
      favorites.firstWhere((element) => element.id == event.listing.id).isFav =
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
    on<ListingDeletedByUserEvent>((event, emit) {
      favorites.remove(event.listing);
      emit(FavoriteListingsReadyState(favorites: favorites));
    });
    on<LoadingEvent>((event, emit) => emit(LoadingState()));
  }
}
