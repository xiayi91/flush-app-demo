part of 'search_bloc.dart';

abstract class SearchEvent {}

class GetListingsEvent extends SearchEvent {}

class LoadingEvent extends SearchEvent {}

class SearchListingsEvent extends SearchEvent {
  final String query;

  SearchListingsEvent({required this.query});
}

class ListingDeletedByUserEvent extends SearchEvent {
  ListingModel listing;

  ListingDeletedByUserEvent({required this.listing});
}
