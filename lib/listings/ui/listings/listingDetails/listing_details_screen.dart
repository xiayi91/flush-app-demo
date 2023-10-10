import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instaflutter/core/ui/chat/api/chat_api_manager.dart';
import 'package:instaflutter/core/ui/chat/chatScreen/chat_screen.dart';
import 'package:instaflutter/core/ui/chat/conversationBloc/conversation_bloc.dart';
import 'package:instaflutter/core/ui/fullScreenImageViewer/full_screen_image_viewer.dart';
import 'package:instaflutter/core/ui/loading/loading_cubit.dart';
import 'package:instaflutter/core/utils/helper.dart';
import 'package:instaflutter/listings/listings_app_config.dart';
import 'package:instaflutter/listings/model/listing_model.dart';
import 'package:instaflutter/listings/model/listing_review_model.dart';
import 'package:instaflutter/listings/model/listings_user.dart';
import 'package:instaflutter/listings/ui/auth/authentication_bloc.dart';
import 'package:instaflutter/listings/ui/listings/addReview/add_review_screen.dart';
import 'package:instaflutter/listings/ui/listings/api/listings_api_manager.dart';
import 'package:instaflutter/listings/ui/listings/listingDetails/listing_details_bloc.dart';
import 'package:instaflutter/listings/ui/profile/api/profile_api_manager.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ListingDetailsWrappingWidget extends StatelessWidget {
  final ListingModel listing;
  final ListingsUser currentUser;

  const ListingDetailsWrappingWidget(
      {Key? key, required this.listing, required this.currentUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ListingDetailsBloc(
            listing: listing,
            listingsRepository: listingApiManager,
            profileRepository: profileApiManager,
            currentUser: currentUser,
          ),
        ),
        BlocProvider(
          create: (context) => ConversationsBloc(
            chatRepository: chatApiManager,
            currentUser: currentUser,
          ),
        ),
      ],
      child: ListingDetailsScreen(currentUser: currentUser, listing: listing),
    );
  }
}

class ListingDetailsScreen extends StatefulWidget {
  final ListingModel listing;
  final ListingsUser currentUser;

  const ListingDetailsScreen(
      {Key? key, required this.listing, required this.currentUser})
      : super(key: key);

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  late ListingModel listing;
  int _pageIndex = 0;
  final PageController _pagerController = PageController(initialPage: 0);
  Timer? _autoScroll;
  late GoogleMapController _mapController;
  late LatLng _placeLocation;
  final Future _mapFuture = Future.delayed(Duration.zero, () => true);
  late ListingsUser currentUser;
  bool isLoadingReviews = true;

