import 'package:bloc/bloc.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_repository.dart';

part 'category_listings_event.dart';

part 'category_listings_state.dart';

class CategoryListingsBloc
    extends Bloc<CategoryListingsEvent, CategoryListingsState> {
  final ListingsRepository listingsRepository;
  final ListingsUser currentUser;
  final String categoryID;
  List<ListingModel> listings = [];

  CategoryListingsBloc({
    required this.listingsRepository,
    required this.currentUser,
    required this.categoryID,
  }) : super(CategoryListingsInitial()) {
    on<GetListingsEvent>((event, emit) async {
      listings = await listingsRepository.getListingsByCategoryID(
          categoryID: categoryID, favListingsIDs: currentUser.likedListingsIDs);
      emit(ListingsReadyState(listings: listings));
    });
    on<ListingDeletedEvent>((event, emit) {
      listings.remove(event.listing);
      emit(ListingsReadyState(listings: listings));
    });
    on<LoadingEvent>((event, emit) => emit(LoadingState()));
  }
}
