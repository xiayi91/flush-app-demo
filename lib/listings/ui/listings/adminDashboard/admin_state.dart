part of 'admin_bloc.dart';

abstract class AdminState {}

class AdminInitial extends AdminState {}

class PendingListingsState extends AdminState {
  List<ListingModel> pendingListings;

  PendingListingsState({required this.pendingListings});
}

class LoadingState extends AdminState {}

class ListingFavToggleState extends AdminState {
  ListingModel listing;
  ListingsUser updatedUser;

  ListingFavToggleState({required this.listing, required this.updatedUser});
}