  List<ListingReviewModel> reviews = [];

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
    listing = widget.listing;
    _placeLocation = LatLng(listing.latitude, listing.longitude);
    context.read<ListingDetailsBloc>().add(GetListingReviewsEvent());
    if (!(listing.photos.length < 2)) {
      _autoScroll = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        if (_pageIndex < listing.photos.length - 1) {
          _pageIndex++;
        } else {
          _pageIndex = 0;
        }
        _pagerController.animateToPage(
          _pageIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ListingDetailsBloc, ListingDetailsState>(
          listener: (context, state) async {
            if (state is DeletedListingState) {
              await context.read<LoadingCubit>().hideLoading();
              if (!mounted) return;
              Navigator.pop(context, true);
            }
          },
        ),
        BlocListener<ConversationsBloc, ConversationsState>(
          listener: (context, state) {
            if (state is FriendTapState) {
              push(
                  context,
                  ChatWrapperWidget(
                    channelDataModel: state.channelDataModel,
                    currentUser: currentUser,
                    colorAccent: Color(colorAccent),
                    colorPrimary: Color(colorPrimary),
                  ));
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          actions: [
            BlocConsumer<ListingDetailsBloc, ListingDetailsState>(
              listener: (context, state) {
                if (state is ListingFavToggleState) {
                  listing = state.listing;
                  context.read<AuthenticationBloc>().user = state.updatedUser;
                  currentUser = state.updatedUser;
                }
              },
              buildWhen: (old, current) =>
                  old != current && current is ListingFavToggleState,
              builder: (context, state) {
                return PopupMenuButton(
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem(
                          child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.all(0),
                        leading: Icon(
                          Icons.favorite,
                          color: listing.isFav
                              ? Color(colorPrimary)
                              : isDarkMode(context)
                                  ? Colors.white
                                  : null,
                        ),
                        title: Text(
                          listing.isFav
                              ? 'Remove From Favorites'.tr()
                              : 'Add To Favorites'.tr(),
                          style: const TextStyle(fontSize: 18),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context
                              .read<ListingDetailsBloc>()
                              .add(ListingFavUpdatedEvent());
                        },
                      )),
                      if (currentUser.userID != listing.authorID)
                        PopupMenuItem(
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.all(0),
                            leading: Icon(
                              Icons.stars,
                              color: isDarkMode(context) ? Colors.white : null,
                            ),
                            title: Text(
                              'Add Review'.tr(),
                              style: const TextStyle(fontSize: 18),
                            ),
                            onTap: () async {
                              Navigator.pop(context);
                              bool? reviewPublished = await push(
                                  context,
                                  AddReviewWrappingWidget(
                                      listing: listing,
                                      currentUser: currentUser));
                              if (reviewPublished != null && reviewPublished) {
                                if (!mounted) return;
                                context
                                    .read<ListingDetailsBloc>()
                                    .add(LoadingEvent());
                                context
                                    .read<ListingDetailsBloc>()
                                    .add(GetListingReviewsEvent());
                              }
                            },
                          ),
                        ),
                      if (currentUser.userID != listing.authorID)
                        PopupMenuItem(
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.all(0),
                            leading: Icon(
                              Icons.chat,
                              color: isDarkMode(context) ? Colors.white : null,
                            ),
                            title: Text(
                              'Send Message'.tr(),
                              style: const TextStyle(fontSize: 18),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              context.read<ConversationsBloc>().add(
                                  FetchFriendByIDEvent(
                                      friendID: listing.authorID));
                            },
                          ),
                        ),
                      if (currentUser.userID == listing.authorID ||
                          currentUser.isAdmin)
                        PopupMenuItem(
                          child: ListTile(
                            dense: true,
                            onTap: () => deleteListing(context),
                            contentPadding: const EdgeInsets.all(0),
                            leading: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            title: Text(
                              'Delete Listing'.tr(),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                    ];
                  },
                );
              },
            ),
          ],
          title: Text(
            listing.title,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (listing.photos.isNotEmpty)
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 3,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (listing.photos.length > 1) {
                              push(
                                  context,
                                  FullScreenImageViewer(
                                    galleryImagesList: [...listing.photos],
                                    index: _pageIndex,
                                    imageUrl: '',
                                  ));
                            } else {
                              push(
                                  context,
                                  FullScreenImageViewer(
                                    imageUrl: listing.photos.first,
                                  ));
                            }
                          },
                          child: PageView.builder(
                            controller: _pagerController,
                            itemCount: listing.photos.length,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) =>
                                displayImage(listing.photos[index]),
                          ),
                        ),
                        if (listing.photos.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Align(
                                alignment: Alignment.bottomCenter,
                                child: SmoothPageIndicator(
                                    effect: ColorTransitionEffect(
                                        activeDotColor: Color(colorPrimary),
                                        dotHeight: 8,
                                        dotWidth: 8,
                                        dotColor: Colors.grey.shade300),
                                    controller: _pagerController,
                                    count: listing.photos.length)),
                          )
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: TextStyle(
                            fontSize: 19,
                            color: isDarkMode(context)
                                ? Colors.grey.shade200
                                : Colors.grey.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        listing.price,
                        style: TextStyle(
                          fontSize: 19,
                          color: isDarkMode(context)
                              ? Colors.grey.shade200
                              : Colors.grey.shade900,
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    listing.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDarkMode(context)
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16, 16, 0),
                  child: Text(
                    'Location'.tr(),
                    style: TextStyle(
                        fontSize: 19,
                        color: isDarkMode(context)
                            ? Colors.grey.shade200
                            : Colors.grey.shade900),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: Text(
                    listing.place,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDarkMode(context)
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 3,
                  child: FutureBuilder(
                      future: _mapFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator.adaptive());
                        }
                        return GoogleMap(
                          gestureRecognizers: {}..add(
                              Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer())),
                          markers: <Marker>{
                            Marker(
                                markerId: const MarkerId('marker_1'),
                                position: _placeLocation,
                                infoWindow: InfoWindow(title: listing.title)),
                          },
                          mapType: MapType.normal,
                          initialCameraPosition: CameraPosition(
                            target: _placeLocation,
                            zoom: 14.4746,
                          ),
                          onMapCreated: _onMapCreated,
                        );
                      }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16, 16, 16),
                  child: Text(
                    'Extra info'.tr(),
                    style: TextStyle(
                        fontSize: 19,
                        color: isDarkMode(context)
                            ? Colors.grey.shade200
                            : Colors.grey.shade900),
                  ),
                ),
                ListView.builder(
                    itemCount: listing.filters.entries.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) => FilterDetailsWidget(
                        filter: listing.filters.entries.elementAt(index))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16, 16, 0),
                  child: Text(
                    'Reviews'.tr(),
                    style: TextStyle(
                        fontSize: 19,
                        color: isDarkMode(context)
                            ? Colors.grey.shade200
                            : Colors.grey.shade900),
                  ),
                ),
                BlocConsumer<ListingDetailsBloc, ListingDetailsState>(
                  listener: (context, state) {
                    if (state is ReviewsFetchedState) {
                      isLoadingReviews = false;
                      reviews = state.reviews;
                    } else if (state is LoadingState) {
                      isLoadingReviews = true;
                    }
                  },
                  buildWhen: (old, current) =>
                      old != current &&
                      (current is ReviewsFetchedState ||
                          current is LoadingState),
                  builder: (context, state) {
                    if (isLoadingReviews) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child:
                            Center(child: CircularProgressIndicator.adaptive()),
                      );
                    }
                    if (reviews.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: showEmptyState(
                          'No Reviews found.'.tr(),
                          'You can add a review and it will show up here.'.tr(),
                          buttonTitle: 'Add Review',
                          isDarkMode: isDarkMode(context),
                          action: () async {
                            bool? reviewPublished = await push(
                                context,
                                AddReviewWrappingWidget(
                                    listing: listing,
                                    currentUser: currentUser));
                            if (reviewPublished != null && reviewPublished) {
                              if (!mounted) return;
                              context
                                  .read<ListingDetailsBloc>()
                                  .add(LoadingEvent());
                              context
                                  .read<ListingDetailsBloc>()
                                  .add(GetListingReviewsEvent());
                            }
                          },
                          colorPrimary: Color(colorPrimary),
                        ),
                      );
                    } else {
                      return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          shrinkWrap: true,
                          itemCount: reviews.length,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) =>
                              ReviewWidget(review: reviews[index]));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _pagerController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (isDarkMode(context)) {
      _mapController.setMapStyle('[{"featureType": "all","'
          'elementType": "'
          'geo'
          'met'
          'ry","stylers": [{"color": "#242f3e"}]},{"featureType": "all","elementType": "labels.text.stroke","stylers": [{"lightness": -80}]},{"featureType": "administrative","elementType": "labels.text.fill","stylers": [{"color": "#746855"}]},{"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#263c3f"}]},{"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#6b9a76"}]},{"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2b3544"}]},{"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#9ca5b3"}]},{"featureType": "road.arterial","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.arterial","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "road.highway","elementType": "geometry.fill","stylers": [{"color": "#746855"}]},{"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1f2835"}]},{"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f3d19c"}]},{"featureType": "road.local","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.local","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "transit","elementType": "geometry","stylers": [{"color": "#2f3948"}]},{"featureType": "transit.station","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "water","elementType": "geometry","stylers": [{"color": "#17263c"}]},{"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#515c6d"}]},{"featureType": "water","elementType": "labels.text.stroke","stylers": [{"lightness": -20}]}]');
    }
  }

  deleteListing(BuildContext blocContext) {
    Navigator.pop(context);
    String title = 'Delete Listing?'.tr();
    String content = 'Are you sure you want to remove this '
            'listing?'
        .tr();
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: Text(
                'Yes'.tr(),
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                context.read<LoadingCubit>().showLoading(
                      context,
                      'Deleting...'.tr(),
                      false,
                      Color(colorPrimary),
                    );
                blocContext
                    .read<ListingDetailsBloc>()
                    .add(DeleteListingEvent());
              },
            ),
            TextButton(
              child: Text('No'.tr()),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: Text(
                'Yes'.tr(),
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                context.read<LoadingCubit>().showLoading(
                      context,
                      'Deleting...'.tr(),
                      false,
                      Color(colorPrimary),
                    );
                blocContext
                    .read<ListingDetailsBloc>()
                    .add(DeleteListingEvent());
              },
            ),
            TextButton(
              child: Text('No'.tr()),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }
}

