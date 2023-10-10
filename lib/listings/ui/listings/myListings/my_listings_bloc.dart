import 'package:bloc/bloc.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_repository.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_repository.dart';

part 'my_listings_event.dart';

part 'my_listings_state.dart';

class MyListingsBloc extends Bloc<MyListingsEvent, MyListingsState> {
  final ListingsRepository listingsRepository;
  final ProfileRepository profileRepository;
  final ListingsUser currentUser;
  List<ListingModel> myListings = [];

  MyListingsBloc({
    required this.listingsRepository,
    required this.currentUser,
    required this.profileRepository,
  }) : super(MyListingsInitial()) {
    on<GetMyListingsEvent>((event, emit) async {
      myListings = await listingsRepository.getMyListings(
          currentUserID: currentUser.userID,
          favListingsIDs: currentUser.likedListingsIDs);
      emit(MyListingsReadyState(myListings: myListings));
    });
    on<ListingFavUpdated>((event, emit) async {
      event.listing.isFav = !event.listing.isFav;
      myListings.firstWhere((element) => element.id == event.listing.id).isFav =
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
      myListings.remove(event.listing);
      emit(MyListingsReadyState(myListings: myListings));
    });
    on<LoadingEvent>((event, emit) => emit(LoadingState()));
  }
}
