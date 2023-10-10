part of 'admin_bloc.dart';

abstract class AdminEvent {}

class GetPendingListingsEvent extends AdminEvent {}

class LoadingEvent extends AdminEvent {}

class ApprovePendingListing extends AdminEvent {
  ListingModel approvedListing;

  ApprovePendingListing({required this.approvedListing});
}

class RemovePendingListing extends AdminEvent {
  ListingModel removedListing;

  RemovePendingListing({required this.removedListing});
}

class ListingDeletedByUserEvent extends AdminEvent {
  ListingModel listing;

  ListingDeletedByUserEvent({required this.listing});
}

class ListingFavUpdated extends AdminEvent {
  ListingModel listing;

  ListingFavUpdated({required this.listing});
}

class ListingDeleteByAdminEvent extends AdminEvent {
  ListingModel listing;

  ListingDeleteByAdminEvent({required this.listing});
}

class ListingApprovalByAdminEvent extends AdminEvent {
  ListingModel listing;

  ListingApprovalByAdminEvent({required this.listing});
}
