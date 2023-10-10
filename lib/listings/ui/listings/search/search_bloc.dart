import 'package:bloc/bloc.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_repository.dart';

part 'search_event.dart';

part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ListingsRepository listingsRepository;
  final ListingsUser currentUser;
  List<ListingModel> listings = [];

  SearchBloc({
    required this.listingsRepository,
    required this.currentUser,
  }) : super(SearchInitial()) {
    on<GetListingsEvent>((event, emit) async {
      listings = await listingsRepository.getListings(
          favListingsIDs: currentUser.likedListingsIDs);
      emit(ListingsReadyState(listings: listings));
    });
    on<LoadingEvent>((event, emit) => emit(LoadingState()));
    on<SearchListingsEvent>((event, emit) {
      List<ListingModel> filteredListings = [];
      if (event.query.isEmpty) {
        emit(ListingsReadyState(listings: listings));
        return;
      }
      for (var listing in listings) {
        if (listing.title.toLowerCase().contains(event.query.toLowerCase()) ||
            listing.place.toLowerCase().contains(event.query.toLowerCase())) {
          filteredListings.add(listing);
        }
      }
      emit(ListingsFilteredState(filteredListings: filteredListings));
    });
    on<ListingDeletedByUserEvent>((event, emit) {
      listings.remove(event.listing);
      emit(ListingsReadyState(listings: listings));
    });
  }
}