class ReviewWidget extends StatelessWidget {
  final ListingReviewModel review;

  const ReviewWidget({Key? key, required this.review}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          leading: displayCircleImage(review.profilePictureURL, 40, false),
          title: Text(
            review.fullName(),
            style: TextStyle(
              fontSize: 17,
              color: isDarkMode(context)
                  ? Colors.grey.shade200
                  : Colors.grey.shade900,
            ),
          ),
          subtitle: Text(
            formatReviewTimestamp(review.createdAt),
            style: TextStyle(
                fontSize: 13,
                color: isDarkMode(context)
                    ? Colors.grey.shade400
                    : Colors.grey.shade500),
          ),
          trailing: RatingBar.builder(
              onRatingUpdate: (rating) {},
              ignoreGestures: true,
              glow: false,
              itemCount: 5,
              allowHalfRating: true,
              itemSize: 20,
              unratedColor: Color(colorPrimary).withOpacity(.5),
              initialRating: review.starCount,
              itemBuilder: (context, index) =>
                  Icon(Icons.star, color: Color(colorPrimary))),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16, 8),
          child: Text(review.content),
        )
      ],
    );
  }
}

class FilterDetailsWidget extends StatelessWidget {
  final MapEntry<String, dynamic> filter;

  const FilterDetailsWidget({Key? key, required this.filter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8, left: 24, right: 100),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(filter.key, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(filter.value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
