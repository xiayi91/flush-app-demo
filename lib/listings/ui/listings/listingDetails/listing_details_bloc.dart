import 'package:bloc/bloc.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listing_review_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_repository.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_repository.dart';

part 'listing_details_event.dart';

part 'listing_details_state.dart';

class ListingDetailsBloc
    extends Bloc<ListingDetailsEvent, ListingDetailsState> {
  final ListingsRepository listingsRepository;
  final ProfileRepository profileRepository;
  final ListingsUser currentUser;
  final ListingModel listing;

  ListingDetailsBloc({
    required this.listing,
    required this.listingsRepository,
    required this.currentUser,
    required this.profileRepository,
  }) : super(ListingDetailsInitial()) {
    on<GetListingReviewsEvent>((event, emit) async {
      List<ListingReviewModel> reviews =
          await listingsRepository.getReviews(listingID: listing.id);
      emit(ReviewsFetchedState(reviews: reviews));
    });
    on<ListingFavUpdatedEvent>((event, emit) async {
      listing.isFav = !listing.isFav;
      if (listing.isFav) {
        currentUser.likedListingsIDs.add(listing.id);
      } else {
        currentUser.likedListingsIDs.remove(listing.id);
      }
      await profileRepository.updateCurrentUser(currentUser);
      emit(ListingFavToggleState(
        listing: listing,
        updatedUser: currentUser,
      ));
    });
    on<DeleteListingEvent>((event, emit) async {
      await listingsRepository.deleteListing(listingModel: listing);
      emit(DeletedListingState());
    });
    on<LoadingEvent>((event, emit) => emit(LoadingState()));
  }
}
