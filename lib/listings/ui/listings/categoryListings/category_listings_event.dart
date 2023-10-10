part of 'category_listings_bloc.dart';

abstract class CategoryListingsEvent {}

class GetListingsEvent extends CategoryListingsEvent {}

class ListingDeletedEvent extends CategoryListingsEvent {
  ListingModel listing;

  ListingDeletedEvent({required this.listing});
}

class LoadingEvent extends CategoryListingsEvent {}
