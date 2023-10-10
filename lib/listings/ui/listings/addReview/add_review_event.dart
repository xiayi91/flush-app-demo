part of 'add_review_bloc.dart';

abstract class AddReviewEvent {}

class PostReviewEvent extends AddReviewEvent {
  ListingReviewModel reviewModel;

  PostReviewEvent({required this.reviewModel});
}
