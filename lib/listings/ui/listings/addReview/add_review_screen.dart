import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:instaflutter/core/ui/loading/loading_cubit.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listing_review_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/listings/addReview/add_review_bloc.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_api_manager.dart';

class AddReviewWrappingWidget extends StatelessWidget {
  final ListingModel listing;
  final ListingsUser currentUser;

  const AddReviewWrappingWidget(
      {Key? key, required this.listing, required this.currentUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddReviewBloc(listingsRepository: listingApiManager),
      child: AddReviewScreen(
        currentUser: currentUser,
        listing: listing,
      ),
    );
  }
}

class AddReviewScreen extends StatefulWidget {
  final ListingModel listing;
  final ListingsUser currentUser;

  const AddReviewScreen(
      {Key? key, required this.listing, required this.currentUser})
      : super(key: key);

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  double _rating = 2.5;
  final TextEditingController _reviewController = TextEditingController();

  late ListingsUser currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Review ${widget.listing.title}'.tr(),
        ),
      ),
      body: BlocListener<AddReviewBloc, AddReviewState>(
        listener: (context, state) {
          if (state is PostReviewSuccessState) {
            context.read<LoadingCubit>().hideLoading();
            Navigator.pop(context, true);
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: RatingBar.builder(
                      itemCount: 5,
                      glow: false,
                      allowHalfRating: true,
                      initialRating: _rating,
                      maxRating: 5,
                      itemSize: 30,
                      itemPadding: const EdgeInsets.all(4),
                      itemBuilder: (context, index) =>
                          Icon(Icons.star, color: Color(colorPrimary)),
                      unratedColor: Color(colorPrimary).withOpacity(.5),
                      onRatingUpdate: (newValue) {
                        _rating = newValue;
                      }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    maxLines: 7,
                    autofocus: true,
                    keyboardType: TextInputType.multiline,
                    controller: _reviewController,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText:
                          'Write your review for ${widget.listing.title}'.tr(),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(child: Container()),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      backgroundColor: Color(colorPrimary),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      context.read<LoadingCubit>().showLoading(
                            context,
                            'Posting review...'.tr(),
                            false,
                            Color(colorPrimary),
                          );
                      context.read<AddReviewBloc>().add(
                            PostReviewEvent(
                              reviewModel: ListingReviewModel(
                                authorID: currentUser.userID,
                                firstName: currentUser.firstName,
                                lastName: currentUser.lastName,
                                listingID: widget.listing.id,
                                profilePictureURL:
                                    currentUser.profilePictureURL,
                                starCount: _rating,
                                createdAt: Timestamp.now().seconds,
                                content: _reviewController.text.trim(),
                              ),
                            ),
                          );
                    },
                    child: Text(
                      'Add Review'.tr(),
                      style: TextStyle(
                        color:
                            isDarkMode(context) ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
