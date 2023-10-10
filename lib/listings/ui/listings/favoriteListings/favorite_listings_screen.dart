import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/ui/auth/authentication_bloc.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_api_manager.dart';
import 'package:instaflutter/listings/ui/listings/favoriteListings/favorite_listings_bloc.dart';
import 'package:instaflutter/listings/ui/listings/listingDetails/listing_details_screen.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_api_manager.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class FavoriteListingsWrapperWidget extends StatelessWidget {
  final ListingsUser currentUser;

  const FavoriteListingsWrapperWidget({Key? key, required this.currentUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FavoriteListingsBloc(
        profileRepository: profileApiManager,
        currentUser: currentUser,
        listingsRepository: listingApiManager,
      ),
      child: FavoriteListingScreen(currentUser: currentUser),
    );
  }
}

class FavoriteListingScreen extends StatefulWidget {
  final ListingsUser currentUser;

  const FavoriteListingScreen({Key? key, required this.currentUser})
      : super(key: key);

  @override
  State<FavoriteListingScreen> createState() => _FavoriteListingScreenState();
}

class _FavoriteListingScreenState extends State<FavoriteListingScreen> {
  List<ListingModel> favorites = [];
  late ListingsUser currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
    context.read<FavoriteListingsBloc>().add(GetMyFavoriteListings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favorites'.tr(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<FavoriteListingsBloc>().add(LoadingEvent());
          context.read<FavoriteListingsBloc>().add(GetMyFavoriteListings());
        },
        child: BlocConsumer<FavoriteListingsBloc, FavoriteListingsState>(
          listener: (context, state) {
            if (state is FavoriteListingsReadyState) {
              isLoading = false;
              favorites = state.favorites;
            } else if (state is ListingFavToggleState) {
              currentUser = state.updatedUser;
              context.read<AuthenticationBloc>().user = state.updatedUser;
              favorites
                  .firstWhere((element) => element.id == state.listing.id)
                  .isFav = state.listing.isFav;
            } else if (state is LoadingState) {
              isLoading = true;
            }
          },
          builder: (context, state) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            if (favorites.isEmpty) {
              return Stack(
                children: [
                  ListView(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: showEmptyState(
                        'No Favorites'.tr(),
                        'All your favorite listings will show up here once you click the ❤ button.'
                            .tr()),
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
                itemCount: favorites.length,
                itemBuilder: (context, index) => FavoriteListingCard(
                  listing: favorites[index],
                  currentUser: currentUser,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class FavoriteListingCard extends StatefulWidget {
  final ListingModel listing;
  final ListingsUser currentUser;

  const FavoriteListingCard(
      {Key? key, required this.listing, required this.currentUser})
      : super(key: key);

  @override
  State<FavoriteListingCard> createState() => _FavoriteListingCardState();
}

class _FavoriteListingCardState extends State<FavoriteListingCard> {
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
              .read<FavoriteListingsBloc>()
              .add(ListingDeletedByUserEvent(listing: widget.listing));
        }
        if (!widget.listing.isFav) {
          if (!mounted) return;
          context
              .read<FavoriteListingsBloc>()
              .add(ListingFavUpdated(listing: widget.listing));
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
                    tooltip: 'Remove From Favorites'.tr(),
                    icon: Icon(
                      Icons.favorite,
                      color: Color(colorPrimary),
                    ),
                    onPressed: () => context
                        .read<FavoriteListingsBloc>()
                        .add(ListingFavUpdated(listing: widget.listing)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.listing.title,
            maxLines: 1,
            style: TextStyle(
                fontSize: 16,
                color:
                    isDarkMode(context) ? Colors.grey[400] : Colors.grey[800],
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
