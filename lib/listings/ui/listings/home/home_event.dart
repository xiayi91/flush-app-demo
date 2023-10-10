part of 'home_bloc.dart';

abstract class HomeEvent {}

class GetCategoriesEvent extends HomeEvent {}

class GetListingsEvent extends HomeEvent {}

class ToggleShowAllEvent extends HomeEvent {}

class ListingDeletedByUserEvent extends HomeEvent {
  ListingModel listing;

  ListingDeletedByUserEvent({required this.listing});
}

class ListingFavUpdated extends HomeEvent {
  ListingModel listing;

  ListingFavUpdated({required this.listing});
}

class ListingDeleteByAdminEvent extends HomeEvent {
  ListingModel listing;

  ListingDeleteByAdminEvent({required this.listing});
}

class LoadingEvent extends HomeEvent {}
