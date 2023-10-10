import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/ui/auth/authentication_bloc.dart';
import 'package:instaflutter/listings/ui/listings/addListing/add_listing_screen.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_api_manager.dart';
import 'package:instaflutter/listings/ui/listings/listingDetails/listing_details_screen.dart';
import 'package:instaflutter/listings/ui/listings/myListings/my_listings_bloc.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_api_manager.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MyListingsWrapperWidget extends StatelessWidget {
  final ListingsUser currentUser;

  const MyListingsWrapperWidget({Key? key, required this.currentUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MyListingsBloc(
        listingsRepository: listingApiManager,
        currentUser: currentUser,
        profileRepository: profileApiManager,
      ),
      child: MyListingsScreen(currentUser: currentUser),
    );
  }
}

class MyListingsScreen extends StatefulWidget {
  final ListingsUser currentUser;

  const MyListingsScreen({Key? key, required this.currentUser})
      : super(key: key);

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<ListingModel> _listings = [];
  late ListingsUser currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
    context.read<MyListingsBloc>().add(GetMyListingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Listings'.tr(),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<MyListingsBloc>().add(LoadingEvent());
            context.read<MyListingsBloc>().add(GetMyListingsEvent());
          },
          child: BlocConsumer<MyListingsBloc, MyListingsState>(
            listener: (context, state) {
              if (state is MyListingsReadyState) {
                isLoading = false;
                _listings = state.myListings;
              } else if (state is ListingFavToggleState) {
                currentUser = state.updatedUser;
                context.read<AuthenticationBloc>().user = state.updatedUser;
                _listings
                    .firstWhere((element) => element.id == state.listing.id)
                    .isFav = state.listing.isFav;
              } else if (state is LoadingState) {
                isLoading = true;
              }
            },
            builder: (context, state) {
              if (isLoading) {
                return const Center(
                    child: CircularProgressIndicator.adaptive());
              }
              if (_listings.isEmpty) {
                return Stack(
                  children: [
                    ListView(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: showEmptyState(
                        'No Listings'.tr(),
                        'Add a new listing to show up here.'.tr(),
                        action: () => push(
                          context,
                          AddListingWrappingWidget(currentUser: currentUser),
                        ),
                        colorPrimary: Color(colorPrimary),
                        isDarkMode: isDarkMode(context),
                        buttonTitle: 'Add Listing'.tr(),
                      ),
                    ),
                  ],
                );
              } else {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 16),
                  itemCount: _listings.length,
                  itemBuilder: (context, index) => MyListingCard(
                    listing: _listings[index],
                    currentUser: currentUser,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class MyListingCard extends StatefulWidget {
  final ListingModel listing;
  final ListingsUser currentUser;

  const MyListingCard(
      {Key? key, required this.listing, required this.currentUser})
      : super(key: key);

  @override
  State<MyListingCard> createState() => _MyListingCardState();
}

class _MyListingCardState extends State<MyListingCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        bool? isListingDeleted = await push(
            context,
            ListingDetailsWrappingWidget(
                listing: widget.listing, currentUser: widget.currentUser));
        if (isListingDeleted != null && isListingDeleted) {
          if (!mounted) return;
          context
              .read<MyListingsBloc>()
              .add(ListingDeletedByUserEvent(listing: widget.listing));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                displayImage(widget.listing.photo),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    tooltip: widget.listing.isFav
                        ? 'Remove From Favorites'.tr()
                        : 'Add To Favorites'.tr(),
                    icon: Icon(
                      Icons.favorite,
                      color: widget.listing.isFav
                          ? Color(colorPrimary)
                          : Colors.white,
                    ),
                    onPressed: () => context
                        .read<MyListingsBloc>()
                        .add(ListingFavUpdated(listing: widget.listing)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.listing.title,
            maxLines: 1,
            style: TextStyle(
                fontSize: 16,
                color: isDarkMode(context)
                    ? Colors.grey.shade400
                    : Colors.grey.shade800,
                fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(widget.listing.place, maxLines: 1),
          ),
          RatingBar.builder(
            ignoreGestures: true,
            minRating: .5,
            initialRating: widget.listing.reviewsSum != 0
                ? widget.listing.reviewsSum / widget.listing.reviewsCount
                : 0,
            allowHalfRating: true,
            itemSize: 22,
            glow: false,
            unratedColor: Color(colorPrimary).withOpacity(0.5),
            itemBuilder: (context, index) =>
                Icon(Icons.star, color: Color(colorPrimary)),
            itemCount: 5,
            onRatingUpdate: (newValue) {},
          )
        ],
      ),
    );
  }
}
