import 'package:bloc/bloc.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_repository.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_repository.dart';

part 'admin_event.dart';

part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final ListingsRepository listingsRepository;
  final ProfileRepository profileRepository;
  final ListingsUser currentUser;
  List<ListingModel> pendingListings = [];

  AdminBloc({
    required this.listingsRepository,
    required this.currentUser,
    required this.profileRepository,
  }) : super(AdminInitial()) {
    on<GetPendingListingsEvent>((event, emit) async {
      pendingListings = await listingsRepository.getPendingListings(
          favListingsIDs: currentUser.likedListingsIDs);
      emit(PendingListingsState(pendingListings: pendingListings));
    });

    on<ListingDeletedByUserEvent>((event, emit) {
      pendingListings.remove(event.listing);
      emit(PendingListingsState(pendingListings: pendingListings));
    });
    on<ListingFavUpdated>((event, emit) async {
      event.listing.isFav = !event.listing.isFav;
      pendingListings
          .firstWhere((element) => element.id == event.listing.id)
          .isFav = event.listing.isFav;
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
      pendingListings.remove(event.listing);
      emit(PendingListingsState(pendingListings: pendingListings));
    });
    on<ListingApprovalByAdminEvent>((event, emit) async {
      await listingsRepository.approveListing(listingModel: event.listing);
      pendingListings.remove(event.listing);
      emit(PendingListingsState(pendingListings: pendingListings));
    });
    on<LoadingEvent>((event, emit) => emit(LoadingState()));
  }
}
